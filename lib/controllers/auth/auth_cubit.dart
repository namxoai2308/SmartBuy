import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_ecommerce/services/auth_services.dart';
import 'package:flutter_ecommerce/utilities/enums.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_ecommerce/models/user_model.dart';

part 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final AuthServices authServices = AuthServicesImpl();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  AuthFormType authFormType = AuthFormType.login;

  AuthCubit() : super(const AuthInitial());

  Future<UserModel?> _getUserModel(String uid) async {
    try {
      final docSnap = await _firestore.collection('users').doc(uid).get();
      if (docSnap.exists) {
        return UserModel.fromFirestore(docSnap as DocumentSnapshot<Map<String, dynamic>>);
      } else {
        print("Firestore Warning: No user document found for UID: $uid");
        return null;
      }
    } catch (e) {
      print("Error getting user model from Firestore: $e");
      return null;
    }
  }

  Future<void> login(String email, String password) async {
    emit(const AuthLoading());
    try {
      final User? authUser = await authServices.loginWithEmailAndPassword(email, password);
      if (authUser != null) {
        final userModel = await _getUserModel(authUser.uid);
        if (userModel != null) {
          emit(AuthSuccess(userModel));
        } else {
          emit(const AuthFailed('Login successful, but failed to load user data.'));
        }
      } else {
        emit(const AuthFailed('Login failed. Please check credentials.'));
      }
    } on Exception catch (e) {
      emit(AuthFailed(e.toString().replaceFirst('Exception: ', '')));
    } catch (e) {
      emit(AuthFailed('An unexpected error occurred: ${e.toString()}'));
    }
  }

  Future<void> signUp(String email, String password, String name) async {
    emit(const AuthLoading());
    try {
      final User? authUser = await authServices.signUpWithEmailAndPassword(email, password, name);
      if (authUser != null) {
        emit(const AuthSignUpSuccess());
        await Future.delayed(const Duration(milliseconds: 50));
        authFormType = AuthFormType.login;
        emit(const AuthInitial());
      } else {
        emit(const AuthFailed('Sign up failed. Please try again.'));
      }
    } on Exception catch (e) {
      emit(AuthFailed(e.toString().replaceFirst('Exception: ', '')));
    } catch (e) {
      emit(AuthFailed('An unknown error occurred during sign up: ${e.toString()}'));
    }
  }

  Future<void> authStatus() async {
    try {
      final User? authUser = authServices.currentUser;
      if (authUser != null) {
        final userModel = await _getUserModel(authUser.uid);
        if (userModel != null) {
          emit(AuthSuccess(userModel));
        } else {
          print("AuthStatus Warning: User exists in Auth but not Firestore (${authUser.uid}). Forcing logout.");
          await authServices.logout();
          emit(const AuthInitial());
        }
      } else {
        emit(const AuthInitial());
      }
    } catch (e) {
      print("Error checking auth status: $e");
      emit(AuthFailed("Couldn't check authentication status: ${e.toString()}"));
    }
  }

  Future<void> logout() async {
    try {
      await authServices.logout();
      emit(const AuthInitial());
    } catch (e) {
      print("Logout failed: ${e.toString()}");
      emit(AuthFailed("Logout failed: ${e.toString()}"));
      await Future.delayed(const Duration(milliseconds: 50));
      emit(const AuthInitial());
    }
  }

  void toggleFormType() {
    authFormType = authFormType == AuthFormType.login
        ? AuthFormType.register
        : AuthFormType.login;
    emit(ToggleFormType(authFormType));
  }
}

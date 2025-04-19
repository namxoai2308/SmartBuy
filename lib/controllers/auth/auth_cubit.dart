import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_ecommerce/services/auth_services.dart';
import 'package:flutter_ecommerce/utilities/enums.dart';
import 'package:meta/meta.dart';
import 'package:equatable/equatable.dart';

part 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  AuthCubit() : super(const AuthInitial());

  final authServices = AuthServicesImpl();
  var authFormType = AuthFormType.login;

  Future<void> login(String email, String password) async {
    emit(const AuthLoading());
    try {
      final User? user =
          await authServices.loginWithEmailAndPassword(email, password);

      if (user != null) {
        emit(AuthSuccess(user));
      } else {
        emit(const AuthFailed('Incorrect credentials!'));
      }
    } catch (e) {
      emit(AuthFailed(e.toString()));
    }
  }

  Future<void> signUp(String email, String password) async {
    emit(const AuthLoading());
    try {
      final User? user =
          await authServices.signUpWithEmailAndPassword(email, password);

      if (user != null) {
        emit(AuthSuccess(user));
      } else {
        emit(const AuthFailed('Incorrect credentials!'));
      }
    } catch (e) {
      emit(AuthFailed(e.toString()));
    }
  }

  void authStatus() {
    final User? user = authServices.currentUser;
    if (user != null) {
      emit(AuthSuccess(user));
    } else {
      emit(const AuthInitial());
    }
  }

  Future<void> logout() async {
    emit(const AuthLoading());
    try {
      await authServices.logout();
      emit(const AuthInitial());
    } catch (e) {
      emit(AuthFailed(e.toString()));
    }
  }

  void toggleFormType() {
    final newFormType = authFormType == AuthFormType.login
        ? AuthFormType.register
        : AuthFormType.login;
    authFormType = newFormType;
    emit(ToggleFormType(newFormType));
  }
}

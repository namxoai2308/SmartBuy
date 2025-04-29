import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_ecommerce/controllers/auth/auth_cubit.dart';
import 'package:flutter_ecommerce/views/pages/auth_page.dart';
import 'package:flutter_ecommerce/views/pages/bottom_navbar.dart';
import 'package:flutter_ecommerce/views/pages/splash_screen.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      buildWhen: (previous, current) => current is! ToggleFormType,
      builder: (context, state) {
        if (state is AuthSuccess) {
          print("AuthWrapper: State is AuthSuccess, showing BottomNavbar.");
          return const BottomNavbar();
        } else if (state is AuthInitial || state is AuthFailed) {
          print("AuthWrapper: State is AuthInitial or AuthFailed, showing AuthPage.");
          return const AuthPage();
        } else {
          print("AuthWrapper: State is Loading/Unknown, showing SplashScreen.");
          return const SplashScreen();
        }
      },
    );
  }
}

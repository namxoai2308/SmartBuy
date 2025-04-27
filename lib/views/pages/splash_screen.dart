import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_ecommerce/controllers/auth/auth_cubit.dart';
import 'package:flutter_ecommerce/controllers/home/home_cubit.dart';
import 'package:flutter_ecommerce/utilities/routes.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _navigationAttempted = false;
  late final HomeCubit _homeCubit;

  @override
  void initState() {
    super.initState();
    _homeCubit = context.read<HomeCubit>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
       _checkInitialAuthStateAndNavigate();
    });
  }

  void _checkInitialAuthStateAndNavigate() {
    if (!mounted) return;
    final currentState = context.read<AuthCubit>().state;

    if (currentState is! AuthLoading && !_navigationAttempted) {
       _navigateToNextScreen(currentState);
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _navigateToNextScreen(AuthState state) {
    if (!mounted) return;
    if (_navigationAttempted) return;
    _navigationAttempted = true;
    String? userId = (state is AuthSuccess) ? state.user.uid : null;

    try {
      _homeCubit.getHomeContent(userId: userId);
    } catch (e, stackTrace) {
       return;
    }

    try {
      final routeName = AppRoutes.bottomNavBarRoute;
      Navigator.of(context).pushReplacementNamed(routeName);
    } catch (e, stackTrace) {
       return;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.red,
      body: const Center(
        child: Column(
           mainAxisAlignment: MainAxisAlignment.center,
           children: [
              CircularProgressIndicator(color: Colors.white),
              SizedBox(height: 20),
              Text(
                'Wellcom',
                style: TextStyle(color: Colors.white),
               ),
           ],
        )
      ),
    );
  }
}

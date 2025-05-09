import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_ecommerce/controllers/auth/auth_cubit.dart';
import 'package:flutter_ecommerce/controllers/home/home_cubit.dart';
import 'package:flutter_ecommerce/utilities/routes.dart';

class OrderSuccessPage extends StatelessWidget {
  const OrderSuccessPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final homeCubit = context.read<HomeCubit>();
    final authCubit = context.read<AuthCubit>();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const Spacer(flex: 2),
              Image.asset(
                'assets/success_shopping.png',
                height: 180,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(Icons.check_circle_outline_rounded, size: 150, color: Colors.green[600]);
                },
              ),
              const SizedBox(height: 40),
              const Text(
                'Success!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 15),
              Text(
                'Your order will be delivered soon.\nThank you for choosing our app!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[700],
                  height: 1.4,
                ),
              ),
              const Spacer(flex: 3),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFDB3022),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30.0),
                  ),
                  elevation: 2,
                ),
                onPressed: () {
                  final authState = authCubit.state;
                  if (authState is AuthSuccess && authState.user.role.toLowerCase() == 'buyer') {
                    final userId = authState.user.uid; // Lấy userId
                    print("OrderSuccessPage: Refreshing recommendations for buyer: $userId");
                    homeCubit.refreshRecommendations(userId: userId);
                  } else {
                    print("OrderSuccessPage: Skipping recommendation refresh - User is not a buyer or not logged in.");
                  }

                  Navigator.of(context).pushNamedAndRemoveUntil(
                    AppRoutes.bottomNavBarRoute,
                    (route) => false,
                  );
                },
                child: const Text(
                  'CONTINUE SHOPPING',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
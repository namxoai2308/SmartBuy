import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart'; // <-- 1. Import flutter_bloc
import 'package:flutter_ecommerce/controllers/auth/auth_cubit.dart'; // <-- 2. Import AuthCubit và State
import 'package:flutter_ecommerce/controllers/home/home_cubit.dart'; // <-- 3. Import HomeCubit
import 'package:flutter_ecommerce/utilities/routes.dart';

class OrderSuccessPage extends StatelessWidget {
  const OrderSuccessPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
                  return Icon(Icons.shopping_bag_outlined, size: 150, color: Colors.orange[700]);
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
                  backgroundColor: const Color(0xFFE53935), // Màu đỏ quen thuộc
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30.0),
                  ),
                  elevation: 2,
                ),
                onPressed: () {
                  // --- Bắt đầu thay đổi ---
                  // 4. Lấy các Cubits
                  final homeCubit = context.read<HomeCubit>();
                  final authCubit = context.read<AuthCubit>();

                  // 5. Lấy userId từ AuthState
                  String? userId;
                  final authState = authCubit.state;
                  if (authState is AuthSuccess) {
                    userId = authState.user.uid;
                    print("OrderSuccessPage: Refreshing recommendations for user: $userId");
                  } else {
                    print("OrderSuccessPage: User not logged in? Refreshing general recommendations.");
                    userId = null;
                  }
                  homeCubit.refreshRecommendations(userId: userId);

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
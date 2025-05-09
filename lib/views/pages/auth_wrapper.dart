import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_ecommerce/controllers/auth/auth_cubit.dart';
import 'package:flutter_ecommerce/views/pages/auth_page.dart';
import 'package:flutter_ecommerce/views/pages/bottom_navbar.dart'; // Assuming this is the Buyer's main screen
import 'package:flutter_ecommerce/views/pages/seller/seller_home_screen.dart'; // Import Seller's screen
import 'package:flutter/foundation.dart'; // Import để sử dụng debugPrint

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    debugPrint('[AuthWrapper] build() called.'); // LOG: AuthWrapper được build

    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        debugPrint('[AuthWrapper] builder - Current AuthState: $state'); // LOG: Trạng thái hiện tại trong builder

        if (state is AuthSuccess) {
          final userRole = state.user.role.toLowerCase();
          debugPrint('[AuthWrapper] AuthSuccess - User role: "$userRole", User email: "${state.user.email}"'); // LOG: Thông tin khi AuthSuccess

          if (userRole == 'seller') {
            debugPrint('[AuthWrapper] AuthSuccess - Role is "seller", returning SellerHomeScreen.');
            return const SellerHomeScreen();
          } else if (userRole == 'buyer') {
            debugPrint('[AuthWrapper] AuthSuccess - Role is "buyer", returning BottomNavbar.');
            return const BottomNavbar();
          } else {
            debugPrint('[AuthWrapper] AuthSuccess - Unknown role: "$userRole". Attempting to logout and returning AuthPage.');
            // Logic logout của bạn
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (context.mounted) { // Kiểm tra mounted
                debugPrint('[AuthWrapper] addPostFrameCallback - Calling logout due to unknown role.');
                context.read<AuthCubit>().logout();
              }
            });
            return const AuthPage();
          }
        } else if (state is AuthLoading) {
          debugPrint('[AuthWrapper] AuthLoading - Returning loading indicator.');
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator.adaptive(),
            ),
          );
        } else {
          // Bao gồm AuthInitial, AuthFailed, AuthSignUpSuccess
          debugPrint('[AuthWrapper] AuthState is $state (e.g., Initial, Failed, SignUpSuccess) - Returning AuthPage.');
          return const AuthPage();
        }
      },
    );
  }
}
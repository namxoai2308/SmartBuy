import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_ecommerce/controllers/auth/auth_cubit.dart';
import 'package:flutter_ecommerce/utilities/routes.dart';
import 'package:flutter_ecommerce/views/widgets/main_button.dart';
import 'package:flutter_ecommerce/controllers/checkout/checkout_cubit.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final authCubit = context.read<AuthCubit>();
    final authState = context.watch<AuthCubit>().state;

    String userName = 'Loading...';
    String email = 'Loading...';

    if (authState is AuthSuccess) {
      userName = authState.user.displayName ?? 'No Name Set';
      email = authState.user.email ?? 'No Email Provided';
    }

    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 8.0, right: 8.0),
              child: Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  icon: const Icon(Icons.search, size: 28, color: Colors.black54),
                  onPressed: () {
                    print('Search button pressed');
                  },
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 0),
              child: const Text(
                "My Profile",
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundImage: const AssetImage('assets/success_shopping.png'),
                    backgroundColor: Colors.grey[200],
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          userName,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          email,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.grey[600],
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(height: 30),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 0),
                children: [
                  _buildProfileTile(
                    context,
                    title: "My orders",
                    subtitle: "Check your order status",
                    onTap: () {
                      Navigator.of(context).pushNamed(AppRoutes.myOrdersPageRoute);
                    },
                  ),
                  _buildProfileTile(
                    context,
                    title: "Shipping addresses",
                    subtitle: "Manage your addresses",
                    onTap: () {
                      final checkoutCubit = context.read<CheckoutCubit>();
                      Navigator.of(context).pushNamed(
                        AppRoutes.shippingAddressesRoute,
                        arguments: checkoutCubit,
                      );
                    },
                  ),
                  _buildProfileTile(
                    context,
                    title: "Payment methods",
                    subtitle: "Manage payment options",
                    onTap: () {
                      Navigator.of(context).pushNamed(AppRoutes.paymentMethodsRoute);
                    },
                  ),
                  _buildProfileTile(
                    context,
                    title: "Promocodes",
                    subtitle: "View available promocodes",
                    onTap: () {},
                  ),
                  _buildProfileTile(
                    context,
                    title: "My reviews",
                    subtitle: "See your product reviews",
                    onTap: () {},
                  ),
                  _buildProfileTile(
                    context,
                    title: "Settings",
                    subtitle: "Notifications, password, etc.",
                    onTap: () {},
                  ),
                  const SizedBox(height: 30),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: BlocListener<AuthCubit, AuthState>(
                      listener: (context, state) {
                        if (state is AuthInitial) {
                          Navigator.of(context, rootNavigator: true)
                              .pushNamedAndRemoveUntil(AppRoutes.loginPageRoute, (route) => false);
                        } else if (state is AuthFailed) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Logout failed: ${state.error}')),
                          );
                        }
                      },
                      child: BlocBuilder<AuthCubit, AuthState>(
                        buildWhen: (previous, current) =>
                            previous is AuthLoading != current is AuthLoading,
                        builder: (context, state) {
                          if (state is AuthLoading) {
                            return MainButton(
                              hasCircularBorder: true,
                              onTap: null,
                              child: const Center(
                                child: SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 3,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            );
                          }
                          return MainButton(
                            text: 'LOG OUT',
                            onTap: () async {
                              await authCubit.logout();
                            },
                            hasCircularBorder: true,
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    VoidCallback? onTap,
  }) {
    return ListTile(
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 14,
          color: Colors.grey[600],
        ),
      ),
      trailing: const Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: Colors.black45,
      ),
      onTap: onTap,
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 8.0),
    );
  }
}

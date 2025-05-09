import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_ecommerce/controllers/auth/auth_cubit.dart';
import 'package:flutter_ecommerce/utilities/routes.dart';
import 'package:flutter_ecommerce/views/widgets/main_button.dart';
import 'package:flutter_ecommerce/controllers/checkout/checkout_cubit.dart';
import 'package:flutter_ecommerce/controllers/chat/chat_cubit.dart';
import 'package:flutter_ecommerce/models/user_model.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  void _navigateToSupportChat(BuildContext context) {
    final currentAuthCubitState = context.read<AuthCubit>().state;
    if (currentAuthCubitState is! AuthSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to chat with support.')),
      );
      return;
    }

    if (currentAuthCubitState.user.role.toLowerCase() != 'buyer') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Only buyers can initiate support chat from profile.')),
      );
      return;
    }

    context.read<ChatCubit>().startChatWithAdmin();
    Navigator.of(context).pushNamed(AppRoutes.chatWaitingPageRoute);
  }

  @override
  Widget build(BuildContext context) {
    final authCubit = context.read<AuthCubit>();
    final authState = context.watch<AuthCubit>().state;

    String userName = 'Loading...';
    String email = 'Loading...';

    if (authState is AuthSuccess) {
      userName = authState.user.name ?? 'No Name Set';
      email = authState.user.email ?? 'No Email Provided';
    }

    return SafeArea(
      child: Scaffold(
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
              child: Text(
                "My Profile",
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).brightness == Brightness.light
                      ? Colors.black87
                      : Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 30,
                    backgroundImage: AssetImage('assets/success_shopping.png'),
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
                                color: Theme.of(context).brightness == Brightness.light
                                    ? Colors.black87
                                    : Colors.white,
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          email,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).brightness == Brightness.light
                                    ? Colors.grey[600]
                                    : Colors.white,
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
                    title: "Langages",
                    subtitle: "Select Langages",
                    onTap: () async {
                      Navigator.of(context).pushNamed(AppRoutes.languagesPageRoute);
                    },
                  ),
                  _buildProfileTile(
                    context,
                    title: "Support",
                    subtitle: "Chat with our support team",
                    onTap: () => _navigateToSupportChat(context),
                  ),
                  _buildProfileTile(
                    context,
                    title: "Settings",
                    subtitle: "Notifications, password, etc.",
                    onTap: () {
                      Navigator.of(context).pushNamed(AppRoutes.settingsPageRoute);
                    },
                  ),
                  const SizedBox(height: 30),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: BlocListener<AuthCubit, AuthState>(
                      listener: (context, state) {
                        if (state is AuthInitial) {
                          Navigator.of(context, rootNavigator: true).pushNamedAndRemoveUntil(
                            AppRoutes.loginPageRoute,
                            (route) => false,
                          );
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
                                  child: CircularProgressIndicator(strokeWidth: 3),
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
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).brightness == Brightness.light
              ? Colors.black87
              : Colors.white,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 14,
          color: Theme.of(context).brightness == Brightness.light
              ? Colors.grey[600]
              : Colors.white,
        ),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: Theme.of(context).brightness == Brightness.light
            ? Colors.black54
            : Colors.white,
      ),
      onTap: onTap,
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 8.0),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_ecommerce/controllers/auth/auth_cubit.dart';
import 'package:flutter_ecommerce/utilities/assets.dart';
import 'package:flutter_ecommerce/utilities/enums.dart';
import 'package:flutter_ecommerce/views/widgets/main_button.dart';
import 'package:flutter_ecommerce/views/widgets/main_dialog.dart';
import 'package:flutter_ecommerce/views/widgets/social_media_button.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _nameFocusNode = FocusNode();
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  final _confirmPasswordFocusNode = FocusNode();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameFocusNode.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();
    super.dispose();
  }

  void _submitForm(AuthCubit authCubit) {
    FocusScope.of(context).unfocus();
    if (_formKey.currentState?.validate() ?? false) {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();

      if (authCubit.authFormType == AuthFormType.login) {
        authCubit.login(email, password);
      } else {
        final name = _nameController.text.trim();
        if (_passwordController.text == _confirmPasswordController.text) {
          authCubit.signUp(email, password, name);
        } else {
          MainDialog(context: context, title: 'Error', content: 'Passwords do not match.').showAlertDialog();
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return BlocConsumer<AuthCubit, AuthState>(
      listener: (context, listenerState) {
        if (listenerState is AuthFailed) {
          MainDialog(context: context, title: 'Authentication Failed', content: listenerState.error).showAlertDialog();
        } else if (listenerState is AuthSignUpSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Registration successful! Please log in.'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
          _formKey.currentState?.reset();
          _nameController.clear();
          _emailController.clear();
          _passwordController.clear();
          _confirmPasswordController.clear();
          FocusScope.of(context).requestFocus(_emailFocusNode);
        } else if (listenerState is AuthSuccess) {
          print("Auth Success (Login)! AuthWrapper will navigate.");
        }
      },
      buildWhen: (previous, current) =>
          current is AuthInitial ||
          current is AuthLoading ||
          current is AuthFailed ||
          current is AuthSignUpSuccess ||
          current is ToggleFormType,
      builder: (context, state) {
        final authCubit = context.read<AuthCubit>();
        final isLoading = state is AuthLoading;

        return Scaffold(
          resizeToAvoidBottomInset: true,
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 40.0, horizontal: 32.0),
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        authCubit.authFormType == AuthFormType.login ? 'Login' : 'Register',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 60.0),
                      if (authCubit.authFormType == AuthFormType.register)
                        Column(
                          children: [
                            TextFormField(
                              controller: _nameController,
                              focusNode: _nameFocusNode,
                              onEditingComplete: () => FocusScope.of(context).requestFocus(_emailFocusNode),
                              textInputAction: TextInputAction.next,
                              keyboardType: TextInputType.name,
                              textCapitalization: TextCapitalization.words,
                              validator: (val) => (val == null || val.trim().isEmpty) ? 'Please enter your name!' : null,
                              decoration: const InputDecoration(labelText: 'Name', hintText: 'Enter your full name'),
                            ),
                            const SizedBox(height: 24.0),
                          ],
                        ),
                      TextFormField(
                        controller: _emailController,
                        focusNode: _emailFocusNode,
                        onEditingComplete: () => FocusScope.of(context).requestFocus(_passwordFocusNode),
                        textInputAction: TextInputAction.next,
                        keyboardType: TextInputType.emailAddress,
                        validator: (val) {},
                        decoration: const InputDecoration(labelText: 'Email', hintText: 'Enter your email'),
                      ),
                      const SizedBox(height: 24.0),
                      TextFormField(
                        controller: _passwordController,
                        focusNode: _passwordFocusNode,
                        onEditingComplete: () => authCubit.authFormType == AuthFormType.register
                            ? FocusScope.of(context).requestFocus(_confirmPasswordFocusNode)
                            : _submitForm(authCubit),
                        textInputAction: authCubit.authFormType == AuthFormType.register
                            ? TextInputAction.next
                            : TextInputAction.done,
                        validator: (val) {},
                        obscureText: true,
                        decoration: const InputDecoration(labelText: 'Password', hintText: 'Enter your password'),
                        onFieldSubmitted: (_) {
                          if (authCubit.authFormType == AuthFormType.login) _submitForm(authCubit);
                        },
                      ),
                      const SizedBox(height: 16.0),
                      if (authCubit.authFormType == AuthFormType.register)
                        Column(
                          children: [
                            TextFormField(
                              controller: _confirmPasswordController,
                              focusNode: _confirmPasswordFocusNode,
                              textInputAction: TextInputAction.done,
                              validator: (val) {
                                if (val == null || val.isEmpty) return 'Please confirm your password!';
                                if (val != _passwordController.text) return 'Passwords do not match!';
                                return null;
                              },
                              obscureText: true,
                              decoration: const InputDecoration(labelText: 'Confirm Password', hintText: 'Re-enter your password'),
                              onFieldSubmitted: (_) => _submitForm(authCubit),
                            ),
                            const SizedBox(height: 16.0),
                          ],
                        ),
                      if (authCubit.authFormType == AuthFormType.login)
                        Align(
                          alignment: Alignment.topRight,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4.0),
                            child: InkWell(
                              child: const Text('Forgot your password?'),
                              onTap: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Forgot Password action not implemented')),
                                );
                              },
                            ),
                          ),
                        ),
                      const SizedBox(height: 24.0),
                      MainButton(
                        text: authCubit.authFormType == AuthFormType.login ? 'Login' : 'Register',
                        isLoading: isLoading,
                        onTap: isLoading ? null : () => _submitForm(authCubit),
                      ),
                      const SizedBox(height: 16.0),
                      Align(
                        alignment: Alignment.center,
                        child: InkWell(
                          child: Text(
                            authCubit.authFormType == AuthFormType.login
                                ? 'Don\'t have an account? Register'
                                : 'Already have an account? Login',
                          ),
                          onTap: () {
                            _formKey.currentState?.reset();
                            _nameController.clear();
                            _emailController.clear();
                            _passwordController.clear();
                            _confirmPasswordController.clear();
                            FocusScope.of(context).unfocus();
                            authCubit.toggleFormType();
                          },
                        ),
                      ),
                      SizedBox(height: size.height * 0.07),
                      Align(
                        alignment: Alignment.center,
                        child: Text(
                          authCubit.authFormType == AuthFormType.login ? 'Or Login with' : 'Or Register with',
                          style: Theme.of(context).textTheme.labelMedium,
                        ),
                      ),
                      const SizedBox(height: 16.0),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SocialMediaButton(
                            iconName: AppAssets.facebookIcon,
                            onPress: () {},
                          ),
                          const SizedBox(width: 16.0),
                          SocialMediaButton(
                            iconName: AppAssets.googleIcon,
                            onPress: () {},
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

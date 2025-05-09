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

  String _selectedRole = 'buyer'; // Default role

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
          authCubit.signUp(email, password, name, _selectedRole);
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
          setState(() {
             _selectedRole = 'buyer';
          });
          FocusScope.of(context).requestFocus(_emailFocusNode);
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
        final isRegisterForm = authCubit.authFormType == AuthFormType.register;

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
                        isRegisterForm ? 'Register' : 'Login',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 60.0),
                      if (isRegisterForm) ...[
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
                      TextFormField(
                        controller: _emailController,
                        focusNode: _emailFocusNode,
                        onEditingComplete: () => FocusScope.of(context).requestFocus(_passwordFocusNode),
                        textInputAction: TextInputAction.next,
                        keyboardType: TextInputType.emailAddress,
                        validator: (val) {
                           if (val == null || val.trim().isEmpty) return 'Please enter your email!';
                           if (!RegExp(r"^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$").hasMatch(val)) {
                             return 'Please enter a valid email!';
                           }
                           return null;
                        },
                        decoration: const InputDecoration(labelText: 'Email', hintText: 'Enter your email'),
                      ),
                      const SizedBox(height: 24.0),
                      TextFormField(
                        controller: _passwordController,
                        focusNode: _passwordFocusNode,
                        onEditingComplete: () => isRegisterForm
                            ? FocusScope.of(context).requestFocus(_confirmPasswordFocusNode)
                            : _submitForm(authCubit),
                        textInputAction: isRegisterForm ? TextInputAction.next : TextInputAction.done,
                        validator: (val) {
                           if (val == null || val.trim().isEmpty) return 'Please enter your password!';
                           if (val.length < 6) return 'Password must be at least 6 characters!';
                           return null;
                        },
                        obscureText: true,
                        decoration: const InputDecoration(labelText: 'Password', hintText: 'Enter your password'),
                        onFieldSubmitted: (_) {
                          if (!isRegisterForm) _submitForm(authCubit);
                        },
                      ),
                      const SizedBox(height: 16.0),
                      if (isRegisterForm) ...[
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
                      if (!isRegisterForm)
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
                        text: isRegisterForm ? 'Register' : 'Login',
                        isLoading: isLoading,
                        onTap: isLoading ? null : () => _submitForm(authCubit),
                      ),
                      const SizedBox(height: 16.0),
                      Align(
                        alignment: Alignment.center,
                        child: InkWell(
                          child: Text(
                            isRegisterForm
                                ? 'Already have an account? Login'
                                : 'Don\'t have an account? Register',
                          ),
                          onTap: isLoading
                              ? null
                              : () {
                                  _formKey.currentState?.reset();
                                  _nameController.clear();
                                  _emailController.clear();
                                  _passwordController.clear();
                                  _confirmPasswordController.clear();
                                  setState(() {
                                    _selectedRole = 'buyer';
                                  });
                                  context.read<AuthCubit>().toggleFormType();
                                },
                        ),

                      ),
                      const SizedBox(height: 66.0),
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                SocialMediaButton(
                                                  iconName: AppAssets.facebookIcon,
                                                  onPress: () {
                                                     ScaffoldMessenger.of(context).showSnackBar(
                                                        const SnackBar(content: Text('Facebook login not implemented')),
                                                      );
                                                  },
                                                ),
                                                const SizedBox(width: 16.0),
                                                SocialMediaButton(
                                                  iconName: AppAssets.googleIcon,
                                                  onPress: () {
                                                     ScaffoldMessenger.of(context).showSnackBar(
                                                        const SnackBar(content: Text('Google login not implemented')),
                                                      );
                                                  },
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
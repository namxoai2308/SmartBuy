import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart'; // thêm để sử dụng FirebaseAuth
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_ecommerce/controllers/auth/auth_cubit.dart';
import 'package:flutter_ecommerce/services/auth.dart';
import 'package:flutter_ecommerce/utilities/constants.dart';
import 'package:flutter_ecommerce/utilities/router.dart';
import 'package:flutter_ecommerce/utilities/routes.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:provider/provider.dart';
import 'package:flutter_ecommerce/controllers/cart/cart_cubit.dart';


Future<void> main() async {
  await initSetup();
  runApp(const MyApp());
}

Future<void> initSetup() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await FirebaseAuth.instance.setSettings(appVerificationDisabledForTesting: true);

  Stripe.publishableKey = AppConstants.publishableKey;
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthCubit>(
          create: (context) {
            final cubit = AuthCubit();
            cubit.authStatus();
            return cubit;
          },
        ),
        BlocProvider<CartCubit>(
          create: (context) => CartCubit()..getCartItems(),
        ),
      ],
      child: Builder(
        builder: (context) {
          return BlocBuilder<AuthCubit, AuthState>(
            bloc: BlocProvider.of<AuthCubit>(context),
            buildWhen: (previous, current) =>
                current is AuthSuccess || current is AuthInitial,
            builder: (context, state) {
              return MaterialApp(
                debugShowCheckedModeBanner: false,
                title: 'Ecommerce App',
                theme: ThemeData(
                  scaffoldBackgroundColor: const Color(0xFFE5E5E5),
                  primaryColor: Colors.red,
                  appBarTheme: const AppBarTheme(
                    backgroundColor: Colors.white,
                    elevation: 2,
                    iconTheme: IconThemeData(color: Colors.black),
                  ),
                  inputDecorationTheme: InputDecorationTheme(
                    labelStyle: Theme.of(context).textTheme.labelMedium,
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16.0),
                      borderSide: const BorderSide(color: Colors.grey),
                    ),
                    disabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16.0),
                      borderSide: const BorderSide(color: Colors.grey),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16.0),
                      borderSide: const BorderSide(color: Colors.grey),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16.0),
                      borderSide: const BorderSide(color: Colors.red),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16.0),
                      borderSide: const BorderSide(color: Colors.red),
                    ),
                  ),
                ),
                onGenerateRoute: onGenerate,
                initialRoute: state is AuthSuccess
                    ? AppRoutes.bottomNavBarRoute
                    : AppRoutes.loginPageRoute,
              );
            },
          );
        },
      ),
    );
  }
}


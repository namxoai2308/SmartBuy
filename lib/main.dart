import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_ecommerce/controllers/auth/auth_cubit.dart';
import 'package:flutter_ecommerce/controllers/cart/cart_cubit.dart';
import 'package:flutter_ecommerce/controllers/home/home_cubit.dart';
import 'package:flutter_ecommerce/utilities/constants.dart';
import 'package:flutter_ecommerce/utilities/router.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:flutter_ecommerce/views/pages/auth_wrapper.dart';
import 'package:flutter_ecommerce/services/search_history_service.dart';
import 'package:provider/provider.dart';

Future<void> main() async {
  await initSetup();
  runApp(const MyApp());
}

Future<void> initSetup() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  Stripe.publishableKey = AppConstants.publishableKey;
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        Provider<SearchHistoryService>(
          create: (_) => SearchHistoryService(),
        ),
        BlocProvider<AuthCubit>(
          create: (context) => AuthCubit()..authStatus(),
          lazy: false,
        ),
        BlocProvider<CartCubit>(
          create: (context) => CartCubit()..getCartItems(),
        ),
        BlocProvider<HomeCubit>(
          create: (context) => HomeCubit(authCubit: context.read<AuthCubit>()),
          lazy: false,
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Ecommerce App',
        theme: ThemeData(
          scaffoldBackgroundColor: const Color(0xFFE5E5E5),
          primaryColor: Colors.red,
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.white,
            elevation: 1,
            iconTheme: IconThemeData(color: Colors.black),
            titleTextStyle: TextStyle(
              color: Colors.black,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            labelStyle: Theme.of(context).textTheme.bodyMedium,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
              borderSide: const BorderSide(color: Colors.grey),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
              borderSide: const BorderSide(color: Colors.grey),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
              borderSide: BorderSide(color: Colors.red.shade700),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
              borderSide: const BorderSide(color: Colors.red),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
              borderSide: const BorderSide(color: Colors.red, width: 1.5),
            ),
          ),
        ),
        home: const AuthWrapper(),
        onGenerateRoute: onGenerate,
        builder: (context, child) {
          return BlocListener<AuthCubit, AuthState>(
            listener: (context, state) {
              final cartCubit = context.read<CartCubit>();
              if (state is AuthSuccess) {
                print("Main Listener: AuthSuccess -> Getting Cart Items");
                cartCubit.getCartItems();
              } else if (state is AuthInitial) {
                print("Main Listener: AuthInitial -> Clearing Cart State");
                cartCubit.clearCartState();
              }
            },
            listenWhen: (previous, current) => previous.runtimeType != current.runtimeType,
            child: child!,
          );
        },
      ),
    );
  }
}

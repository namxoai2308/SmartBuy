import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';

// THÊM 2 DÒNG IMPORT NÀY:
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart'; // File này sẽ được Flutter tự động tạo

import 'package:flutter_ecommerce/controllers/auth/auth_cubit.dart';
import 'package:flutter_ecommerce/controllers/cart/cart_cubit.dart';
import 'package:flutter_ecommerce/controllers/order/order_cubit.dart';
import 'package:flutter_ecommerce/controllers/checkout/checkout_cubit.dart';
import 'package:flutter_ecommerce/controllers/chat/chat_cubit.dart';
import 'package:flutter_ecommerce/controllers/home/home_cubit.dart';
import 'package:flutter_ecommerce/controllers/theme_notifier.dart';
import 'package:flutter_ecommerce/controllers/locale_notifier.dart'; // <--- THÊM IMPORT LOCALE NOTIFIER

import 'package:flutter_ecommerce/services/search_history_service.dart';
import 'package:flutter_ecommerce/services/order_services.dart';

import 'package:flutter_ecommerce/utilities/constants.dart';
import 'package:flutter_ecommerce/utilities/router.dart'; // Đảm bảo 'onGenerate' được định nghĩa trong file này
import 'package:flutter_ecommerce/utilities/app_themes.dart';

import 'package:flutter_ecommerce/views/pages/auth_wrapper.dart';
import 'package:flutter_stripe/flutter_stripe.dart';

Future<void> main() async {
  await initSetup();
  runApp(
    // SỬ DỤNG MULTIPROVIDER Ở ĐÂY ĐỂ CUNG CẤP CẢ ThemeNotifier và LocaleNotifier
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeNotifier()),
        ChangeNotifierProvider(create: (_) => LocaleNotifier()), // <--- CUNG CẤP LOCALE NOTIFIER
      ],
      child: const MyApp(),
    ),
  );
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
    // MultiBlocProvider cho các Cubits có thể đặt ở đây, bên trong MultiProvider của ChangeNotifier
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
          create: (context) => CartCubit(),
        ),
        BlocProvider<CheckoutCubit>(
          create: (context) => CheckoutCubit(),
        ),
        BlocProvider<HomeCubit>(
          create: (context) => HomeCubit(
            authCubit: context.read<AuthCubit>(),
          ),
          lazy: false,
        ),
        BlocProvider<ChatCubit>(
          create: (context) => ChatCubit(
            authCubit: context.read<AuthCubit>(),
          ),
        ),

                BlocProvider<OrderCubit>(
                  create: (context) => OrderCubit(
                    // Lấy OrderServicesImpl. Bạn có thể tạo mới hoặc lấy từ provider nếu OrderServices cũng được provide
                    orderServices: OrderServicesImpl(),
                    // Lấy AuthCubit đã được cung cấp ở trên
                    authCubit: BlocProvider.of<AuthCubit>(context), // Hoặc context.read<AuthCubit>()
                  ),
                  // KHÔNG gọi fetchCurrentUserOrders() hay fetchAllOrdersForAdmin() ở đây.
                  // Việc fetch sẽ được thực hiện trong initState của từng trang cụ thể.
                ),
      ],
      // SỬ DỤNG CONSUMER2 ĐỂ LẮNG NGHE CẢ HAI NOTIFIER
      child: Consumer2<ThemeNotifier, LocaleNotifier>(
        builder: (context, themeNotifier, localeNotifier, _) {
          print("MyApp rebuilding. Current Locale from Notifier: ${localeNotifier.appLocale}");
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            onGenerateTitle: (BuildContext context) {
              // Đảm bảo AppLocalizations có sẵn trước khi sử dụng
              // Hoặc cung cấp giá trị mặc định nếu AppLocalizations.of(context) là null
              // Điều này hiếm khi xảy ra nếu delegates được thiết lập đúng.
              return AppLocalizations.of(context)?.appTitle ?? 'Ecommerce App';
            },
            theme: AppThemes.lightTheme,
            darkTheme: AppThemes.darkTheme,
            themeMode: themeNotifier.currentThemeMode,

            // --- CẬP NHẬT ĐỂ SỬ DỤNG LOCALE TỪ NOTIFIER ---
            locale: localeNotifier.appLocale, // <--- SỬ DỤNG LOCALE TỪ LOCALE NOTIFIER
            // Nếu localeNotifier.appLocale là null, MaterialApp sẽ dùng ngôn ngữ hệ thống
            // hoặc fallback về supportedLocales[0]

            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('en', ''),
              Locale('vi', ''),
              Locale('fr', ''), // Thêm các ngôn ngữ bạn đã tạo file .arb
              Locale('es', ''), // và muốn hỗ trợ trong LanguagesPage
            ],
            // --- KẾT THÚC CẬP NHẬT ---

            home: const AuthWrapper(),
            onGenerateRoute: onGenerate,
            builder: (context, child) {
              return BlocListener<AuthCubit, AuthState>(
                listenWhen: (prev, curr) =>
                    prev.runtimeType != curr.runtimeType,
                listener: (context, state) {
                  final cartCubit = context.read<CartCubit>();
                  final chatCubit = context.read<ChatCubit>();
                  if (state is AuthSuccess) {
                    print("Main Listener: AuthSuccess -> Loading Cart & Chat");
                    cartCubit.getCartItems();
                    chatCubit.loadUser(state.user.uid, state.user.role);
                  } else if (state is AuthInitial || state is AuthFailed) {
                    print("Main Listener: AuthInitial/Failed -> Clearing Cart & Chat State");
                    cartCubit.clearCartState();
                    chatCubit.clearChatData();
                  }
                },
                child: child!,
              );
            },
          );
        },
      ),
    );
  }
}
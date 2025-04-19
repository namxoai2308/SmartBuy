import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_ecommerce/controllers/checkout/checkout_cubit.dart';
import 'package:flutter_ecommerce/controllers/product_details/product_details_cubit.dart';
import 'package:flutter_ecommerce/models/shipping_address.dart';
import 'package:flutter_ecommerce/utilities/args_models/add_shipping_address_args.dart';
import 'package:flutter_ecommerce/utilities/routes.dart';
import 'package:flutter_ecommerce/views/pages/bottom_navbar.dart';
import 'package:flutter_ecommerce/views/pages/checkout/add_shipping_address_page.dart';
import 'package:flutter_ecommerce/views/pages/checkout/checkout_page.dart';
import 'package:flutter_ecommerce/views/pages/checkout/payment_methods_page.dart';
import 'package:flutter_ecommerce/views/pages/checkout/shipping_addresses_page.dart';
import 'package:flutter_ecommerce/views/pages/auth_page.dart';
import 'package:flutter_ecommerce/views/pages/product_details.dart';
import 'package:flutter_ecommerce/views/pages/checkout/order_success_page.dart';
import 'package:flutter_ecommerce/views/pages/profile/my_orders_page.dart';
import 'package:flutter_ecommerce/controllers/auth/auth_cubit.dart';
import 'package:flutter_ecommerce/services/order_services.dart';
import 'package:flutter_ecommerce/controllers/order/order_cubit.dart';
import 'package:flutter_ecommerce/models/order_model.dart';
import 'package:flutter_ecommerce/views/pages/profile/order_details_page.dart';

Route<dynamic> onGenerate(RouteSettings settings) {
  switch (settings.name) {
    case AppRoutes.loginPageRoute:
      return CupertinoPageRoute(
        builder: (_) => const AuthPage(),
        settings: settings,
      );
    case AppRoutes.bottomNavBarRoute:
      return CupertinoPageRoute(
        builder: (_) => const BottomNavbar(),
        settings: settings,
      );
    case AppRoutes.checkoutPageRoute:
      return CupertinoPageRoute(
        builder: (_) => BlocProvider(
          create: (context) {
            final cubit = CheckoutCubit();
            cubit.getCheckoutData();
            return cubit;
          },
          child: const CheckoutPage(),
        ),
        settings: settings,
      );
    case AppRoutes.productDetailsRoute:
      final productId = settings.arguments as String;

      return CupertinoPageRoute(
        builder: (_) => BlocProvider(
          create: (context) {
            final cubit = ProductDetailsCubit();
            cubit.getProductDetails(productId);
            return cubit;
          },
          child: const ProductDetails(),
        ),
        settings: settings,
      );

    case AppRoutes.shippingAddressesRoute:
      final checkoutCubit = settings.arguments as CheckoutCubit;
      return CupertinoPageRoute(
        builder: (_) => BlocProvider.value(
          value: checkoutCubit,
          child: const ShippingAddressesPage(),
        ),
        settings: settings,
      );
    case AppRoutes.paymentMethodsRoute:
      return CupertinoPageRoute(
        builder: (_) => BlocProvider(
          create: (context) {
            final cubit = CheckoutCubit();
            cubit.fetchCards();
            return cubit;
          },
          child: const PaymentMethodsPage(),
        ),
        settings: settings,
      );

    case AppRoutes.orderSuccessRoute:
          return CupertinoPageRoute(
            builder: (_) => const OrderSuccessPage(),
            settings: settings,
          );

    case AppRoutes.addShippingAddressRoute:
      final args = settings.arguments as AddShippingAddressArgs;
      final checkoutCubit = args.checkoutCubit;
      final shippingAddress = args.shippingAddress;

      return CupertinoPageRoute(
        builder: (_) => BlocProvider.value(
          value: checkoutCubit,
          child: AddShippingAddressPage(
            shippingAddress: shippingAddress,
          ),
        ),
        settings: settings,
      );
    case AppRoutes.myOrdersPageRoute: // <-- THÊM CASE NÀY
          return CupertinoPageRoute( // Hoặc MaterialPageRoute tùy bạn chọn
            builder: (context) {
              // Lấy AuthCubit đã được cung cấp ở cây widget phía trên
              // Đảm bảo AuthCubit được cung cấp ở nơi cao hơn (ví dụ: main.dart)
              final authCubit = BlocProvider.of<AuthCubit>(context);

              // Tạo instance của OrderServices
              // Lưu ý: Nếu bạn dùng Dependency Injection (DI), hãy lấy service từ DI container
              final orderServices = OrderServicesImpl();

              // Cung cấp OrderCubit cho trang MyOrdersPage và các widget con của nó
              return BlocProvider(
                create: (context) => OrderCubit(
                  orderServices: orderServices,
                  authCubit: authCubit, // Truyền AuthCubit vào
                )..fetchOrders(), // Gọi fetchOrders() ngay khi Cubit được tạo
                child: const MyOrdersPage(), // Trả về widget trang MyOrdersPage
              );
            },
            settings: settings, // Chuyển tiếp settings nếu cần
          );


    default:
      return CupertinoPageRoute(
        builder: (_) => const AuthPage(),
        settings: settings,
      );
  }
}

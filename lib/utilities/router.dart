import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart'; // Import nếu cần MaterialPageRoute
import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:flutter_ecommerce/controllers/checkout/checkout_cubit.dart'; // Không cần import trực tiếp ở đây nữa
import 'package:flutter_ecommerce/controllers/product_details/product_details_cubit.dart';
// import 'package:flutter_ecommerce/models/checkout/shipping_address.dart'; // Không cần
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
import 'package:flutter_ecommerce/services/order_services.dart'; // Giữ lại vì dùng trong MyOrdersPage case
import 'package:flutter_ecommerce/controllers/order/order_cubit.dart';
import 'package:flutter_ecommerce/models/order/order_model.dart';
import 'package:flutter_ecommerce/views/pages/profile/order_details_page.dart';
import 'package:flutter_ecommerce/views/pages/chat/chat_seller_target_waiting_page.dart';
import 'package:flutter_ecommerce/views/pages/profile/settings_page.dart';
import 'package:flutter_ecommerce/views/pages/profile/languages_page.dart';

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

    // --- SỬA ĐỔI: CHECKOUT PAGE ---
    case AppRoutes.checkoutPageRoute:
      // Bỏ BlocProvider tạo mới CheckoutCubit.
      // Giả định CheckoutCubit đã được cung cấp ở scope cao hơn.
      return CupertinoPageRoute(
        builder: (_) => const CheckoutPage(), // Trang này sẽ tự lấy Cubit từ context
        settings: settings,
      );
    // --- KẾT THÚC SỬA ĐỔI ---

    case AppRoutes.productDetailsRoute:
      final productId = settings.arguments as String;
      // Giữ lại BlocProvider cục bộ cho ProductDetailsCubit
      return CupertinoPageRoute(
        builder: (context) {
          return BlocProvider(
            create: (context) => ProductDetailsCubit()..getProductDetails(productId),
            child: ProductDetails(productId: productId),
          );
        },
        settings: settings,
      );

    // --- SỬA ĐỔI: SHIPPING ADDRESSES PAGE ---
    case AppRoutes.shippingAddressesRoute:
      // final checkoutCubit = settings.arguments as CheckoutCubit; // <- Bỏ dòng này
      // Bỏ BlocProvider.value.
      // Giả định CheckoutCubit đã được cung cấp ở scope cao hơn.
      return CupertinoPageRoute(
        builder: (_) => const ShippingAddressesPage(), // Trang này sẽ tự lấy Cubit từ context
        settings: settings,
      );
    // --- KẾT THÚC SỬA ĐỔI ---

    // --- SỬA ĐỔI: PAYMENT METHODS PAGE ---
    case AppRoutes.paymentMethodsRoute:
      // Bỏ BlocProvider tạo mới CheckoutCubit.
      // Giả định CheckoutCubit đã được cung cấp ở scope cao hơn.
      // Lưu ý: Logic gọi cubit.fetchCards() cần được chuyển vào initState
      // hoặc một thời điểm thích hợp khác bên trong PaymentMethodsPage.
      return CupertinoPageRoute(
        builder: (_) => const PaymentMethodsPage(), // Trang này sẽ tự lấy Cubit từ context
        settings: settings,
      );
    // --- KẾT THÚC SỬA ĐỔI ---

    case AppRoutes.orderSuccessRoute:
      return CupertinoPageRoute(
        builder: (_) => const OrderSuccessPage(),
        settings: settings,
      );

    // --- SỬA ĐỔI: ADD SHIPPING ADDRESS PAGE ---
    case AppRoutes.addShippingAddressRoute:
      // Lấy dữ liệu khác ngoài cubit một cách an toàn hơn
       final shippingAddress = (settings.arguments is AddShippingAddressArgs)
          ? (settings.arguments as AddShippingAddressArgs).shippingAddress
          : null;
      // Bỏ BlocProvider.value.
      // Giả định CheckoutCubit đã được cung cấp ở scope cao hơn.
      return CupertinoPageRoute(
        builder: (_) => AddShippingAddressPage(
          shippingAddress: shippingAddress, // Chỉ truyền dữ liệu cần thiết
        ), // Trang này sẽ tự lấy Cubit từ context
        settings: settings,
      );
    // --- KẾT THÚC SỬA ĐỔI ---

    // --- KHÔNG SỬA ĐỔI: MY ORDERS PAGE ---
//     case AppRoutes.myOrdersPageRoute:
//       return CupertinoPageRoute(
//         builder: (context) {
//           // Logic tạo OrderCubit được giữ nguyên theo yêu cầu
//           final authCubit = BlocProvider.of<AuthCubit>(context); // Hoặc context.read
//           final orderServices = OrderServicesImpl();
//           return BlocProvider(
//             create: (context) => OrderCubit(
//               orderServices: orderServices, // Đảm bảo cung cấp đúng dependency
//               authCubit: authCubit,
//             )..fetchOrders(),
//             child: const MyOrdersPage(),
//           );
//         },
//         settings: settings,
//       );
    // --- KẾT THÚC KHÔNG SỬA ĐỔI ---
 case AppRoutes.myOrdersPageRoute:
      // Vì OrderCubit đã được cung cấp toàn cục ở main.dart,
      // MyOrdersPage sẽ tự động truy cập được nó thông qua context.
      // Chúng ta không cần tạo BlocProvider ở đây nữa.
      return CupertinoPageRoute( // Hoặc MaterialPageRoute tùy theo sở thích của bạn
        builder: (_) => const MyOrdersPage(), // Chỉ cần trả về widget trang
        settings: settings, // Giữ lại settings để truyền arguments nếu có trong tương lai
      );

    case AppRoutes.chatWaitingPageRoute:
      // Giả định ChatCubit đã được cung cấp ở scope cao hơn
      return CupertinoPageRoute(
        builder: (_) => const ChatSellerTargetWaitingPage(),
        settings: settings,
      );

    case AppRoutes.settingsPageRoute:
      // Giả định ThemeNotifier đã được cung cấp ở scope cao hơn
      return CupertinoPageRoute(
        builder: (_) => const SettingsPage(),
        settings: settings,
      );

    case AppRoutes.languagesPageRoute:
      return CupertinoPageRoute(
        builder: (_) => const LanguagesPage(),
        settings: settings,
      );


    default:
      // Route mặc định
      return CupertinoPageRoute(
        builder: (_) => const AuthPage(), // Hoặc trang lỗi
        settings: settings,
      );
  }
}
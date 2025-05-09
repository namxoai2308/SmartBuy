import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_ecommerce/controllers/cart/cart_cubit.dart';
import 'package:flutter_ecommerce/controllers/checkout/checkout_cubit.dart';
import 'package:flutter_ecommerce/views/pages/cart_page.dart';
import 'package:flutter_ecommerce/views/pages/home/home_page.dart';
import 'package:flutter_ecommerce/views/pages/profile/profle_page.dart';
import 'package:flutter_ecommerce/views/pages/home/shop_page.dart';
import 'package:persistent_bottom_nav_bar_v2/persistent_bottom_nav_bar_v2.dart';
import 'package:flutter_ecommerce/controllers/home/home_cubit.dart';
import 'chatbot_page.dart';
import 'chatbot_wrapper.dart';

class BottomNavbar extends StatefulWidget {
  const BottomNavbar({super.key});

  @override
  State<BottomNavbar> createState() => _BottomNavbarState();
}

class _BottomNavbarState extends State<BottomNavbar> {
  final _bottomNavbarController = PersistentTabController();

  final List<Widget> _screens = [
    const HomePage(),
    const ShopPage(),
    const CartPage(),
      BlocBuilder<HomeCubit, HomeState>(
         buildWhen: (prev, curr) => curr is HomeSuccess,
         builder: (context, homeState) {
           if (homeState is HomeSuccess) {
              return ChatbotWrapper(products: homeState.allProducts);
           }
           return const Center(child: Text("Loading Chatbot..."));
         }
      ),
    BlocProvider(
      create: (_) => CheckoutCubit()..getCheckoutData(),
      child: const ProfilePage(),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PersistentTabView(
        controller: _bottomNavbarController,
        tabs: [
          PersistentTabConfig(
            screen: _screens[0],
            item: ItemConfig(
              icon: const Icon(CupertinoIcons.home),
              title: ("Home"),
              activeForegroundColor: Colors.redAccent,
            ),
          ),
          PersistentTabConfig(
            screen: _screens[1],
            item: ItemConfig(
              icon: const Icon(CupertinoIcons.bag),
              title: ("Shop"),
              activeForegroundColor: Colors.redAccent,
            ),
          ),
          PersistentTabConfig(
            screen: _screens[2],
            item: ItemConfig(
              icon: const Icon(CupertinoIcons.shopping_cart),
              title: ("Cart"),
              activeForegroundColor: Colors.redAccent,
            ),
          ),
          PersistentTabConfig(
            screen: _screens[3],
            item: ItemConfig(
              icon: const Icon(Icons.smart_toy),
              title: ("Chatbot"),
              activeForegroundColor: Colors.redAccent,
            ),
          ),
          PersistentTabConfig(
            screen: _screens[4],
            item: ItemConfig(
              icon: const Icon(CupertinoIcons.profile_circled),
              title: ("Profile"),
              activeForegroundColor: Colors.redAccent,
            ),
          ),
        ],
        navBarBuilder: (navbarConfig) => Style1BottomNavBar(
          navBarConfig: navbarConfig,
        ),
        backgroundColor: Colors.white,
        handleAndroidBackButtonPress: true,
        resizeToAvoidBottomInset: true,
        stateManagement: true,
        popAllScreensOnTapOfSelectedTab: true,
        popActionScreens: PopActionScreensType.all,
        screenTransitionAnimation: const ScreenTransitionAnimation(
          curve: Curves.ease,
          duration: Duration(milliseconds: 200),
        ),
      ),
    );
  }
}

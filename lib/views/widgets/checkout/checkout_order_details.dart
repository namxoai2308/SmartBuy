import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_ecommerce/controllers/cart/cart_cubit.dart';
import 'package:flutter_ecommerce/controllers/checkout/checkout_cubit.dart';
import 'package:flutter_ecommerce/views/widgets/order_summary_component.dart';

class CheckoutOrderDetails extends StatelessWidget {
  const CheckoutOrderDetails({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CartCubit, CartState>(
      builder: (context, cartState) {
        return BlocBuilder<CheckoutCubit, CheckoutState>(
          builder: (context, checkoutState) {
            if (cartState is CartLoaded) {
              final totalAmount = cartState.totalAmount;

              double delivery = 0.0;
              if (checkoutState is CheckoutLoaded &&
                  checkoutState.selectedDeliveryMethod != null) {
                delivery = checkoutState.selectedDeliveryMethod!.price.toDouble();
              }

              final summary = totalAmount + delivery;

              return Column(
                children: [
                  OrderSummaryComponent(
                      title: 'Order',
                      value: '\$${totalAmount.toStringAsFixed(2)}'),
                  const SizedBox(height: 8.0),
                  OrderSummaryComponent(
                      title: 'Delivery',
                      value: '\$${delivery.toStringAsFixed(2)}'),
                  const SizedBox(height: 8.0),
                  OrderSummaryComponent(
                      title: 'Summary',
                      value: '\$${summary.toStringAsFixed(2)}'),
                ],
              );
            } else if (cartState is CartLoading) {
              return const Center(child: CircularProgressIndicator());
            } else {
              return const Text('Unable to load cart data');
            }
          },
        );
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_ecommerce/controllers/cart/cart_cubit.dart';
import 'package:flutter_ecommerce/views/widgets/order_summary_component.dart';

class CheckoutOrderDetails extends StatelessWidget {
  const CheckoutOrderDetails({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CartCubit, CartState>(
      builder: (context, state) {
        if (state is CartLoaded) {
          final totalAmount = state.totalAmount;
          final delivery = totalAmount * 0.05;
          final summary = totalAmount + delivery;

          return Column(
            children: [
              OrderSummaryComponent(title: 'Order', value: '\$${totalAmount.toStringAsFixed(2)}'),
              const SizedBox(height: 8.0),
              OrderSummaryComponent(title: 'Delivery', value: '\$${delivery.toStringAsFixed(2)}'),
              const SizedBox(height: 8.0),
              OrderSummaryComponent(title: 'Summary', value: '\$${summary.toStringAsFixed(2)}'),
            ],
          );
        } else if (state is CartLoading) {
          return const Center(child: CircularProgressIndicator());
        } else {
          return const Text('Unable to load cart data');
        }
      },
    );
  }
}

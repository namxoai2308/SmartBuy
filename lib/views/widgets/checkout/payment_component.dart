import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_ecommerce/controllers/checkout/checkout_cubit.dart';
import 'package:flutter_ecommerce/utilities/assets.dart';

class PaymentComponent extends StatelessWidget {
  const PaymentComponent({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CheckoutCubit, CheckoutState>(
      builder: (context, state) {
        if (state is CheckoutLoaded) {
        print("Selected Payment Method in UI: ${state.selectedPaymentMethod}");
          if (state.selectedPaymentMethod == null) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'No payment method added. Add one.',
                style: TextStyle(fontSize: 16, color: Colors.redAccent),
              ),
            );
          } else {
            final selectedPaymentMethod = state.selectedPaymentMethod;
            final last4Digits = selectedPaymentMethod?.cardNumber.substring(
                selectedPaymentMethod!.cardNumber.length - 4);
            return Row(
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16.0),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: Image.network(
                      AppAssets.mastercardIcon,
                      fit: BoxFit.cover,
                      height: 30,
                    ),
                  ),
                ),
                const SizedBox(width: 16.0),
                Text('**** **** **** $last4Digits'),
              ],
            );
          }
        }
        return const SizedBox.shrink();
      },
    );
  }
}


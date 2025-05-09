import 'package:flutter/material.dart';
import 'package:flutter_ecommerce/controllers/checkout/checkout_cubit.dart';
import 'package:flutter_ecommerce/models/checkout/shipping_address.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_ecommerce/views/pages/checkout/shipping_addresses_page.dart';

class ShippingAddressComponent extends StatelessWidget {
  final ShippingAddress shippingAddress;
  final CheckoutCubit checkoutCubit;

  const ShippingAddressComponent({
    super.key,
    required this.shippingAddress,
    required this.checkoutCubit,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  shippingAddress.fullName,
                  style: Theme.of(context).textTheme.labelMedium!.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                ),
                InkWell(
                  onTap: () {
                    Navigator.of(context).push(
                      PageRouteBuilder(
                        pageBuilder: (_, __, ___) => BlocProvider.value(
                          value: checkoutCubit,
                          child: const ShippingAddressesPage(),
                        ),
                        transitionsBuilder:
                            (context, animation, secondaryAnimation, child) {
                          const begin = Offset(1.0, 0.0);
                          const end = Offset.zero;
                          const curve = Curves.ease;
                          final tween = Tween(begin: begin, end: end)
                              .chain(CurveTween(curve: curve));
                          return SlideTransition(
                            position: animation.drive(tween),
                            child: child,
                          );
                        },
                      ),
                    );
                  },
                  child: Text(
                    'Change',
                    style: Theme.of(context).textTheme.labelSmall!.copyWith(
                          color: Colors.redAccent,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8.0),
            Text(
              shippingAddress.address,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: Colors.black,
                  ),
            ),
            Text(
              '${shippingAddress.city}, ${shippingAddress.state}, ${shippingAddress.country}',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: Colors.black,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_ecommerce/controllers/checkout/checkout_cubit.dart';
import 'package:flutter_ecommerce/models/checkout/shipping_address.dart';
import 'package:flutter_ecommerce/utilities/args_models/add_shipping_address_args.dart';
import 'package:flutter_ecommerce/utilities/routes.dart';

class ShippingAddressStateItem extends StatefulWidget {
  final ShippingAddress shippingAddress;
  final VoidCallback? onTap;

  const ShippingAddressStateItem({
    super.key,
    required this.shippingAddress,
    this.onTap,
  });

  @override
  State<ShippingAddressStateItem> createState() => _ShippingAddressStateItemState();
}

class _ShippingAddressStateItemState extends State<ShippingAddressStateItem> {
  late bool checkedValue;

  @override
  void initState() {
    super.initState();
    checkedValue = widget.shippingAddress.isDefault;
  }

  @override
  Widget build(BuildContext context) {
    final checkoutCubit = context.read<CheckoutCubit>();

    return InkWell(
      onTap: widget.onTap,
      borderRadius: BorderRadius.circular(12),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.shippingAddress.fullName,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                  ),
                  InkWell(
                    onTap: () async {
                      final result = await Navigator.of(context).pushNamed(
                        AppRoutes.addShippingAddressRoute,
                        arguments: AddShippingAddressArgs(
                          shippingAddress: widget.shippingAddress,
                          checkoutCubit: checkoutCubit,
                        ),
                      );
                      if (result == true && mounted) {
                        checkoutCubit.getShippingAddresses();
                      }
                    },
                    child: Text(
                      'Edit',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: Colors.redAccent,
                          ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                widget.shippingAddress.address,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(color: Colors.black),
              ),
              Text(
                '${widget.shippingAddress.city}, ${widget.shippingAddress.state}, ${widget.shippingAddress.country}',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(color: Colors.black),
              ),
              CheckboxListTile(
                title: const Text(
                  "Default shipping address",
                  style: TextStyle(color: Colors.black),
                ),
                value: checkedValue,
                onChanged: (newValue) async {
                  if (newValue == null || !newValue) return;

                  setState(() {
                    checkedValue = true;
                  });

                  final updated = widget.shippingAddress.copyWith(isDefault: true);
                  await checkoutCubit.saveAddress(updated);

                  if (mounted) {
                    checkoutCubit.getShippingAddresses();
                  }
                },
                activeColor: Colors.black,
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

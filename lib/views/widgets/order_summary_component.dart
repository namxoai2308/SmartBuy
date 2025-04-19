import 'package:flutter/material.dart';

class OrderSummaryComponent extends StatelessWidget {
  final String title;
  final String value;

  const OrderSummaryComponent({
    Key? key,
    required this.title,
    required this.value,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          '$title:',
          style: Theme.of(context).textTheme.labelSmall!.copyWith(
                color: Colors.grey,
                fontSize: 14,
              ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.titleSmall!.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }
}

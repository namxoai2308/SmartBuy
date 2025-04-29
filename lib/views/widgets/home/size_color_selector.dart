import 'package:flutter/material.dart';

class SizeColorSelectorWidget extends StatelessWidget {
  final List<String> sizeOptions;
  final List<String> colorOptions;
  final String? selectedSize;
  final String? selectedColor;
  final ValueChanged<String> onSizeChanged;
  final ValueChanged<String> onColorChanged;

  const SizeColorSelectorWidget({
    Key? key,
    required this.sizeOptions,
    required this.colorOptions,
    required this.selectedSize,
    required this.selectedColor,
    required this.onSizeChanged,
    required this.onColorChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            SizedBox(
              width: 140,
              height: 50,
              child: DropDownMenuComponent(
                items: sizeOptions,
                hint: 'Size',
                value: selectedSize,
                onChanged: (String? newValue) {
                  if (newValue != null) onSizeChanged(newValue);
                },
              ),
            ),
            const SizedBox(width: 16),
            SizedBox(
              width: 140,
              height: 50,
              child: DropDownMenuComponent(
                items: colorOptions,
                hint: 'Color',
                value: selectedColor,
                onChanged: (String? newValue) {
                  if (newValue != null) onColorChanged(newValue);
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}

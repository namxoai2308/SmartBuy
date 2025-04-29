import 'package:flutter/material.dart';

class SelectOptionComponent extends StatefulWidget {
  final String title;
  final List<String> options;
  final String? initialSelected;
  final void Function(String selectedValue) onDone;

  const SelectOptionComponent({
    Key? key,
    required this.title,
    required this.options,
    this.initialSelected,
    required this.onDone,
  }) : super(key: key);

  @override
  State<SelectOptionComponent> createState() => _SelectOptionComponentState();
}

class _SelectOptionComponentState extends State<SelectOptionComponent> {
  String? selectedValue;

  @override
  void initState() {
    super.initState();
    selectedValue = widget.initialSelected;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: MediaQuery.of(context).viewInsets.add(const EdgeInsets.all(20)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Center(
            child: Text(
              'Select ${widget.title}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 24),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: widget.options.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 2.5,
            ),
            itemBuilder: (context, index) {
              final value = widget.options[index];
              final isSelected = selectedValue == value;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    selectedValue = value;
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.red : Colors.white,
                    border: Border.all(
                      color: isSelected ? Colors.red : Colors.grey.shade400,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    value,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.black,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: selectedValue == null
                  ? null
                  : () {
                      widget.onDone(selectedValue!);
                      Navigator.pop(context);
                    },
              child: Text(
                'Done',
                style: TextStyle(
                  fontSize: 16,
                  color: selectedValue == null ? Colors.grey : Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

void showSelectOptionBottomSheet({
  required BuildContext context,
  required String title,
  required List<String> options,
  required Function(String selected) onSelected,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => SelectOptionComponent(
      title: title,
      options: options,
      onDone: onSelected,
    ),
  );
}
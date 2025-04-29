import 'package:flutter/material.dart';
import 'package:flutter_ecommerce/models/filter_criteria.dart';

class FilterModal extends StatefulWidget {
  final void Function(FilterCriteria criteria)? onApply;
  final FilterCriteria? initialCriteria;

  const FilterModal({
    super.key,
    this.onApply,
    this.initialCriteria,
  });

  @override
  State<FilterModal> createState() => _FilterModalState();
}

class _FilterModalState extends State<FilterModal> {
  late RangeValues _selectedPriceRange;
  late String _selectedCategory;
  late List<String> _selectedBrands;
  Color? _selectedUIColor;
  String? _selectedUISize;

  final double _minPrice = FilterCriteria.defaultMinPrice;
  final double _maxPrice = FilterCriteria.defaultMaxPrice;
  final List<Color> _uiColors = [ Colors.black, Colors.white, Colors.red, Colors.brown[200]!, Colors.amber[100]!, Colors.indigo ];
  final List<String> _uiSizes = ['XS', 'S', 'M', 'L', 'XL'];
  final List<String> _availableCategories = ['All', 'clothing', 'shoes', 'Jewelry'];
  final List<String> _availableBrands = ['Adidas', 'Cartier', 'Gucci', 'Nike', 'H&M', 'Levis', 'Prada', 'Zara'];

  @override
  void initState() {
    super.initState();
    final initial = widget.initialCriteria ?? FilterCriteria.initial();
    _selectedPriceRange = initial.priceRange;
    _selectedCategory = initial.selectedCategory;
    _selectedBrands = List.from(initial.selectedBrands);
    _selectedUIColor = null;
    _selectedUISize = null;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   Text(
                    'Filters',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ),
              const Divider(),
              const SizedBox(height: 10),

              const Text('Price range', style: TextStyle(fontWeight: FontWeight.bold)),
              RangeSlider(
                values: _selectedPriceRange,
                min: _minPrice,
                max: _maxPrice,
                labels: RangeLabels(
                  '\$${_selectedPriceRange.start.round()}',
                  '\$${_selectedPriceRange.end.round()}',
                ),
                onChanged: (range) => setState(() => _selectedPriceRange = range),
                activeColor: Colors.red,
                inactiveColor: Colors.red.shade100,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('\$${_selectedPriceRange.start.round()}'),
                  Text('\$${_selectedPriceRange.end.round()}'),
                ],
              ),
              const SizedBox(height: 20),

              const Text('Colors (Display Only)', style: TextStyle(fontWeight: FontWeight.bold)),
               const SizedBox(height: 8),
              Wrap(
                spacing: 8.0,
                runSpacing: 8.0,
                children: _uiColors.map((color) {
                  final isSelected = _selectedUIColor == color;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedUIColor = isSelected ? null : color),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? Colors.red : Colors.grey.shade300,
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                             color: Colors.grey.withOpacity(0.3),
                             spreadRadius: 1,
                             blurRadius: 2,
                             offset: Offset(0, 1),
                          )
                        ]
                      ),
                      // Bỏ Icon check ở đây
                      child: null,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              const Text('Sizes (Display Only)', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: _uiSizes.map((size) {
                  final isSelected = _selectedUISize == size;
                  return ChoiceChip(
                    label: Text(size),
                    selected: isSelected,
                    onSelected: (sel) => setState(() => _selectedUISize = sel ? size : null),
                    selectedColor: Colors.red,
                    labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black),
                    backgroundColor: Colors.grey[200],
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                     side: BorderSide(color: isSelected ? Colors.red : Colors.grey.shade300),
                     padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                     showCheckmark: false,
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              const Text('Category', style: TextStyle(fontWeight: FontWeight.bold)),
               const SizedBox(height: 8),
              Wrap(
                spacing: 10,
                 runSpacing: 10,
                children: _availableCategories.map((cat) {
                  final isSelected = _selectedCategory == cat;
                  return ChoiceChip(
                    label: Text(cat),
                    selected: isSelected,
                    onSelected: (sel) { if(sel) setState(() => _selectedCategory = cat); },
                     selectedColor: Colors.red,
                    labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black),
                     backgroundColor: Colors.grey[200],
                     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                     side: BorderSide(color: isSelected ? Colors.red : Colors.grey.shade300),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      showCheckmark: false,
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              const Text('Brand', style: TextStyle(fontWeight: FontWeight.bold)),
               const SizedBox(height: 8),
               Wrap(
                 spacing: 10.0,
                 runSpacing: 10.0,
                 children: _availableBrands.map((brand) {
                    final isSelected = _selectedBrands.contains(brand);
                    return FilterChip(
                      label: Text(brand),
                      selected: isSelected,
                      onSelected: (sel) {
                        setState(() {
                          if (sel) _selectedBrands.add(brand);
                          else _selectedBrands.remove(brand);
                        });
                      },
                      selectedColor: Colors.red,
                      labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black),
                      backgroundColor: Colors.grey[200],
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      side: BorderSide(color: isSelected ? Colors.red : Colors.grey.shade300),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),

                      showCheckmark: false, // Hoặc đặt thành false
                    );
                 }).toList(),
               ),
              const SizedBox(height: 30),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.black,
                        side: BorderSide(color: Colors.grey.shade400),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Discard'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        final appliedCriteria = FilterCriteria(
                          priceRange: _selectedPriceRange,
                          selectedCategory: _selectedCategory,
                          selectedBrands: List.from(_selectedBrands),
                        );
                        widget.onApply?.call(appliedCriteria);
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                         padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Apply'),
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
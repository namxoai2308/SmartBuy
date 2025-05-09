// lib/models/filter_criteria.dart
import 'package:flutter/material.dart';
import 'package:equatable/equatable.dart';

class FilterCriteria extends Equatable {
  final RangeValues priceRange;
  final String selectedCategory;
  final List<String> selectedBrands; // <-- Phải có trường này

  static const double defaultMinPrice = 0;
  static const double defaultMaxPrice = 1000;
  static const defaultPriceRange = RangeValues(defaultMinPrice, defaultMaxPrice);

  const FilterCriteria({
    this.priceRange = defaultPriceRange,
    this.selectedCategory = 'All',
    this.selectedBrands = const [], // <-- Khởi tạo rỗng
  });

  factory FilterCriteria.initial() {
    return const FilterCriteria();
  }

  bool get isAnyFilterApplied =>
      selectedCategory != 'All' ||
      selectedBrands.isNotEmpty ||
      priceRange != defaultPriceRange;

  @override
  List<Object?> get props => [priceRange, selectedCategory, selectedBrands];

  FilterCriteria copyWith({
    RangeValues? priceRange,
    String? selectedCategory,
    List<String>? selectedBrands,
  }) {
    return FilterCriteria(
      priceRange: priceRange ?? this.priceRange,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      selectedBrands: selectedBrands ?? this.selectedBrands, // <-- Copy brands
    );
  }
}
import 'package:flutter_ecommerce/models/product.dart';
import 'package:flutter_ecommerce/views/pages/home/shop_page.dart';

class ProductFilterService {
  static List<Product> filterAndSortProducts({
    required List<Product> products,
    required String searchQuery,
    required String selectedCategory,
    required SortOption selectedSortOption,
  }) {
    final filteredProducts = products.where((product) {
      final titleMatch = (product.title ?? '').toLowerCase().contains(searchQuery.toLowerCase());
      final categoryMatch = selectedCategory == 'All' || product.category == selectedCategory;
      return titleMatch && categoryMatch;
    }).toList();

    filteredProducts.sort((a, b) {
      switch (selectedSortOption) {
        case SortOption.priceLowToHigh:
          return (a.price ?? 0).compareTo(b.price ?? 0);
        case SortOption.priceHighToLow:
          return (b.price ?? 0).compareTo(a.price ?? 0);
        case SortOption.popular:
        case SortOption.newest:
        case SortOption.customerReview:
          return (b.rate ?? 0).compareTo(a.rate ?? 0);
        default:
          return 0;
      }
    });

    return filteredProducts;
  }
}

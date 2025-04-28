import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_ecommerce/controllers/auth/auth_cubit.dart';
import 'package:flutter_ecommerce/controllers/home/home_cubit.dart';
import 'package:flutter_ecommerce/models/product.dart';
import 'package:flutter_ecommerce/services/search_history_service.dart';
import 'package:flutter_ecommerce/views/widgets/home/list_item_home.dart';
import 'package:flutter_ecommerce/services/product_filter_service.dart';


enum SortOption { popular, newest, customerReview, priceLowToHigh, priceHighToLow }

class ShopPage extends StatefulWidget {
  const ShopPage({Key? key}) : super(key: key);

  @override
  State<ShopPage> createState() => _ShopPageState();
}

class _ShopPageState extends State<ShopPage> {
  bool isSearching = false;
  String searchQuery = '';
  final TextEditingController searchController = TextEditingController();
  final SearchHistoryService _searchHistoryService = SearchHistoryService();

  String selectedCategory = 'All';
  SortOption selectedSortOption = SortOption.priceLowToHigh;
  final List<String> categories = ['All', 'Clothing', 'Shoes', 'Jewelry', 'electronics', 'furniture', 'others'];

  int _searchActionCount = 0;
  static const int _searchRefreshThreshold = 10;

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  void _saveSearchQueryAndCheckRefresh() {
    final trimmedQuery = searchQuery.trim();
    if (trimmedQuery.isNotEmpty) {
      _searchHistoryService.addSearchTerm(trimmedQuery);
      _searchActionCount++;

      if (_searchActionCount > 0 && _searchActionCount % _searchRefreshThreshold == 0) {
        final authState = context.read<AuthCubit>().state;
        String? userId = (authState is AuthSuccess) ? authState.user.uid : null;
        context.read<HomeCubit>().refreshRecommendations(userId: userId);
      }
    }
  }

  void _showSortOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: SortOption.values.map((option) {
              return ListTile(
                title: Text(_getSortOptionText(option)),
                onTap: () {
                  setState(() {
                    selectedSortOption = option;
                  });
                  Navigator.pop(context);
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }

  String _getSortOptionText(SortOption option) {
    switch (option) {
      case SortOption.popular:
        return 'Popular';
      case SortOption.newest:
        return 'Newest';
      case SortOption.customerReview:
        return 'Customer review';
      case SortOption.priceLowToHigh:
        return 'Price: lowest to high';
      case SortOption.priceHighToLow:
        return 'Price: highest to low';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        elevation: 0,
        title: isSearching
            ? TextField(
                controller: searchController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Search products...',
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.clear, color: Colors.grey),
                    onPressed: () {
                      setState(() {
                        searchQuery = '';
                        searchController.clear();
                      });
                    },
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14.0),
                ),
                onChanged: (value) {
                  setState(() {
                    searchQuery = value;
                  });
                },
                onSubmitted: (value) {
                  _saveSearchQueryAndCheckRefresh();
                  FocusScope.of(context).unfocus();
                },
              )
            : null,
        actions: [
          IconButton(
            icon: Icon(
              isSearching ? Icons.close : Icons.search,
              color: Colors.black,
              size: 28,
            ),
            onPressed: () {
              final previousSearchState = isSearching;
              setState(() {
                isSearching = !isSearching;
                if (!isSearching && previousSearchState) {
                  _saveSearchQueryAndCheckRefresh();
                  searchQuery = '';
                  searchController.clear();
                }
              });
            },
          ),
        ],
        centerTitle: false,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isSearching)
            const Padding(
              padding: EdgeInsets.only(left: 16.0, top: 0, bottom: 8),
              child: Text(
                'My Shop',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.filter_list),
                  onPressed: () {/* TODO: Filter logic */},
                  tooltip: 'Filter by category',
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Filters: $selectedCategory',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.sort),
                  onPressed: () {
                    _showSortOptions(context);
                  },
                  tooltip: 'Sort options',
                ),
                const SizedBox(width: 4),
                Text(
                  _getSortOptionText(selectedSortOption),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: BlocBuilder<HomeCubit, HomeState>(
              builder: (context, state) {
                if (state is HomeLoading) {
                  return const Center(child: CircularProgressIndicator.adaptive());
                } else if (state is HomeSuccess) {
                  final filteredProducts = ProductFilterService.filterAndSortProducts(
                    products: state.allProducts,
                    searchQuery: searchQuery,
                    selectedCategory: selectedCategory,
                    selectedSortOption: selectedSortOption,
                  );

                  if (filteredProducts.isEmpty) {
                    return Center(
                      child: Text(
                        searchQuery.isNotEmpty || selectedCategory != 'All'
                            ? 'No products match your criteria.'
                            : 'No products available in this shop yet.',
                        style: TextStyle(color: Colors.grey[600]),
                        textAlign: TextAlign.center,
                      ),
                    );
                  }

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0),
                    child: GridView.builder(
                      padding: const EdgeInsets.only(top: 8, bottom: 16),
                      itemCount: filteredProducts.length,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 0.63,
                      ),
                      itemBuilder: (context, index) {
                        final product = filteredProducts[index];
                        return ListItemHome(
                          product: product,
                          isNew: true,
                        );
                      },
                    ),
                  );
                } else if (state is HomeFailed) {
                  final errorMessage = state.toString();
                  return Center(child: Text('Error loading products: $errorMessage'));
                } else {
                  return const Center(child: Text("Loading shop data..."));
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

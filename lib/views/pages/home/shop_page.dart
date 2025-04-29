import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_ecommerce/controllers/auth/auth_cubit.dart';
import 'package:flutter_ecommerce/controllers/home/home_cubit.dart';
import 'package:flutter_ecommerce/models/filter_criteria.dart';
import 'package:flutter_ecommerce/models/product.dart';
import 'package:flutter_ecommerce/services/search_history_service.dart';
import 'package:flutter_ecommerce/views/widgets/home/filter_modal.dart';
import 'package:flutter_ecommerce/views/widgets/home/list_item_home.dart';

enum SortOption { popular, newest, customerReview, priceLowToHigh, priceHighToLow }

class ShopPage extends StatefulWidget {
  const ShopPage({Key? key}) : super(key: key);

  @override
  State<ShopPage> createState() => _ShopPageState();
}

class _ShopPageState extends State<ShopPage> {
  bool isSearching = false;
  final TextEditingController searchController = TextEditingController();
  final SearchHistoryService _searchHistoryService = SearchHistoryService();

  final List<String> _availableCategories = [
    'All', 'clothing', 'shoes', 'Jewelry'
  ];
  final List<String> _availableBrands = [
    'Adidas', 'Nike', 'Gucci', 'Zara', 'H&M', 'Levis', 'Prada', 'Cartier'
  ];

  int _searchActionCount = 0;
  static const int _searchRefreshThreshold = 10;

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  void _saveSearchQueryAndCheckRefresh(String query) {
    final trimmedQuery = query.trim();
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
    final homeCubit = context.read<HomeCubit>();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: SortOption.values.map((option) {
              return ListTile(
                title: Text(_getSortOptionText(option)),
                onTap: () {
                  homeCubit.setSortOption(option);
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
      case SortOption.popular: return 'Popular';
      case SortOption.newest: return 'Newest';
      case SortOption.customerReview: return 'Customer review';
      case SortOption.priceLowToHigh: return 'Price: lowest to high';
      case SortOption.priceHighToLow: return 'Price: highest to low';
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeCubit, HomeState>(
      builder: (context, currentHomeState) {
        FilterCriteria currentFilters = FilterCriteria.initial();
        SortOption currentSort = SortOption.popular;
        List<Product> productsToShow = [];
        String currentSearchQuery = '';

        if (currentHomeState is HomeSuccess) {
          currentFilters = currentHomeState.appliedFilters;
          currentSort = currentHomeState.currentSortOption;
          productsToShow = currentHomeState.filteredShopProducts;
          currentSearchQuery = currentHomeState.currentSearchQuery;
        }

        String currentCategory = currentFilters.selectedCategory;
        List<String> currentBrands = currentFilters.selectedBrands;

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
                      hintText: 'Search...',
                      prefixIcon: const Icon(Icons.search, color: Colors.grey),
                      suffixIcon: searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, color: Colors.grey),
                              onPressed: () {
                                context.read<HomeCubit>().setSearchQuery('');
                                searchController.clear();
                              },
                            )
                          : null,

                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 14.0),
                    ),
                    onChanged: (value) {
                      context.read<HomeCubit>().setSearchQuery(value);
                    },
                    onSubmitted: (value) {
                      _saveSearchQueryAndCheckRefresh(value);
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
                      _saveSearchQueryAndCheckRefresh(searchController.text);
                      context.read<HomeCubit>().setSearchQuery('');
                      searchController.clear();
                    } else if (isSearching) {
                      searchController.text = currentSearchQuery;
                      searchController.selection = TextSelection.fromPosition(
                          TextPosition(offset: searchController.text.length));
                    }
                  });
                },
              ),
            ],
            centerTitle: false,
          ),
          body: Builder(
            builder: (context) {
              if (currentHomeState is HomeLoading || currentHomeState is HomeInitial) {
                return const Center(child: CircularProgressIndicator.adaptive());
              } else if (currentHomeState is HomeFailed) {
                return Center(child: Text('Error: ${currentHomeState.error}'));
              } else if (currentHomeState is HomeSuccess) {
                if (productsToShow.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32.0),
                      child: Text(
                        currentSearchQuery.isNotEmpty || currentFilters.isAnyFilterApplied
                            ? 'No products found matching your criteria. Try adjusting filters or search.'
                            : 'No products available in the shop right now.',
                        style: TextStyle(color: Colors.grey[600], fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }

                return CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (!isSearching)
                            const Padding(
                              padding: EdgeInsets.only(left: 16.0, top: 0, bottom: 8),
                              child: Text('My Shop', style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold)),
                            ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 8.0),
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: _availableBrands.map((brand) {
                                  final isSelected = currentBrands.contains(brand);
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 8.0),
                                    child: FilterChip(
                                      label: Text(brand),
                                      selected: isSelected,
                                      onSelected: (_) {
                                        context.read<HomeCubit>().toggleBrandFilter(brand);
                                      },
                                      backgroundColor: Colors.black,
                                      selectedColor: Colors.black,
                                      labelStyle: TextStyle(
                                        color: Colors.white ,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      checkmarkColor: Colors.white,
                                      showCheckmark: true,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(40.0), // bo tròn hơn
                                        side: BorderSide(
                                          color: isSelected ? Colors.white : Colors.white,
                                          width: 1,
                                        ),
                                      ),
                                      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0), // padding rộng hơn
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ),

                          Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.grey[400]!),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  InkWell(
                                    onTap: () {
                                      showModalBottomSheet(
                                        context: context,
                                        isScrollControlled: true,
                                        shape: const RoundedRectangleBorder(
                                          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                                        ),
                                        builder: (_) => FilterModal(
                                          initialCriteria: currentFilters,
                                          onApply: (appliedCriteria) {
                                            context.read<HomeCubit>().applyFilterCriteria(appliedCriteria);
                                          },
                                        ),
                                      );
                                    },
                                    child: Row(
                                      children: const [
                                        Icon(Icons.filter_list, size: 18, color: Colors.black),
                                        SizedBox(width: 4),
                                        Text('Filters', style: TextStyle(fontSize: 14, color: Colors.black)),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 90),
                                  InkWell(
                                    onTap: () => _showSortOptions(context),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.swap_vert, size: 18, color: Colors.black),
                                        const SizedBox(width: 4),
                                        Text(_getSortOptionText(currentSort),
                                            style: const TextStyle(fontSize: 14, color: Colors.black)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: SizedBox(height: 12),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      sliver: SliverGrid(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final product = productsToShow[index];
                            return ListItemHome(product: product, isNew: index < 4);
                          },
                          childCount: productsToShow.length,
                        ),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 0.63,
                        ),
                      ),
                    ),
                  ],
                );
              } else {
                return const SizedBox.shrink();
              }
            },
          ),
        );
      },
    );
  }
}

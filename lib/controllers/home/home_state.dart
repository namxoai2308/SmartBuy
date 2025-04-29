part of 'home_cubit.dart';

@immutable
sealed class HomeState extends Equatable {
  const HomeState();

  @override
  List<Object?> get props => [];
}

final class HomeInitial extends HomeState {}

final class HomeLoading extends HomeState {}

final class HomeSuccess extends HomeState {
  final List<Product> salesProducts;
  final List<Product> newProducts;
  final List<Product> allProducts;
  final List<Product> recommendedProducts;
  final List<Product> filteredShopProducts;
  final FilterCriteria appliedFilters;
  final SortOption currentSortOption;
  final String currentSearchQuery;

  const HomeSuccess({
    required this.salesProducts,
    required this.newProducts,
    required this.allProducts,
    required this.recommendedProducts,
    required this.filteredShopProducts,
    required this.appliedFilters,
    required this.currentSortOption,
    required this.currentSearchQuery,
  });

  @override
  List<Object?> get props => [
        salesProducts,
        newProducts,
        allProducts,
        recommendedProducts,
        filteredShopProducts,
        appliedFilters,
        currentSortOption,
        currentSearchQuery,
      ];

  HomeSuccess copyWith({
    List<Product>? salesProducts,
    List<Product>? newProducts,
    List<Product>? allProducts,
    List<Product>? recommendedProducts,
    List<Product>? filteredShopProducts,
    FilterCriteria? appliedFilters,
    SortOption? currentSortOption,
    String? currentSearchQuery,
  }) {
    return HomeSuccess(
      salesProducts: salesProducts ?? this.salesProducts,
      newProducts: newProducts ?? this.newProducts,
      allProducts: allProducts ?? this.allProducts,
      recommendedProducts: recommendedProducts ?? this.recommendedProducts,
      filteredShopProducts: filteredShopProducts ?? this.filteredShopProducts,
      appliedFilters: appliedFilters ?? this.appliedFilters,
      currentSortOption: currentSortOption ?? this.currentSortOption,
      currentSearchQuery: currentSearchQuery ?? this.currentSearchQuery,
    );
  }
}

final class HomeFailed extends HomeState {
  final String error;

  const HomeFailed(this.error);

  @override
  List<Object> get props => [error];
}
import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_ecommerce/controllers/auth/auth_cubit.dart';
import 'package:flutter_ecommerce/models/product.dart';
import 'package:flutter_ecommerce/models/filter_criteria.dart';
import 'package:flutter_ecommerce/services/home_services.dart';
import 'package:flutter_ecommerce/services/recommendation_service.dart';
import 'package:flutter_ecommerce/views/pages/home/shop_page.dart';

part 'home_state.dart';

class HomeCubit extends Cubit<HomeState> {
  final HomeServicesImpl homeServices = HomeServicesImpl();
  final RecommendationServices recommendationServices = RecommendationServices();
  final AuthCubit authCubit;
  StreamSubscription? _authSubscription;

  FilterCriteria _currentFilters = FilterCriteria.initial();
  String _currentSearchQuery = '';
  SortOption _currentSortOption = SortOption.popular;

  HomeCubit({required this.authCubit}) : super(HomeInitial()) {
    _listenToAuthChanges();
  }

  void _listenToAuthChanges() {
    _authSubscription?.cancel();
    _authSubscription = authCubit.stream.listen((authState) {
      if (authState is AuthSuccess) {
        getHomeContent(userId: authState.user.uid);
      } else if (authState is AuthInitial || authState is AuthFailed) {
        getHomeContent(userId: null);
      }
    });

    final initialAuthState = authCubit.state;
    if (initialAuthState is AuthSuccess) {
      getHomeContent(userId: initialAuthState.user.uid);
    } else {
      getHomeContent(userId: null);
    }
  }

  @override
  void emit(HomeState state) {
    if (isClosed) return;
    super.emit(state);
  }

  Future<void> getHomeContent({String? userId}) async {
    if (state is! HomeLoading) {
      emit(HomeLoading());
    }
    try {
      final results = await Future.wait([
        homeServices.getNewProducts(),
        homeServices.getSalesProducts(),
        homeServices.getAllProducts(),
        recommendationServices.getRecommendations(userId),
      ]);

      final newProducts = results[0] as List<Product>;
      final salesProducts = results[1] as List<Product>;
      final allProducts = results[2] as List<Product>;
      final recommendedProducts = results[3] as List<Product>;

      final filteredList = _internalFilterAndSort(
        originalList: allProducts,
        filters: _currentFilters,
        searchQuery: _currentSearchQuery,
        sortOption: _currentSortOption,
      );

      emit(HomeSuccess(
        salesProducts: salesProducts,
        newProducts: newProducts,
        allProducts: allProducts,
        recommendedProducts: recommendedProducts,
        filteredShopProducts: filteredList,
        appliedFilters: _currentFilters,
        currentSortOption: _currentSortOption,
        currentSearchQuery: _currentSearchQuery,
      ));
    } catch (e) {
      emit(HomeFailed(e.toString()));
    }
  }

  void applyFilterCriteria(FilterCriteria criteria) {
    _currentFilters = criteria;
    _reEmitSuccessStateWithUpdatedFilters();
  }

  void setSearchQuery(String query) {
    _currentSearchQuery = query.trim();
    _reEmitSuccessStateWithUpdatedFilters();
  }

  void setSortOption(SortOption option) {
    _currentSortOption = option;
    _reEmitSuccessStateWithUpdatedFilters();
  }

  void setCategoryFilter(String category) {
    _currentFilters = _currentFilters.copyWith(selectedCategory: category);
    _reEmitSuccessStateWithUpdatedFilters();
  }

  void toggleBrandFilter(String brand) {
    final currentBrands = List<String>.from(_currentFilters.selectedBrands);
    if (currentBrands.contains(brand)) {
      currentBrands.remove(brand);
    } else {
      currentBrands.add(brand);
    }
    _currentFilters = _currentFilters.copyWith(selectedBrands: currentBrands);
    _reEmitSuccessStateWithUpdatedFilters();
  }

  void _reEmitSuccessStateWithUpdatedFilters() {
    if (state is HomeSuccess) {
      final currentState = state as HomeSuccess;
      final updatedFilteredList = _internalFilterAndSort(
        originalList: currentState.allProducts,
        filters: _currentFilters,
        searchQuery: _currentSearchQuery,
        sortOption: _currentSortOption,
      );

      emit(currentState.copyWith(
        filteredShopProducts: updatedFilteredList,
        appliedFilters: _currentFilters,
        currentSortOption: _currentSortOption,
        currentSearchQuery: _currentSearchQuery,
      ));
    }
  }

  List<Product> _internalFilterAndSort({
    required List<Product> originalList,
    required FilterCriteria filters,
    required String searchQuery,
    required SortOption sortOption,
  }) {
    List<Product> workingList = List.from(originalList);

    if (searchQuery.isNotEmpty) {
      workingList = workingList.where((p) =>
          p.title.toLowerCase().contains(searchQuery.toLowerCase()) ||
          (p.brand?.toLowerCase().contains(searchQuery.toLowerCase()) ?? false) ||
          p.category.toLowerCase().contains(searchQuery.toLowerCase())
      ).toList();
    }

    if (filters.selectedCategory != 'All') {
      workingList = workingList.where((p) =>
          p.category.toLowerCase() == filters.selectedCategory.toLowerCase()
      ).toList();
    }

    workingList = workingList.where((p) =>
        p.price >= filters.priceRange.start && p.price <= filters.priceRange.end
    ).toList();

    if (filters.selectedBrands.isNotEmpty) {
      workingList = workingList.where((p) =>
          p.brand != null && filters.selectedBrands.contains(p.brand)
      ).toList();
    }

    workingList.sort((a, b) {
      switch (sortOption) {
        case SortOption.popular: return 0;
        case SortOption.newest: return 0;
        case SortOption.customerReview: return b.averageRating.compareTo(a.averageRating);
        case SortOption.priceLowToHigh: return a.price.compareTo(b.price);
        case SortOption.priceHighToLow: return b.price.compareTo(a.price);
        default: return 0;
      }
    });

    return workingList;
  }

  Future<void> refreshRecommendations({String? userId}) async {
    if (state is HomeSuccess) {
      final currentState = state as HomeSuccess;
      try {
        final currentUserId = userId ?? (authCubit.state is AuthSuccess ? (authCubit.state as AuthSuccess).user.uid : null);
        final newRecommendedProducts = await recommendationServices.getRecommendations(currentUserId);
        emit(currentState.copyWith(
          recommendedProducts: newRecommendedProducts,
        ));
      } catch (e) {
        print('Error refreshing recommendations: $e');
      }
    }
  }

  Future<void> refreshProducts() async {
    final currentUserId = (authCubit.state is AuthSuccess ? (authCubit.state as AuthSuccess).user.uid : null);
    await getHomeContent(userId: currentUserId);
  }

  @override
  Future<void> close() {
    _authSubscription?.cancel();
    return super.close();
  }
}

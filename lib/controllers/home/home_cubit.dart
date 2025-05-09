import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_ecommerce/controllers/auth/auth_cubit.dart';
import 'package:flutter_ecommerce/models/home/product.dart';
import 'package:flutter_ecommerce/models/home/filter_criteria.dart';
import 'package:flutter_ecommerce/models/user_model.dart';
import 'package:flutter_ecommerce/services/home_services.dart';
import 'package:flutter_ecommerce/services/recommendation_service.dart';
import 'package:flutter_ecommerce/views/pages/home/shop_page.dart';

part 'home_state.dart'; // Đảm bảo state của bạn được định nghĩa ở đây

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

  // Helper để lấy UserModel hiện tại một cách an toàn
  // Sửa lại: Truy cập state.user thay vì state.userModel
  UserModel? get _currentUser {
    final authState = authCubit.state;
    return authState is AuthSuccess ? authState.user : null;
  }

  void _listenToAuthChanges() {
    _authSubscription?.cancel();
    _authSubscription = authCubit.stream.listen((authState) {
      getHomeContent();
    });
    getHomeContent();
  }

  @override
  void emit(HomeState state) {
    if (isClosed) return;
    super.emit(state);
  }

  Future<void> getHomeContent() async {
    if (state is! HomeLoading) {
      emit(HomeLoading());
    }
    try {
      // Sử dụng getter _currentUser đã sửa
      final currentUser = _currentUser;
      final bool isBuyer = currentUser?.role.toLowerCase() == 'buyer';
      final String? currentUserId = currentUser?.uid;

      final bool shouldFetchRecommendations = isBuyer && currentUserId != null;

      final List<Future> futures = [
        homeServices.getNewProducts(),
        homeServices.getSalesProducts(),
        homeServices.getAllProducts(),
        shouldFetchRecommendations
            ? recommendationServices.getRecommendations(currentUserId!)
            : Future.value(<Product>[]),
      ];

      final results = await Future.wait(futures);

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

  // --- Các hàm filter, sort giữ nguyên ---
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
  // ----------------------------------------

  Future<void> refreshRecommendations({required String userId}) async {
    // Sử dụng getter _currentUser đã sửa
    final currentUser = _currentUser;
    final bool isBuyer = currentUser?.role.toLowerCase() == 'buyer';

     if (!isBuyer || currentUser?.uid != userId) {
       print("Skipping refreshRecommendations: User is not a buyer or ID mismatch.");
       return;
     }

    if (state is HomeSuccess) {
      final currentState = state as HomeSuccess;
      try {
        final newRecommendedProducts = await recommendationServices.getRecommendations(userId);
        emit(currentState.copyWith(
          recommendedProducts: newRecommendedProducts,
        ));
      } catch (e) {
        print('Error refreshing recommendations for user $userId: $e');
      }
    } else {
        print("Skipping refreshRecommendations: Home state is not Success.");
    }
  }

  Future<void> refreshProducts() async {
    await getHomeContent();
  }

  @override
  Future<void> close() {
    _authSubscription?.cancel();
    return super.close();
  }
}
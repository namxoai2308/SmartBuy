part of 'home_cubit.dart';

@immutable
sealed class HomeState {}

final class HomeInitial extends HomeState {}

final class HomeLoading extends HomeState {}

final class HomeSuccess extends HomeState {
  final List<Product> salesProducts;
  final List<Product> newProducts;
  final List<Product> allProducts;
  final List<Product> recommendedProducts;

  HomeSuccess({required this.salesProducts,
  required this.newProducts,
  required this.allProducts,
  required this.recommendedProducts});
}

final class HomeFailed extends HomeState {
  final String error;

  HomeFailed(this.error);
}

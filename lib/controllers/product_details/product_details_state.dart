part of 'product_details_cubit.dart';

@immutable
abstract class ProductDetailsState {}

class ProductDetailsInitial extends ProductDetailsState {}

class ProductDetailsLoading extends ProductDetailsState {}

class ProductDetailsError extends ProductDetailsState {
  final String error;
  ProductDetailsError(this.error);
}

class ProductDetailsLoaded extends ProductDetailsState {
  final Product product;
  final List<Product> allProducts;

  ProductDetailsLoaded({required this.product, required this.allProducts, });
}

class AddingToCart extends ProductDetailsState {}

class AddedToCart extends ProductDetailsState {}

class AddToCartError extends ProductDetailsState {
  final String error;
  AddToCartError(this.error);
}

class SizeSelected extends ProductDetailsState {
  final String size;
  SizeSelected(this.size);
}

class ColorSelected extends ProductDetailsState {
  final String color;
  ColorSelected(this.color);
}

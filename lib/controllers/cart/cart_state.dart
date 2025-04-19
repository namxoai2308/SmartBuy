
part of 'cart_cubit.dart';

@immutable
sealed class CartState extends Equatable {
  @override
  List<Object?> get props => [];
}

final class CartInitial extends CartState {}

final class CartLoading extends CartState {}

final class CartLoaded extends CartState {
  final List<AddToCartModel> cartProducts;
  final double totalAmount;

  CartLoaded(this.cartProducts, this.totalAmount);

  @override
  List<Object?> get props => [cartProducts, totalAmount];
}

final class CartError extends CartState {
  final String message;

  CartError(this.message);

  @override
  List<Object?> get props => [message];
}

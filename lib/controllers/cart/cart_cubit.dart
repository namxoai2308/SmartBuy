import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_ecommerce/models/add_to_cart_model.dart';
import 'package:flutter_ecommerce/services/auth_services.dart';
import 'package:flutter_ecommerce/services/cart_services.dart';
import 'package:meta/meta.dart';
import 'package:flutter/foundation.dart';
import 'package:equatable/equatable.dart';

part 'cart_state.dart';

class CartCubit extends Cubit<CartState> {
  CartCubit() : super(CartInitial());

  final authServices = AuthServicesImpl();
  final cartServices = CartServicesImpl();

  Future<void> getCartItems() async {
    if (state is! CartLoaded) {
      emit(CartLoading());
    }
    try {
      final currentUser = authServices.currentUser;
      if (currentUser == null) {
        emit(CartLoaded([], 0.0));
        return;
      }
      final cartProducts = await cartServices.getCartProducts(currentUser.uid);
      final totalAmount = cartProducts.fold<double>(
        0,
        (prev, item) => prev + item.price * item.quantity,
      );
      emit(CartLoaded(List.from(cartProducts), totalAmount));
    } catch (e) {
      emit(CartError(e.toString()));
    }
  }

  Future<void> removeFromCart(AddToCartModel cartItem) async {
    final currentState = state;
    if (currentState is CartLoaded && authServices.currentUser != null) {
      try {
        final List<AddToCartModel> currentItems = List.from(currentState.cartProducts);
        currentItems.removeWhere((item) => item.id == cartItem.id);
        final newTotal = currentItems.fold<double>(0, (prev, item) => prev + item.price * item.quantity);
        emit(CartLoaded(currentItems, newTotal));
        await cartServices.removeFromCart(authServices.currentUser!.uid, cartItem.id);
      } catch (e) {
        emit(CartError('Failed to remove item: $e'));
        if (currentState is CartLoaded) emit(currentState);
      }
    }
  }

  Future<void> increaseQuantity(AddToCartModel cartItem) async {
    final currentState = state;
    if (currentState is CartLoaded && authServices.currentUser != null) {
      final List<AddToCartModel> updatedItems = List.from(currentState.cartProducts);
      final itemIndex = updatedItems.indexWhere((item) => item.id == cartItem.id);

      if (itemIndex != -1) {
        final originalItem = updatedItems[itemIndex];
        final updatedItem = originalItem.copyWith(quantity: originalItem.quantity + 1);
        updatedItems[itemIndex] = updatedItem;
        final newTotalAmount = updatedItems.fold<double>(
          0,
          (prev, item) => prev + item.price * item.quantity,
        );
        emit(CartLoaded(updatedItems, newTotalAmount));

        try {
          await cartServices.updateCartItem(authServices.currentUser!.uid, updatedItem);
        } catch (e) {
          emit(CartLoaded(currentState.cartProducts, currentState.totalAmount));
          emit(CartError('Failed to update item quantity. Please try again.'));
        }
      }
    }
  }

  Future<void> clearCart() async {
      final currentState = state;
      try {
        final currentUser = authServices.currentUser;
        if (currentUser != null) {
          await cartServices.clearCart(currentUser.uid);
          emit(CartLoaded([], 0.0));
        } else {
           emit(CartLoaded([], 0.0));
        }
      } catch (e) {
        print('Error clearing cart in Cubit: $e');
        if (currentState is CartLoaded) emit(currentState);
        emit(CartError('Failed to clear cart. $e'));
      }
    }

  Future<void> decreaseQuantity(AddToCartModel cartItem) async {
    final currentState = state;
    if (currentState is CartLoaded && authServices.currentUser != null) {
      final List<AddToCartModel> updatedItems = List.from(currentState.cartProducts);
      final itemIndex = updatedItems.indexWhere((item) => item.id == cartItem.id);

      if (itemIndex != -1) {
        final originalItem = updatedItems[itemIndex];

        if (originalItem.quantity > 1) {
          final updatedItem = originalItem.copyWith(quantity: originalItem.quantity - 1);
          updatedItems[itemIndex] = updatedItem;
          final newTotalAmount = updatedItems.fold<double>(
            0,
            (prev, item) => prev + item.price * item.quantity,
          );
          emit(CartLoaded(updatedItems, newTotalAmount));

          try {
            await cartServices.updateCartItem(authServices.currentUser!.uid, updatedItem);
          } catch (e) {
            emit(CartLoaded(currentState.cartProducts, currentState.totalAmount));
            emit(CartError('Failed to update item quantity. Please try again.'));
          }
        } else {
          updatedItems.removeAt(itemIndex);
          final newTotalAmount = updatedItems.fold<double>(
            0,
            (prev, item) => prev + item.price * item.quantity,
          );
          emit(CartLoaded(updatedItems, newTotalAmount));

          try {
            await cartServices.removeFromCart(authServices.currentUser!.uid, cartItem.id);
          } catch (e) {
            emit(CartLoaded(currentState.cartProducts, currentState.totalAmount));
            emit(CartError('Failed to remove item. Please try again.'));
          }
        }
      }
    }
  }
}

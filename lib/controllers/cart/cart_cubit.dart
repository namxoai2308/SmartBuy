import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_ecommerce/models/add_to_cart_model.dart';
import 'package:flutter_ecommerce/services/auth_services.dart';
import 'package:flutter_ecommerce/services/cart_services.dart';
import 'package:meta/meta.dart';

part 'cart_state.dart';

class CartCubit extends Cubit<CartState> {
  CartCubit() : super(CartInitial());

  final authServices = AuthServicesImpl();
  final cartServices = CartServicesImpl();

  Future<void> getCartItems() async {
    emit(CartLoading());
    try {
      final currentUser = authServices.currentUser;
      final cartProducts = await cartServices.getCartProducts(currentUser!.uid);
      final totalAmount = cartProducts.fold<double>(
        0,
        (prev, item) => prev + item.price * item.quantity,
      );
      emit(CartLoaded(cartProducts, totalAmount));
    } catch (e) {
      emit(CartError(e.toString()));
    }
  }

  Future<void> addToCart(AddToCartModel newItem) async {
    try {
      final currentUser = authServices.currentUser;
      final cartItems = await cartServices.getCartProducts(currentUser!.uid);

      final existingIndex = cartItems.indexWhere((item) =>
        item.productId == newItem.productId && item.size == newItem.size);

      if (existingIndex != -1) {
        // Sản phẩm đã có, cập nhật số lượng
        final existingItem = cartItems[existingIndex];
        final updatedItem = existingItem.copyWith(
          quantity: existingItem.quantity + 1,
        );

        await cartServices.updateCartItem(currentUser.uid, updatedItem);
      } else {
        // Thêm sản phẩm mới với quantity = 1
        await cartServices.addProductToCart(currentUser.uid, newItem);

      }

      await getCartItems();
    } catch (e) {
      emit(CartError('Failed to add item: $e'));
    }
  }


  Future<void> removeFromCart(AddToCartModel cartItem) async {
    try {
      final currentUser = authServices.currentUser;
      await cartServices.removeFromCart(currentUser!.uid, cartItem.id);
      await getCartItems();
    } catch (e) {
      emit(CartError('Failed to remove item: $e'));
    }
  }
}

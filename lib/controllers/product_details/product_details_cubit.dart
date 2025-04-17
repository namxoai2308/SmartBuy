import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_ecommerce/models/add_to_cart_model.dart';
import 'package:flutter_ecommerce/models/product.dart';
import 'package:flutter_ecommerce/services/auth_services.dart';
import 'package:flutter_ecommerce/services/cart_services.dart';
import 'package:flutter_ecommerce/services/product_details_services.dart';
import 'package:flutter_ecommerce/utilities/constants.dart';
import 'package:meta/meta.dart';

part 'product_details_state.dart';

class ProductDetailsCubit extends Cubit<ProductDetailsState> {
  ProductDetailsCubit() : super(ProductDetailsInitial());

  final productDetailsServices = ProductDetailsServicesImpl();
  final cartServices = CartServicesImpl();
  final authServices = AuthServicesImpl();

  String? size;

  Future<void> getProductDetails(String productId) async {
    emit(ProductDetailsLoading());
    try {
      final product = await productDetailsServices.getProductDetails(productId);
      emit(ProductDetailsLoaded(product));
    } catch (e) {
      emit(ProductDetailsError(e.toString()));
    }
  }
     /// Tạo ID sản phẩm trong giỏ hàng dựa trên productId, size và color
      String generateCartItemId({
        required String productId,
        required String size,
        required String color,
      }) {
        return '${productId}_$size';
      }
  Future<void> addToCart(Product product) async {
    emit(AddingToCart());
    try {
      final currentUser = authServices.currentUser;
      if (currentUser == null) {
        emit(AddToCartError('User not logged in.'));
        return;
      }

      if (size == null) {
        emit(AddToCartError('Please select a size'));
        return;
      }

      final discountedUnitPrice =
          product.price * (1 - (product.discountValue?.toDouble() ?? 0.0) / 100);

      final cartItemId = generateCartItemId(
        productId: product.id,
        size: size!,
        color: 'Black',
      );

      // lấy tất cả sản phẩm trong giỏ để kiểm tra
      final cartItems = await cartServices.getCartProducts(currentUser.uid);

      final existingItem = cartItems.firstWhere(
        (item) => item.id == cartItemId,
        orElse: () => null,
      );

      if (existingItem != null) {
        final updatedQuantity = existingItem.quantity + 1;
        final updatedItem = existingItem.copyWith(
          quantity: updatedQuantity,
          price: discountedUnitPrice * updatedQuantity,
        );
        await cartServices.updateCartItem(currentUser.uid, updatedItem);
      } else {
        final newItem = AddToCartModel(
          id: cartItemId,
          title: product.title,
          price: discountedUnitPrice,
          productId: product.id,
          imgUrl: product.imgUrl,
          size: size!,
          quantity: 1,
          color: 'Black',
          discountValue: product.discountValue ?? 0,
        );
        await cartServices.addProductToCart(currentUser.uid, newItem);
      }

      emit(AddedToCart());
    } catch (e) {
      emit(AddToCartError(e.toString()));
    }
  }

  void setSize(String newSize) {
    size = newSize;
    emit(SizeSelected(newSize));
  }
}

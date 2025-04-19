import 'package:flutter_ecommerce/models/add_to_cart_model.dart';
import 'package:flutter_ecommerce/services/firestore_services.dart';
import 'package:flutter_ecommerce/utilities/api_path.dart';
import 'package:flutter/foundation.dart';

abstract class CartServices {
  Future<void> addProductToCart(String userId, AddToCartModel cartProduct);
  Future<List<AddToCartModel>> getCartProducts(String userId);
  Future<void> removeFromCart(String userId, String cartItemId);
  Future<void> updateCartItem(String userId, AddToCartModel updatedItem);
  Future<void> clearCart(String userId);
}

class CartServicesImpl implements CartServices {
  final firestoreServices = FirestoreServices.instance;

  @override
  Future<void> addProductToCart(String userId, AddToCartModel cartProduct) async {
    try {
      final existingItems = await getCartProducts(userId);
      final matchedItem = existingItems.firstWhere(
        (item) =>
            item.productId == cartProduct.productId &&
            item.color == cartProduct.color &&
            item.size == cartProduct.size,
        orElse: () => AddToCartModel.empty(),
      );

      if (!matchedItem.isEmpty) {
        final updatedItem = matchedItem.copyWith(
          quantity: matchedItem.quantity + cartProduct.quantity,
        );
        await updateCartItem(userId, updatedItem);
      } else {
        await firestoreServices.setData(
          path: ApiPath.addToCart(userId, cartProduct.id),
          data: cartProduct.toMap(),
        );
      }
    } catch (e) {
      debugPrint('Error adding/updating product in cart: $e');
      throw Exception('Failed to add product to cart.');
    }
  }

  @override
  Future<List<AddToCartModel>> getCartProducts(String userId) async {
    try {
      return await firestoreServices.getCollection(
        path: ApiPath.myProductsCart(userId),
        builder: (data, documentId) => AddToCartModel.fromMap(data, documentId),
      );
    } catch (e) {
      debugPrint('Error getting cart products: $e');
      return [];
    }
  }

  @override
  Future<void> removeFromCart(String userId, String cartItemId) async {
    try {
      await firestoreServices.deleteData(
        path: ApiPath.addToCart(userId, cartItemId),
      );
    } catch (e) {
      debugPrint('Error removing item from cart: $e');
      throw Exception('Failed to remove item from cart.');
    }
  }

  @override
  Future<void> updateCartItem(String userId, AddToCartModel updatedItem) async {
    try {
      await firestoreServices.setData(
        path: ApiPath.addToCart(userId, updatedItem.id),
        data: updatedItem.toMap(),
      );
    } catch (e) {
      debugPrint('Error updating cart item: $e');
      throw Exception('Failed to update cart item.');
    }
  }

  @override
  Future<void> clearCart(String userId) async {
    try {
      final List<AddToCartModel> cartItems = await getCartProducts(userId);

      if (cartItems.isEmpty) {
        return;
      }

      await Future.wait(cartItems.map((item) async {
        try {
          await firestoreServices.deleteData(
            path: ApiPath.addToCart(userId, item.id),
          );
        } catch (e) {
          print('Failed to delete item ${item.id}: $e');
        }
      }));
    } catch (e) {
      print('Error in clearCart process: $e');
      throw Exception('Failed to clear cart.');
    }
  }
}

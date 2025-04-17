import 'package:flutter_ecommerce/models/add_to_cart_model.dart';
import 'package:flutter_ecommerce/services/firestore_services.dart';
import 'package:flutter_ecommerce/utilities/api_path.dart';

abstract class CartServices {
  Future<void> addProductToCart(String userId, AddToCartModel cartProduct);
  Future<List<AddToCartModel>> getCartProducts(String userId);
  Future<void> removeFromCart(String userId, String productId);
  Future<void> updateCartItem(String userId, AddToCartModel updatedItem);
}

class CartServicesImpl implements CartServices {
  final firestoreServices = FirestoreServices.instance;

  @override
  Future<void> addProductToCart(String userId, AddToCartModel cartProduct) async {
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
  }

  @override
  Future<List<AddToCartModel>> getCartProducts(String userId) async =>
      await firestoreServices.getCollection(
        path: ApiPath.myProductsCart(userId),
        builder: (data, documentId) => AddToCartModel.fromMap(data, documentId),
      );

  @override
  Future<void> removeFromCart(String userId, String productId) async =>
      await firestoreServices.deleteData(
        path: ApiPath.addToCart(userId, productId),
      );

  @override
    Future<void> updateCartItem(String userId, AddToCartModel updatedItem) async =>
        await firestoreServices.setData(
          path: ApiPath.addToCart(userId, updatedItem.id),
          data: updatedItem.toMap(),
        );

}

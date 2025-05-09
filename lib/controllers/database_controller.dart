import 'package:flutter_ecommerce/models/add_to_cart_model.dart';
import 'package:flutter_ecommerce/models/checkout/delivery_method.dart';
import 'package:flutter_ecommerce/models/home/product.dart';
import 'package:flutter_ecommerce/models/checkout/shipping_address.dart';
import 'package:flutter_ecommerce/models/user_model.dart';
import 'package:flutter_ecommerce/services/firestore_services.dart';
import 'package:flutter_ecommerce/utilities/api_path.dart';

abstract class Database {
  Stream<List<Product>> salesProductsStream();
  Stream<List<Product>> newProductsStream();
  Stream<List<AddToCartModel>> myProductsCart();
  Stream<List<DeliveryMethod>> deliveryMethodsStream();
  Stream<List<ShippingAddress>> getShippingAddresses();

  Future<void> setUserData(UserModel user);
  Future<void> addToCart(AddToCartModel product);
  Future<void> saveAddress(ShippingAddress address);
}

class FirestoreDatabase implements Database {
  final String uid;
  final _service = FirestoreServices.instance;

  FirestoreDatabase(this.uid);

  @override
  Stream<List<Product>> salesProductsStream() => _service.collectionsStream(
        path: ApiPath.products(),
        builder: (data, documentId) => Product.fromMap(data!, documentId),
        queryBuilder: (query) => query.where('discountValue', isNotEqualTo: 0),
      );

  @override
  Stream<List<Product>> newProductsStream() => _service.collectionsStream(
        path: ApiPath.products(),
        builder: (data, documentId) => Product.fromMap(data!, documentId),
      );

  @override
  Future<void> setUserData(UserModel user) async => await _service.setData(
        path: ApiPath.user(user.uid),
        data: user.toFirestore(),
      );

  @override
  Future<void> addToCart(AddToCartModel product) async => _service.setData(
        path: ApiPath.addToCart(uid, product.id),
        data: product.toMap(),
      );

  @override
  Stream<List<AddToCartModel>> myProductsCart() => _service.collectionsStream(
        path: ApiPath.myProductsCart(uid),
        builder: (data, documentId) =>
            AddToCartModel.fromMap(data!, documentId),
      );

  @override
  Stream<List<DeliveryMethod>> deliveryMethodsStream() =>
      _service.collectionsStream(
          path: ApiPath.deliveryMethods(),
          builder: (data, documentId) =>
              DeliveryMethod.fromMap(data!, documentId));

  @override
  Stream<List<ShippingAddress>> getShippingAddresses() =>
      _service.collectionsStream(
        path: ApiPath.userShippingAddress(uid),
        builder: (data, documentId) =>
            ShippingAddress.fromMap(data!, documentId),
      );

  @override
  Future<void> saveAddress(ShippingAddress address) => _service.setData(
        path: ApiPath.newAddress(
          uid,
          address.id,
        ),
        data: address.toMap(),
      );
}

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_ecommerce/models/add_to_cart_model.dart';
import 'package:flutter_ecommerce/models/home/product.dart';
import 'package:flutter_ecommerce/models/home/review.dart';
import 'package:flutter_ecommerce/services/auth_services.dart';
import 'package:flutter_ecommerce/services/cart_services.dart';
import 'package:flutter_ecommerce/services/product_details_services.dart';
import 'package:flutter_ecommerce/services/home_services.dart';
import 'package:meta/meta.dart';

part 'product_details_state.dart';

class ProductDetailsCubit extends Cubit<ProductDetailsState> {
  ProductDetailsCubit() : super(ProductDetailsInitial());

  final productDetailsServices = ProductDetailsServicesImpl();
  final cartServices = CartServicesImpl();
  final authServices = AuthServicesImpl();
  final homeServices = HomeServicesImpl();

  String? size;
  String? color;

  List<Product> allProducts = [];

Future<void> getProductDetails(String productId) async {
  emit(ProductDetailsLoading());
  try {
    final product = await productDetailsServices.getProductDetails(productId);
    final allProducts = await homeServices.getAllProducts();

    emit(ProductDetailsLoaded(product: product, allProducts: allProducts));
  } catch (e) {
    emit(ProductDetailsError(e.toString()));
  }
}

Future<void> loadAllProducts() async {
  try {
    final products = await homeServices.getAllProducts();
    allProducts = products;
    if (allProducts.isNotEmpty) {
      final product = allProducts.first;
      emit(ProductDetailsLoaded(product: product, allProducts: allProducts));
    }
  } catch (e) {
    print('Error loading all products: $e');
  }
}

  String generateCartItemId({
    required String productId,
    required String size,
    required String color,
  }) {
    return '${productId}_${size}_$color';
  }

  Future<void> addToCart(Product product) async {
    emit(AddingToCart());
    try {
      final currentUser = authServices.currentUser;
      if (size == null || color == null) {
        emit(AddToCartError('Please select size and color'));
        return;
      }

      final discountedPrice = product.price * (1 - (product.discountValue?.toDouble() ?? 0.0) / 100);

      final addToCartProduct = AddToCartModel(
        id: generateCartItemId(
          productId: product.id,
          size: size!,
          color: color!,
        ),
        title: product.title,
        price: discountedPrice,
        productId: product.id,
        imgUrl: product.imgUrl,
        size: size!,
        color: color!,
        brand: product.brand!,
        category: product.category!,
      );

      await cartServices.addProductToCart(currentUser!.uid, addToCartProduct);
      emit(AddedToCart());
    } catch (e) {
      emit(AddToCartError(e.toString()));
    }
  }

void setSize(String newSize) {
  size = newSize;
  if (state is ProductDetailsLoaded) {
    final currentState = state as ProductDetailsLoaded;
    emit(ProductDetailsLoaded(
      product: currentState.product,
      allProducts: currentState.allProducts,
      selectedSize: newSize,
      selectedColor: currentState.selectedColor,
    ));
  }
}

void setColor(String newColor) {
  color = newColor;
  if (state is ProductDetailsLoaded) {
    final currentState = state as ProductDetailsLoaded;
    emit(ProductDetailsLoaded(
      product: currentState.product,
      allProducts: currentState.allProducts,
      selectedSize: currentState.selectedSize,
      selectedColor: newColor,
    ));
  }
}

}

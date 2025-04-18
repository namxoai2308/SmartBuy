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
      if (size == null) {
        emit(AddToCartError('Please select a size'));
      }
      final discountedPrice = product.price * (1 - (product.discountValue?.toDouble() ?? 0.0) / 100);

      final addToCartProduct = AddToCartModel(
        id: generateCartItemId(
                productId: product.id,
                size: size!,
                color: 'Black', // tạm fix ở đây
              ),
        title: product.title,
        price: discountedPrice,
        productId: product.id,
        imgUrl: product.imgUrl,
        size: size!,
      );
      await cartServices.addProductToCart(currentUser!.uid, addToCartProduct);
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

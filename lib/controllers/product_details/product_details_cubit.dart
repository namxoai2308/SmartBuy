import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_ecommerce/models/add_to_cart_model.dart';
import 'package:flutter_ecommerce/models/product.dart';
import 'package:flutter_ecommerce/models/review.dart';
import 'package:flutter_ecommerce/services/auth_services.dart';
import 'package:flutter_ecommerce/services/cart_services.dart';
import 'package:flutter_ecommerce/services/product_details_services.dart';
import 'package:flutter_ecommerce/services/home_services.dart'; // Thêm service này
import 'package:meta/meta.dart';

part 'product_details_state.dart';

class ProductDetailsCubit extends Cubit<ProductDetailsState> {
  ProductDetailsCubit() : super(ProductDetailsInitial());

  final productDetailsServices = ProductDetailsServicesImpl();
  final cartServices = CartServicesImpl();
  final authServices = AuthServicesImpl();
  final homeServices = HomeServicesImpl(); // Khai báo homeServices để lấy allProducts

  String? size;
  String? color;

  List<Product> allProducts = []; // Lưu tất cả sản phẩm

Future<void> getProductDetails(String productId) async {
  emit(ProductDetailsLoading());
  try {
    // Lấy thông tin chi tiết của sản phẩm
    final product = await productDetailsServices.getProductDetails(productId);

    // Lấy tất cả các sản phẩm từ dịch vụ homeServices
    final allProducts = await homeServices.getAllProducts();

    // Emit trạng thái đã tải sản phẩm chi tiết và danh sách tất cả các sản phẩm
    emit(ProductDetailsLoaded(product: product, allProducts: allProducts));
  } catch (e) {
    emit(ProductDetailsError(e.toString()));
  }
}



// Hàm load allProducts từ HomeServices
Future<void> loadAllProducts() async {
  try {
    final products = await homeServices.getAllProducts(); // Gọi service để lấy tất cả sản phẩm
    allProducts = products;

    // Kiểm tra nếu có sản phẩm để truyền vào ProductDetailsLoaded
    if (allProducts.isNotEmpty) {
      final product = allProducts.first; // Lấy sản phẩm đầu tiên làm ví dụ (hoặc có thể thay bằng sản phẩm khác)
      emit(ProductDetailsLoaded(product: product, allProducts: allProducts)); // Truyền cả product và allProducts vào
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
    emit(SizeSelected(newSize));
  }

  void setColor(String newColor) {
    color = newColor;
    emit(ColorSelected(newColor));
  }
}

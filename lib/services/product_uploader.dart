// lib/utils/product_uploader.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_ecommerce/models/home/product.dart'; // Đường dẫn đến model Product của bạn
import 'package:flutter_ecommerce/services/home_services.dart'; // Đường dẫn đến HomeServicesImpl

// ID Admin Seller của bạn
const String ADMIN_SELLER_ID_FOR_UPLOAD = "M7CFrKwP9WUy8j5BdFq3F8zM9rl2";

class ProductUploader {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final HomeServicesImpl _homeServices = HomeServicesImpl();

  Future<void> uploadAllProductsForAdmin() async {
    final String adminSellerId = ADMIN_SELLER_ID_FOR_UPLOAD;

    if (adminSellerId.isEmpty) {
      print("❌ Admin Seller ID is not defined. Aborting upload.");
      throw Exception("Admin Seller ID is missing.");
    }

    try {
      print("🚀 Starting product upload for Admin Seller ID: $adminSellerId (Using IDs from JSON)");

      final List<Product> localProducts = await _homeServices.getAllProducts();

      if (localProducts.isEmpty) {
        print("ℹ️ No products found in local JSON. Nothing to upload.");
        return;
      }
      print("✅ Found ${localProducts.length} products in JSON. Preparing to upload to Firestore...");

      final CollectionReference productsCollection = _firestore.collection('products');
      WriteBatch batch = _firestore.batch();
      int operationsInBatch = 0;
      int totalProductsUploaded = 0;

      for (var localProduct in localProducts) {
        // Kiểm tra xem localProduct.id có hợp lệ không (không rỗng)
        if (localProduct.id.isEmpty) {
          print("⚠️ Skipping product with empty ID from JSON: ${localProduct.title}");
          continue; // Bỏ qua sản phẩm này
        }

        Map<String, dynamic> productDataForFirestore = localProduct.toMap();

        productDataForFirestore['sellerId'] = adminSellerId;
        productDataForFirestore['createdAt'] = FieldValue.serverTimestamp();
        productDataForFirestore['updatedAt'] = FieldValue.serverTimestamp();

        // --- SỬ DỤNG ID TỪ JSON ---
        // Lấy tham chiếu document bằng ID từ localProduct
        DocumentReference docRef = productsCollection.doc(localProduct.id);

        // Vì ID document đã là localProduct.id, chúng ta có thể xóa trường 'id'
        // khỏi dữ liệu map để tránh lưu trữ thừa.
        // Điều này tùy thuộc vào việc bạn có muốn giữ trường 'id' bên trong document hay không.
        // Nếu `Product.fromMap` của bạn đọc ID từ `snapshot.id`, thì việc có trường `id`
        // bên trong document là không cần thiết. // Xóa trường 'id' khỏi map data

        batch.set(docRef, productDataForFirestore);
        // Nếu bạn muốn MERGE thay vì SET (ghi đè hoàn toàn), dùng:
        // batch.set(docRef, productDataForFirestore, SetOptions(merge: true));
        // Merge hữu ích nếu bạn muốn cập nhật mà không xóa các trường không có trong productDataForFirestore
        // nhưng đối với lần upload đầu, set thường phù hợp hơn.

        operationsInBatch++;
        totalProductsUploaded++;

        if (operationsInBatch >= 100) {
          print("⏳ Committing batch of $operationsInBatch products...");
          await batch.commit();
          batch = _firestore.batch();
          operationsInBatch = 0;
          print("☑️ Batch committed. Continuing upload...");
        }
      }

      if (operationsInBatch > 0) {
        print("⏳ Committing final batch of $operationsInBatch products...");
        await batch.commit();
      }

      print("🎉 Successfully uploaded/updated $totalProductsUploaded products to Firestore for Admin Seller ID: $adminSellerId!");

    } catch (e) {
      print("❌ Error uploading products to Firestore: $e");
      throw Exception("Upload failed: ${e.toString()}");
    }
  }
}
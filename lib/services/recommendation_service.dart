import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:collection/collection.dart';
import 'package:flutter_ecommerce/models/product.dart';
import 'package:flutter_ecommerce/services/home_services.dart';
import 'package:flutter_ecommerce/services/search_history_service.dart';
import 'dart:math';

class RecommendationServices {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final HomeServicesImpl _homeServices = HomeServicesImpl();
  final Random _random = Random();
  final SearchHistoryService _searchHistoryService = SearchHistoryService();

  // --- Constants ---
  static const int _targetRecommendationCount = 30; // Số lượng sản phẩm mục tiêu
  static const int _guestSearchPriorityCount = 10; // Số lượng ưu tiên từ search cho guest
  // -----------------

  Future<List<Product>> getRecommendations(String? userId) async {
    print("[RecommendationService] Lấy gợi ý cho userId: ${userId ?? 'Khách'}");
    final List<String> searchHistory = await _searchHistoryService.getSearchHistory();
    print("[RecommendationService] Lịch sử tìm kiếm được đọc (${searchHistory.length}): $searchHistory");

    if (userId == null) {
      return await _getCombinedGuestRecommendations(searchHistory);
    }

    try {
      final ordersSnapshot = await _firestore
          .collection('orders')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      if (ordersSnapshot.docs.isEmpty) {
        print("[RecommendationService] User chưa có đơn hàng. Dùng gợi ý kết hợp.");
        return await _getCombinedGuestRecommendations(searchHistory);
      } else {
        return await _getPersonalizedRecommendations(userId, ordersSnapshot, searchHistory);
      }
    } catch (e) {
      print("[RecommendationService] Lỗi khi lấy đơn hàng hoặc xử lý gợi ý cho user $userId: $e");
      return await _getCombinedGuestRecommendations(searchHistory);
    }
  }

  // --- Lấy gợi ý dựa trên Discount và Rating ---
  List<Product> _getDiscountAndRatingRecommendations(
      List<Product> allProducts, Set<String> excludeIds) {
    print("[RecommendationService][_getDiscountAndRatingRecommendations] Bắt đầu lọc ${allProducts.length} sản phẩm (loại trừ ${excludeIds.length} IDs).");
    final availableProducts = allProducts.where((p) => !excludeIds.contains(p.id)).toList();

    availableProducts.sort((a, b) {
      // Ưu tiên discount cao hơn (giả sử discountValue là tỉ lệ giảm, ví dụ 0.2 = 20%)
      final discountA = a.discountValue ?? 0.0;
      final discountB = b.discountValue ?? 0.0;
      int discountCompare = discountB.compareTo(discountA); // Cao hơn đứng trước
      if (discountCompare != 0) {
        return discountCompare;
      }

      // Nếu discount bằng nhau, ưu tiên rating cao hơn
      final ratingA = a.rate ?? 0.0;
      final ratingB = b.rate ?? 0.0;
      return ratingB.compareTo(ratingA); // Cao hơn đứng trước
    });

    print("[RecommendationService][_getDiscountAndRatingRecommendations] Đã sắp xếp ${availableProducts.length} sản phẩm theo discount/rating.");
    return availableProducts;
  }

  // --- Hàm phụ: Tìm sản phẩm theo từ khóa ---
  List<Product> _findProductsByKeywords(List<Product> allProducts, List<String> keywords, Set<String> excludeIds) {
     if (keywords.isEmpty) return [];
     print("[RecommendationService][_findProductsByKeywords] Tìm kiếm với keywords: $keywords (loại trừ ${excludeIds.length} IDs)");

     List<Product> foundProducts = [];
     // Dùng Set để tránh thêm cùng 1 sản phẩm nhiều lần nếu khớp nhiều keyword
     Set<String> foundIds = Set.from(excludeIds);

     for (final keyword in keywords) {
        if (keyword.trim().isEmpty) continue; // Bỏ qua keyword rỗng
        final lowerKeyword = keyword.toLowerCase();
        final matchingProducts = allProducts.where((product) {
           if (foundIds.contains(product.id)) return false;

           // Tìm trong title và có thể cả category/brand
           final titleMatch = (product.title ?? '').toLowerCase().contains(lowerKeyword);
           final categoryMatch = (product.category ?? '').toLowerCase().contains(lowerKeyword);
           // final brandMatch = (product.brand ?? '').toLowerCase().contains(lowerKeyword);

           return titleMatch || categoryMatch; // Mở rộng tìm kiếm
        });

        for(final p in matchingProducts) {
           if (!foundIds.contains(p.id)) {
              foundProducts.add(p);
              foundIds.add(p.id);
           }
        }
     }
     print("[RecommendationService][_findProductsByKeywords] Tìm thấy ${foundProducts.length} sản phẩm khớp.");
     return foundProducts;
  }

  // --- Gợi ý cho khách HOẶC khi không đủ dữ liệu mua hàng (ĐÃ SỬA ĐỔI) ---
  Future<List<Product>> _getCombinedGuestRecommendations(List<String> searchHistory) async {
    print("[RecommendationService] Lấy gợi ý kết hợp cho khách/dữ liệu thưa.");
    try {
      final allProducts = await _homeServices.getAllProducts();
      if (allProducts.isEmpty) return [];

      final List<Product> finalRecommendations = [];
      final Set<String> recommendedIds = {};

      if (searchHistory.isEmpty) {
        // --- Trường hợp 1: Không có lịch sử tìm kiếm ---
        print("[RecommendationService] Không có lịch sử tìm kiếm. Lấy theo discount/rating.");
        final discountRatingRecs = _getDiscountAndRatingRecommendations(allProducts, {});
        finalRecommendations.addAll(discountRatingRecs.take(_targetRecommendationCount));
      } else {
        // --- Trường hợp 2: Có lịch sử tìm kiếm ---
        print("[RecommendationService] Có lịch sử tìm kiếm. Ưu tiên ${searchHistory.length} keywords.");

        // Lấy gợi ý từ tìm kiếm
        final searchBasedRecs = _findProductsByKeywords(allProducts, searchHistory, {});

        // Lấy gợi ý từ discount/rating (loại trừ những cái đã có trong search)
        final initialExcludeIds = searchBasedRecs.map((p) => p.id).toSet();
        final discountRatingRecs = _getDiscountAndRatingRecommendations(allProducts, initialExcludeIds);

        // Ưu tiên 10 sản phẩm đầu từ tìm kiếm
        int searchAddedCount = 0;
        for (final product in searchBasedRecs) {
          if (finalRecommendations.length < _guestSearchPriorityCount) {
            finalRecommendations.add(product);
            recommendedIds.add(product.id);
            searchAddedCount++;
          } else {
            break;
          }
        }
         print("[RecommendationService] Đã thêm $searchAddedCount sản phẩm ưu tiên từ tìm kiếm.");

        // Lấy phần còn lại của 2 danh sách
        final remainingSearchRecs = searchBasedRecs.where((p) => !recommendedIds.contains(p.id)).toList();
        // discountRatingRecs đã loại trừ ban đầu, không cần lọc lại

        print("[RecommendationService] Còn lại ${remainingSearchRecs.length} từ tìm kiếm và ${discountRatingRecs.length} từ discount/rating.");

        // Xen kẽ để lấp đầy đến 30
        int searchIdx = 0;
        int ratingIdx = 0;
        while (finalRecommendations.length < _targetRecommendationCount) {
          bool addedSomething = false;
          // Ưu tiên thêm từ search trước nếu còn
          if (searchIdx < remainingSearchRecs.length) {
            final product = remainingSearchRecs[searchIdx++];
            if (!recommendedIds.contains(product.id)) { // Kiểm tra lại phòng trường hợp trùng lặp lạ
              finalRecommendations.add(product);
              recommendedIds.add(product.id);
              addedSomething = true;
              if (finalRecommendations.length >= _targetRecommendationCount) break;
            }
          }
          // Sau đó thêm từ discount/rating nếu còn chỗ và còn sản phẩm
          if (ratingIdx < discountRatingRecs.length) {
             final product = discountRatingRecs[ratingIdx++];
             // Không cần kiểm tra recommendedIds nữa vì đã lọc ban đầu
             finalRecommendations.add(product);
             recommendedIds.add(product.id); // Vẫn thêm vào set để đảm bảo
             addedSomething = true;
             if (finalRecommendations.length >= _targetRecommendationCount) break;
          }

          // Nếu cả hai danh sách đều hết mà chưa đủ 30 -> dừng lại
          if (!addedSomething) {
            print("[RecommendationService] Hết nguồn sản phẩm để xen kẽ.");
            break;
          }
        }
      }

      // Shuffle kết quả cuối cùng để tăng tính ngẫu nhiên
      finalRecommendations.shuffle(_random);

      // Đảm bảo không vượt quá số lượng target
      final finalResult = finalRecommendations.take(_targetRecommendationCount).toList();
      print("[RecommendationService] Gợi ý cuối cùng (khách/thưa): ${finalResult.length}");
      return finalResult;

    } catch (e, stackTrace) {
      print("[RecommendationService] Lỗi khi lấy gợi ý kết hợp: $e");
      print(stackTrace);
      return [];
    }
  }

  // --- Gợi ý cá nhân hóa (KHI CÓ LỊCH SỬ MUA HÀNG - ĐÃ SỬA ĐỔI) ---
  Future<List<Product>> _getPersonalizedRecommendations(
      String userId, QuerySnapshot ordersSnapshot, List<String> searchHistory) async {
    print("[RecommendationService] Lấy gợi ý cá nhân hóa cho user $userId.");
    try {
      final allProducts = await _homeServices.getAllProducts();
      if (allProducts.isEmpty) return await _getCombinedGuestRecommendations(searchHistory);

      // --- Trích xuất dữ liệu mua hàng ---
      List<Map<String, dynamic>> purchasedItems = [];
      // ... (code lấy purchasedItems như cũ) ...
       for (var doc in ordersSnapshot.docs) { /* ... */
         final itemsData = doc.data() as Map<String, dynamic>?;
         if (itemsData != null && itemsData.containsKey('items') && itemsData['items'] is List) {
           try { final items = List<Map<String, dynamic>>.from(itemsData['items']); purchasedItems.addAll(items); } catch(e) { print(e); }
         }
       }
       if (purchasedItems.isEmpty) return await _getCombinedGuestRecommendations(searchHistory);
      // -----------------------------------

      int totalQuantity = purchasedItems.fold<int>(0, (sum, item) => sum + ((item['quantity'] as num?)?.toInt() ?? 0));
      print("[RecommendationService] User $userId đã mua tổng số lượng: $totalQuantity");
      Set<String> purchasedProductIds = purchasedItems.map((item) => item['productId'] as String?).whereNotNull().toSet();
      print("[RecommendationService] ID sản phẩm đã mua: $purchasedProductIds");

      List<Product> finalRecommendations = [];
      Set<String> recommendedIds = Set.from(purchasedProductIds); // Bắt đầu loại trừ sp đã mua

      // --- Bước 1: Gợi ý dựa trên LỊCH SỬ MUA HÀNG ---
      List<Product> purchaseBasedRecs = [];
      if (totalQuantity < 5) {
        print("[RecommendationService] Lọc theo LS Mua hàng (Brand OR Category)");
        Set<String> brands = purchasedItems.map((item) => item['brand'] as String?).whereNotNull().where((s) => s.isNotEmpty).toSet();
        Set<String> categories = purchasedItems.map((item) => item['category'] as String?).whereNotNull().where((s) => s.isNotEmpty).toSet();
        purchaseBasedRecs = allProducts.where((p) => !recommendedIds.contains(p.id) &&
            ((p.brand != null && p.brand!.isNotEmpty && brands.contains(p.brand!)) ||
             (p.category != null && p.category!.isNotEmpty && categories.contains(p.category!)))).toList();
      } else {
        print("[RecommendationService] Lọc theo LS Mua hàng (Brand AND Category)");
        Set<String> purchasedBrands = purchasedItems.map((item) => item['brand'] as String?).whereNotNull().where((s) => s.isNotEmpty).toSet();
        Set<String> purchasedCategories = purchasedItems.map((item) => item['category'] as String?).whereNotNull().where((s) => s.isNotEmpty).toSet();
        purchaseBasedRecs = allProducts.where((p) => !recommendedIds.contains(p.id) &&
            (p.brand != null && p.brand!.isNotEmpty && purchasedBrands.contains(p.brand!)) &&
            (p.category != null && p.category!.isNotEmpty && purchasedCategories.contains(p.category!))).toList();
      }
      // Thêm kết quả từ mua hàng vào danh sách cuối cùng (nếu chưa đủ 30)
      for(final product in purchaseBasedRecs) {
         if (finalRecommendations.length < _targetRecommendationCount && !recommendedIds.contains(product.id)) {
            finalRecommendations.add(product);
            recommendedIds.add(product.id);
         } else if (finalRecommendations.length >= _targetRecommendationCount) {
            break;
         }
      }
      print("[RecommendationService] Đã thêm ${finalRecommendations.length} gợi ý từ LS mua hàng.");

      // --- Bước 2: Bổ sung bằng LỊCH SỬ TÌM KIẾM ---
      if (finalRecommendations.length < _targetRecommendationCount && searchHistory.isNotEmpty) {
         print("[RecommendationService] Bổ sung bằng LS Tìm kiếm...");
         final searchBasedRecs = _findProductsByKeywords(allProducts, searchHistory, recommendedIds); // Loại trừ sp đã có
         int addedCount = 0;
         for(final product in searchBasedRecs) {
            if (finalRecommendations.length < _targetRecommendationCount && !recommendedIds.contains(product.id)) {
               finalRecommendations.add(product);
               recommendedIds.add(product.id);
               addedCount++;
            } else if (finalRecommendations.length >= _targetRecommendationCount) {
               break;
            }
         }
         print("[RecommendationService] Đã bổ sung $addedCount từ LS Tìm kiếm.");
      }

      // --- Bước 3: Bổ sung bằng DISCOUNT/RATING ---
      if (finalRecommendations.length < _targetRecommendationCount) {
         print("[RecommendationService] Bổ sung bằng Discount/Rating...");
         final discountRatingRecs = _getDiscountAndRatingRecommendations(allProducts, recommendedIds); // Loại trừ sp đã có
          int addedCount = 0;
         for(final product in discountRatingRecs) {
            if (finalRecommendations.length < _targetRecommendationCount && !recommendedIds.contains(product.id)) {
               finalRecommendations.add(product);
               recommendedIds.add(product.id);
                addedCount++;
            } else if (finalRecommendations.length >= _targetRecommendationCount) {
               break;
            }
         }
         print("[RecommendationService] Đã bổ sung $addedCount từ Discount/Rating.");
      }

      // --- Hoàn thiện ---
      finalRecommendations.shuffle(_random); // Shuffle kết quả cuối cùng
      final finalResult = finalRecommendations.take(_targetRecommendationCount).toList(); // Đảm bảo đúng 30
      print("[RecommendationService] Gợi ý cuối cùng (cá nhân hóa): ${finalResult.length}");
      return finalResult;

    } catch (e, stackTrace) {
      print("[RecommendationService] Lỗi nghiêm trọng khi tạo gợi ý cá nhân hóa: $e");
      print(stackTrace);
      return await _getCombinedGuestRecommendations(searchHistory); // Fallback an toàn
    }
  }
}
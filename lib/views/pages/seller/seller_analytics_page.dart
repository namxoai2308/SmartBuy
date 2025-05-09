import 'package:flutter/material.dart';
import 'package:flutter_ecommerce/models/home/product.dart'; // Import Product model
import 'package:flutter_ecommerce/services/home_services.dart'; // Import HomeServicesImpl
import 'package:fl_chart/fl_chart.dart'; // Import thư viện biểu đồ
import 'dart:math'; // Để tạo màu ngẫu nhiên cho biểu đồ

class SellerAnalyticsPage extends StatefulWidget {
  const SellerAnalyticsPage({Key? key}) : super(key: key);

  @override
  State<SellerAnalyticsPage> createState() => _SellerAnalyticsPageState();
}

class _SellerAnalyticsPageState extends State<SellerAnalyticsPage> {
  late Future<List<Product>> _productsFuture;
  final HomeServicesImpl _homeServices = HomeServicesImpl();

  // Dữ liệu đã được xử lý cho biểu đồ
  Map<String, int> _productsByCategory = {};
  Map<String, int> _productsByBrand = {};
  // Thêm các map khác cho các phân tích khác nếu cần

  @override
  void initState() {
    super.initState();
    _productsFuture = _loadAndProcessAnalytics();
  }

  Future<List<Product>> _loadAndProcessAnalytics() async {
    final products = await _homeServices.getAllProducts();
    if (products.isNotEmpty) {
      _processProductData(products);
    }
    return products;
  }

  void _processProductData(List<Product> products) {
    // 1. Phân tích theo danh mục
    final categoryCounts = <String, int>{};
    for (var product in products) {
      categoryCounts.update(product.category, (value) => value + 1, ifAbsent: () => 1);
    }
    // Sắp xếp để biểu đồ đẹp hơn (tùy chọn)
    final sortedByCategory = Map.fromEntries(
        categoryCounts.entries.toList()..sort((e1, e2) => e2.value.compareTo(e1.value))
    );
    _productsByCategory = Map.fromEntries(sortedByCategory.entries.take(5)); // Lấy top 5
    if (sortedByCategory.length > 5) {
        _productsByCategory['Other'] = sortedByCategory.entries.skip(5).fold(0, (prev, e) => prev + e.value);
    }


    // 2. Phân tích theo thương hiệu (nếu có)
    final brandCounts = <String, int>{};
    for (var product in products) {
      if (product.brand != null && product.brand!.isNotEmpty) {
        brandCounts.update(product.brand!, (value) => value + 1, ifAbsent: () => 1);
      }
    }
     final sortedByBrand = Map.fromEntries(
        brandCounts.entries.toList()..sort((e1, e2) => e2.value.compareTo(e1.value))
    );
    _productsByBrand = Map.fromEntries(sortedByBrand.entries.take(5)); // Lấy top 5
    if (sortedByBrand.length > 5) {
        _productsByBrand['Other'] = sortedByBrand.entries.skip(5).fold(0, (prev, e) => prev + e.value);
    }


    // Gọi setState nếu cần rebuild UI ngay sau khi xử lý (FutureBuilder đã xử lý việc này)
    // setState(() {}); // Không cần thiết khi dùng FutureBuilder cho lần load đầu
  }

  Color _getRandomColor() {
    return Color((Random().nextDouble() * 0xFFFFFF).toInt()).withOpacity(1.0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Product Analytics'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: FutureBuilder<List<Product>>(
        future: _productsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator.adaptive());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error loading analytics: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No product data available for analytics.'));
          } else {
            // Dữ liệu đã được xử lý và lưu trong _productsByCategory, _productsByBrand
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildSectionTitle('Products by Category'),
                  _buildPieChart(_productsByCategory, 'Category'),
                  const SizedBox(height: 30),

                  if (_productsByBrand.isNotEmpty) ...[
                     _buildSectionTitle('Products by Brand'),
                    _buildPieChart(_productsByBrand, 'Brand'),
                    const SizedBox(height: 30),
                  ],

                  // Thêm các biểu đồ/phân tích khác ở đây
                  // Ví dụ: Biểu đồ cột phân bổ giá, danh sách top sản phẩm,...
                ],
              ),
            );
          }
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Text(
        title,
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildPieChart(Map<String, int> data, String titlePrefix) {
    if (data.isEmpty) {
      return Center(child: Text('No data available for $titlePrefix chart.'));
    }

    List<PieChartSectionData> sections = [];
    data.forEach((key, value) {
      sections.add(
        PieChartSectionData(
          color: _getRandomColor(),
          value: value.toDouble(),
          title: '$key\n($value)', // Hiển thị tên và số lượng
          radius: 100, // Kích thước của phần
          titleStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            shadows: [Shadow(color: Colors.black, blurRadius: 2)],
          ),
          titlePositionPercentageOffset: 0.55, // Vị trí của text
        ),
      );
    });

    return AspectRatio(
      aspectRatio: 1.5, // Tỷ lệ của biểu đồ
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: PieChart(
            PieChartData(
              sections: sections,
              centerSpaceRadius: 40, // Không gian ở giữa
              sectionsSpace: 2, // Khoảng cách giữa các phần
              pieTouchData: PieTouchData( // Cho phép tương tác chạm (optional)
                touchCallback: (FlTouchEvent event, pieTouchResponse) {
                  // Xử lý sự kiện chạm nếu cần
                },
              ),
              borderData: FlBorderData(show: false), // Bỏ đường viền của biểu đồ
            ),
          ),
        ),
      ),
    );
  }
}
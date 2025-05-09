// lib/views/pages/seller/seller_home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_ecommerce/controllers/auth/auth_cubit.dart';
import 'package:flutter_ecommerce/services/product_uploader.dart'; // Import file uploader
// Import các trang chức năng của Seller
import 'package:flutter_ecommerce/views/pages/seller/manage_local_products_page.dart'; // Trang xem sản phẩm local JSON
// import 'package:flutter_ecommerce/views/pages/seller/manage_firebase_products_page.dart'; // Trang quản lý sản phẩm trên Firebase (TODO)
import 'package:flutter_ecommerce/views/pages/seller/seller_analytics_page.dart';
import 'package:flutter_ecommerce/views/pages/chat/conversation_list_page.dart'; // Trang danh sách chat chung
import 'package:flutter_ecommerce/views/pages/seller/admin_view_all_orders_page.dart';


class SellerHomeScreen extends StatelessWidget {
  const SellerHomeScreen({Key? key}) : super(key: key);

  // Widget helper để tạo các nút dashboard cho nhất quán
  Widget _buildDashboardButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    Color iconColor = Colors.teal, // Màu icon mặc định
    bool isDestructive = false, // Cho nút upload
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: ElevatedButton.icon(
        icon: Icon(icon, color: isDestructive ? Colors.white : iconColor, size: 22),
        label: Text(
          label,
          style: TextStyle(
            fontSize: 16,
            color: isDestructive ? Colors.white : Colors.black87,
            fontWeight: FontWeight.w500
          ),
        ),
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: isDestructive ? Colors.redAccent : Colors.white,
          foregroundColor: isDestructive ? Colors.white : Colors.black,
          elevation: 2,
          minimumSize: const Size(double.infinity, 60),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
            side: BorderSide(color: isDestructive ? Colors.redAccent.shade700 : Colors.grey[300]!)
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          alignment: Alignment.centerLeft,
        ),
      ),
    );
  }

  // Hàm xử lý upload với dialog (từ phản hồi trước)
  Future<void> _handleProductUpload(BuildContext context) async {
    // Dialog xác nhận
    bool? confirmUpload = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Confirm Product Upload'),
          content: const Text('This will upload all products from your local JSON to Firebase. This action is typically run only once. Are you sure?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(dialogContext).pop(false),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).primaryColor),
              child: const Text('UPLOAD NOW', style: TextStyle(color: Colors.white)),
              onPressed: () => Navigator.of(dialogContext).pop(true),
            ),
          ],
        );
      },
    );

    if (confirmUpload == true) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext loadingDialogContext) {
          return const AlertDialog(
            content: Row(
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 20),
                Text("Uploading products..."),
              ],
            ),
          );
        },
      );

      try {
        final uploader = ProductUploader();
        await uploader.uploadAllProductsForAdmin(); // Hàm này dùng ADMIN_SELLER_ID_FOR_UPLOAD bên trong

        if (Navigator.of(context).canPop()) Navigator.of(context).pop(); // Đóng dialog loading

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All products uploaded successfully! 🎉'), backgroundColor: Colors.green),
        );
      } catch (e) {
        if (Navigator.of(context).canPop()) Navigator.of(context).pop(); // Đóng dialog loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: ${e.toString()} 💔'), backgroundColor: Colors.red),
        );
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthCubit>().state;
    // Lấy tên Admin từ AuthState, nếu không có thì dùng tên mặc định
    final adminName = (authState is AuthSuccess && authState.user.role.toLowerCase() == 'admin')
                      ? authState.user.name
                      : "Admin"; // Hoặc "Seller" tùy theo role của tài khoản M7C...

    return Scaffold(
      appBar: AppBar(
        title: Text('$adminName '),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1.0, // Thêm chút bóng đổ cho AppBar
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_outlined), // Icon logout rõ ràng hơn
            tooltip: 'Logout',
            onPressed: () {
              context.read<AuthCubit>().logout();
              // AuthWrapper sẽ xử lý điều hướng về trang login
            },
          ),
        ],
      ),
      backgroundColor: Colors.grey[100], // Một màu nền nhẹ nhàng
      body: SingleChildScrollView( // Cho phép cuộn nếu nội dung dài
        padding: const EdgeInsets.all(20.0), // Padding xung quanh
        child: Column(
           mainAxisAlignment: MainAxisAlignment.start, // Căn chỉnh các phần tử từ trên xuống
           crossAxisAlignment: CrossAxisAlignment.stretch, // Các nút sẽ chiếm toàn bộ chiều rộng
           children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 24.0, top: 8.0),
                child: Text(
                  'Welcome, $adminName!',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                  textAlign: TextAlign.center,
                ),
              ),
              _buildDashboardButton(
                 context: context,
                 icon: Icons.inventory_2_outlined, // Icon cho quản lý sản phẩm
                 label: 'Manage Firebase Products ',
                 onPressed: () {
                   Navigator.of(context).push(
                     MaterialPageRoute(builder: (_) => const ManageLocalProductsPage()),
                   );
                 },
              ),
                _buildDashboardButton(
                   context: context,
                   icon: Icons.receipt_long_outlined, // Icon cho quản lý sản phẩm
                   label: 'View All Orders ',
                   onPressed: () {
Navigator.of(context).push(
                     MaterialPageRoute(builder: (_) => const AdminViewAllOrdersPage()),
                   );
                   },
                ),
              // TODO: Sau khi có chức năng quản lý sản phẩm trên Firebase,
              // bạn có thể thêm một nút khác hoặc thay thế nút trên:
              // _buildDashboardButton(
              //    context: context,
              //    icon: Icons.settings_outlined,
              //    label: 'Manage Firebase Products',
              //    onPressed: () {
              //      Navigator.of(context).push(
              //        MaterialPageRoute(builder: (_) => const ManageFirebaseProductsPage()), // Trang này cần tạo
              //      );
              //    },
              // ),
              _buildDashboardButton(
                 context: context,
                 icon: Icons.analytics_outlined, // Icon cho phân tích
                 label: 'View Product Analytics',
                 onPressed: () {
                   Navigator.of(context).push(
                     MaterialPageRoute(builder: (_) => const SellerAnalyticsPage()),
                   );
                 },
              ),
              _buildDashboardButton(
                context: context,
                icon: Icons.chat_bubble_outline_rounded, // Icon cho tin nhắn
                label: 'View Customer Messages',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ConversationListPage()),
                  );
                },
              ),
              const SizedBox(height: 24), // Khoảng cách trước nút upload
              const Divider(), // Đường kẻ phân cách
              const SizedBox(height: 12),
               Padding(
                 padding: const EdgeInsets.symmetric(vertical: 8.0),
                 child: Text(
                  "One-Time Actions (Use with caution):",
                  style: TextStyle(fontSize: 14, color: Colors.grey[700], fontWeight: FontWeight.w500)
                 ),
               ),
              _buildDashboardButton(
                context: context,
                icon: Icons.cloud_upload_outlined,
                label: 'Upload JSON to Firebase',
                iconColor: Colors.white, // Icon màu trắng cho nút đỏ
                isDestructive: true, // Đánh dấu đây là action có thể nguy hiểm
                onPressed: () {
                  _handleProductUpload(context); // Gọi hàm xử lý upload
                },
              ),
           ],
        ),
      ),
    );
  }
}
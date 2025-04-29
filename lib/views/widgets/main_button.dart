import 'package:flutter/material.dart';

class MainButton extends StatelessWidget {
  final String? text; // Giữ nullable
  final VoidCallback? onTap;
  final bool hasCircularBorder;
  final Widget? child; // Widget tùy chỉnh (ưu tiên hơn text nếu có)
  final bool isLoading;

  const MainButton({ // Thêm const nếu có thể
    super.key,
    this.text,
    this.onTap,
    this.hasCircularBorder = false,
    this.child,
    this.isLoading = false,
  }) : assert(text != null || child != null, 'Provide either text or child'); // Giữ assert

  @override
  Widget build(BuildContext context) {
    // Vô hiệu hóa onTap khi đang loading
    final VoidCallback? effectiveOnTap = isLoading ? null : onTap;
    // Xác định màu nền khi disable
    final Color disabledColor = (Theme.of(context).primaryColor).withOpacity(0.7);

    return SizedBox(
      width: double.infinity,
      height: 50, // Điều chỉnh chiều cao nếu cần
      child: ElevatedButton(
        onPressed: effectiveOnTap, // Sử dụng onTap đã xử lý loading
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).primaryColor,
          foregroundColor: Colors.white, // Màu chữ/icon mặc định
          disabledBackgroundColor: disabledColor, // Màu nền khi bị vô hiệu hóa
          disabledForegroundColor: Colors.white.withOpacity(0.8), // Màu chữ/icon khi bị vô hiệu hóa
          shape: hasCircularBorder
              ? RoundedRectangleBorder( borderRadius: BorderRadius.circular(24.0) )
              : RoundedRectangleBorder( borderRadius: BorderRadius.circular(8.0) ), // Thêm bo góc mặc định
          padding: EdgeInsets.zero, // Bỏ padding mặc định của nút nếu cần để indicator căn giữa chuẩn hơn
        ),
        // --- SỬA LẠI LOGIC CHILD ---
        child: isLoading
            ? const Center( // Dùng Center để căn giữa indicator
                child: SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator.adaptive(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              )
            : child ?? // Nếu không loading, ưu tiên hiển thị widget child nếu được cung cấp
               (text != null // Nếu không có child, kiểm tra text và hiển thị Text
                ? Text(
                    text!, // Sử dụng ! vì assert đã đảm bảo text hoặc child phải có
                    textAlign: TextAlign.center, // Căn giữa text
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  )
                : const SizedBox.shrink() // Trường hợp hiếm hoi cả child và text đều null (dù có assert)
              ),
        // --- DÒNG ": child," THỪA ĐÃ BỊ XÓA ---
      ),
    );
  }
}
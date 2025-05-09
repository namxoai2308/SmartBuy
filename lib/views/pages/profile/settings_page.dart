import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // <-- 1. IMPORT PROVIDER
import 'package:flutter_ecommerce/controllers/theme_notifier.dart'; // <-- 2. IMPORT THEME NOTIFIER
import 'package:flutter_ecommerce/services/search_history_service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool salesNotification = true;
  bool newArrivalsNotification = false;
  bool deliveryStatusNotification = false;

  @override
  Widget build(BuildContext context) {
    // --- 3. LẤY ThemeNotifier TỪ PROVIDER ---
    final themeNotifier = Provider.of<ThemeNotifier>(context);

    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: const Text('Settings', style: TextStyle(fontWeight: FontWeight.bold)),
        // actions: const [Padding(padding: EdgeInsets.only(right: 16), child: Icon(Icons.search))], // Bạn có thể giữ lại nếu muốn
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor ?? Colors.transparent, // Lấy màu từ theme
        elevation: Theme.of(context).appBarTheme.elevation ?? 0,
        foregroundColor: Theme.of(context).appBarTheme.foregroundColor, // Lấy màu icon/text từ theme
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- PHẦN THÔNG TIN CÁ NHÂN (giữ nguyên) ---
            const Text("Personal Information", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            TextField(
              decoration: InputDecoration(
                hintText: "Full name",
                filled: true,
                // fillColor: Colors.white, // Nên lấy màu từ theme
                fillColor: Theme.of(context).inputDecorationTheme.fillColor ?? Theme.of(context).colorScheme.surface,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              readOnly: true,
              decoration: InputDecoration(
                hintText: "Date of Birth",
                filled: true,
                // fillColor: Colors.white,
                fillColor: Theme.of(context).inputDecorationTheme.fillColor ?? Theme.of(context).colorScheme.surface,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                suffixIcon: Icon(Icons.calendar_today_outlined, color: Theme.of(context).iconTheme.color?.withOpacity(0.6)),
                labelText: "12/12/1989", // Bạn có thể muốn lấy dữ liệu thực tế ở đây
                // labelStyle: const TextStyle(color: Colors.black), // Nên lấy màu từ theme
              ),
            ),
            const SizedBox(height: 24),

            // --- PHẦN MẬT KHẨU (giữ nguyên) ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Password", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                InkWell( // Thêm InkWell để có thể nhấn
                  onTap: () {
                     // TODO: Điều hướng đến trang thay đổi mật khẩu
                     print("Change password tapped");
                  },
                  child: Text(
                    "Change",
                    style: TextStyle(color: Theme.of(context).colorScheme.secondary) // Dùng màu phụ từ theme
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              readOnly: true,
              obscureText: true,
              decoration: InputDecoration(
                hintText: "Password",
                filled: true,
                // fillColor: Colors.white,
                 fillColor: Theme.of(context).inputDecorationTheme.fillColor ?? Theme.of(context).colorScheme.surface,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 24),

            // --- PHẦN THÔNG BÁO (giữ nguyên logic, cập nhật màu) ---
            const Text("Notifications", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            SwitchListTile(
              title: const Text("Sales"),
              value: salesNotification,
              onChanged: (value) => setState(() => salesNotification = value),
              activeColor: Theme.of(context).colorScheme.primary, // Dùng màu chính từ theme
              contentPadding: EdgeInsets.zero,
            ),
            SwitchListTile(
              title: const Text("New arrivals"),
              value: newArrivalsNotification,
              onChanged: (value) => setState(() => newArrivalsNotification = value),
              activeColor: Theme.of(context).colorScheme.primary,
              contentPadding: EdgeInsets.zero,
            ),
            SwitchListTile(
              title: const Text("Delivery status changes"),
              value: deliveryStatusNotification,
              onChanged: (value) => setState(() => deliveryStatusNotification = value),
              activeColor: Theme.of(context).colorScheme.primary,
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 24), // Thêm khoảng cách trước mục Theme

            // --- 4. THÊM PHẦN CHỌN THEME ---
            const Text("Appearance", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
             ListTile( // Dùng ListTile để căn chỉnh đẹp hơn
               contentPadding: EdgeInsets.zero,
               title: const Text("Theme"),
               trailing: DropdownButton<ThemeMode>(
                 value: themeNotifier.currentThemeMode,
                 items: const [
                   DropdownMenuItem(
                     value: ThemeMode.system,
                     child: Text('System Default'),
                   ),
                   DropdownMenuItem(
                     value: ThemeMode.light,
                     child: Text('Light'),
                   ),
                   DropdownMenuItem(
                     value: ThemeMode.dark,
                     child: Text('Dark'),
                   ),
                 ],
                 // Bỏ gạch chân của DropdownButton
                 underline: const SizedBox.shrink(),
                 // Gọi hàm setThemeMode khi người dùng chọn
                 onChanged: (ThemeMode? newMode) {
                   if (newMode != null) {
                     themeNotifier.setThemeMode(newMode);
                   }
                 },
               ),
             ),
             // --- KẾT THÚC PHẦN CHỌN THEME ---
const SizedBox(height: 24),
const Text("Others", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
const SizedBox(height: 12),
ListTile(
  contentPadding: EdgeInsets.zero,
  title: const Text("Clear Search History"),
  trailing: const Icon(Icons.delete_outline),
  onTap: () async {
    final searchHistoryService = SearchHistoryService();
    await searchHistoryService.clearSearchHistory();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Search history cleared.")),
      );
    }
  },
),

          ],
        ),
      ),
    );
  }
}
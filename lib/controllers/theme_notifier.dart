// lib/controllers/theme_notifier.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeNotifier extends ChangeNotifier {
  final String key = "theme"; // Key để lưu vào SharedPreferences
  SharedPreferences? _prefs; // Instance SharedPreferences

  ThemeMode _themeMode; // Biến lưu trữ ThemeMode hiện tại

  // Khởi tạo với ThemeMode.system làm mặc định
  ThemeNotifier() : _themeMode = ThemeMode.system {
    _loadFromPrefs(); // Tải lựa chọn đã lưu khi khởi tạo
  }

  // Getter để lấy ThemeMode hiện tại
  ThemeMode get currentThemeMode => _themeMode;

  // Hàm để thay đổi ThemeMode
  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return; // Không làm gì nếu mode không đổi

    _themeMode = mode;
    await _saveToPrefs(mode); // Lưu lựa chọn mới
    notifyListeners(); // Thông báo cho các widget đang lắng nghe để rebuild
  }

  // Khởi tạo SharedPreferences
  Future<void> _initPrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  // Tải lựa chọn từ SharedPreferences
  Future<void> _loadFromPrefs() async {
    await _initPrefs();
    // Đọc giá trị đã lưu (dưới dạng int: 0=system, 1=light, 2=dark)
    int themeIndex = _prefs?.getInt(key) ?? 0; // Mặc định là system (index 0)
    _themeMode = ThemeMode.values[themeIndex];
    notifyListeners(); // Thông báo sau khi tải xong
  }

  // Lưu lựa chọn vào SharedPreferences
  Future<void> _saveToPrefs(ThemeMode mode) async {
    await _initPrefs();
    await _prefs?.setInt(key, mode.index); // Lưu index của ThemeMode
  }
}
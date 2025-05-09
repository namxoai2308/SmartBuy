// lib/controllers/locale_notifier.dart (hoặc một đường dẫn tương tự)
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _kLanguageCode = 'languageCode';
const String _kCountryCode = 'countryCode'; // Tùy chọn, nếu bạn muốn lưu cả country code

class LocaleNotifier extends ChangeNotifier {
  Locale? _appLocale;

  Locale? get appLocale => _appLocale;

  LocaleNotifier() {
    _loadLocale();
  }

  Future<void> _loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    String? languageCode = prefs.getString(_kLanguageCode);
    // String? countryCode = prefs.getString(_kCountryCode); // Tùy chọn

    if (languageCode != null && languageCode.isNotEmpty) {
      // _appLocale = Locale(languageCode, countryCode); // Nếu có countryCode
      _appLocale = Locale(languageCode);
    } else {
      // Nếu không có gì được lưu, _appLocale sẽ là null,
      // MaterialApp sẽ sử dụng ngôn ngữ hệ thống hoặc fallback từ supportedLocales
      _appLocale = null;
    }
    notifyListeners();
    print("LocaleNotifier: Loaded locale: $_appLocale");
  }

  Future<void> changeLocale(Locale newLocale) async {
    if (_appLocale?.languageCode == newLocale.languageCode &&
        _appLocale?.countryCode == newLocale.countryCode) return; // Không thay đổi nếu giống hệt

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLanguageCode, newLocale.languageCode);
    // if (newLocale.countryCode != null && newLocale.countryCode!.isNotEmpty) { // Tùy chọn
    //   await prefs.setString(_kCountryCode, newLocale.countryCode!);
    // } else {
    //   await prefs.remove(_kCountryCode);
    // }

    _appLocale = newLocale;
    notifyListeners();
    print("LocaleNotifier: Locale changed to: ${newLocale.languageCode}");
  }

  // Hàm để xóa cài đặt locale, quay về mặc định hệ thống
  Future<void> clearLocale() async {
    if (_appLocale == null) return; // Không có gì để xóa

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kLanguageCode);
    // await prefs.remove(_kCountryCode); // Tùy chọn

    _appLocale = null;
    notifyListeners();
    print("LocaleNotifier: Locale cleared, using system default.");
  }
}
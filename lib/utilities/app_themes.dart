// lib/utilities/app_themes.dart
import 'package:flutter/material.dart';

class AppThemes {
  static final ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: Colors.red, // Màu chính của bạn cho chế độ sáng
    scaffoldBackgroundColor: Colors.white, // Màu nền chính của bạn
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: Colors.white,
        ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white, // Màu AppBar sáng
      foregroundColor: Colors.black, // Màu chữ và icon trên AppBar sáng
      elevation: 1,
      shadowColor: Colors.grey,
    ),
    colorScheme: ColorScheme.fromSwatch().copyWith(
      primary: Colors.red,
      secondary: Colors.redAccent, // Màu phụ
      brightness: Brightness.light,
      // Bạn có thể định nghĩa thêm các màu khác trong colorScheme
      surface: Colors.grey,
      // background: const Color(0xFFE5E5E5),
      // error: Colors.red,
       onPrimary: Colors.white,
      // onSecondary: Colors.white,
      // onSurface: Colors.black,
      onBackground: Colors.black,
      // onError: Colors.white,
    ),
    // Định nghĩa các theme khác nếu cần (textTheme, buttonTheme, etc.)
    textTheme: const TextTheme(
      // Ví dụ: định nghĩa text style cho chế độ sáng
      titleLarge: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
      bodyMedium: TextStyle(color: Colors.black54),
    ),
    // ... các tùy chỉnh theme khác ...
  );

  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: Colors.redAccent, // Màu chính cho chế độ tối (có thể khác)
    scaffoldBackgroundColor: Colors.grey[900], // Màu nền tối
     bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: const Color(0xFF121212),
        ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.grey[850], // Màu AppBar tối
      foregroundColor: Colors.white,      // Màu chữ và icon trên AppBar tối
      elevation: 1,
      shadowColor: Colors.black.withOpacity(0.5),
    ),
    colorScheme: ColorScheme.fromSwatch().copyWith(
      primary: Colors.redAccent,
      secondary: Colors.red, // Màu phụ
      brightness: Brightness.dark,
      // Định nghĩa màu cho chế độ tối
      surface: Colors.grey[800],
      background: Colors.grey[900],
      error: Colors.redAccent,
      onPrimary: Colors.black, // Chữ trên nền màu chính (có thể là đen hoặc trắng tùy màu chính)
      onSecondary: Colors.black,
      onSurface: Colors.white,
      onBackground: Colors.white,
      onError: Colors.black,
    ),
    // Định nghĩa các theme khác cho chế độ tối
    textTheme: const TextTheme(
      // Ví dụ: định nghĩa text style cho chế độ tối
      titleLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      bodyMedium: TextStyle(color: Colors.white70),
    ),
    // ... các tùy chỉnh theme khác ...
     buttonTheme: const ButtonThemeData(
       buttonColor: Colors.redAccent, // Màu nút tối
       textTheme: ButtonTextTheme.primary,
     ),
     //floatingActionButtonTheme: ...,
  );
}
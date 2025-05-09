String documentIdFromLocalData() => DateTime.now().toIso8601String();

 const String ADMIN_SELLER_ID = "M7CFrKwP9WUy8j5BdFq3F8zM9rl2"; // <-- THAY BẰNG ID THẬT
  const String ADMIN_SELLER_NAME = "Shop Support"; // Tên hiển thị của Admin

class AppConstants {
  static const String paymentIntentPath =
      'https://api.stripe.com/v1/payment_intents';

  /// Stripe Keys
  static const String publishableKey =
      '';
  static const String secretKey =
      '';
}
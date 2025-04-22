String documentIdFromLocalData() => DateTime.now().toIso8601String();

class AppConstants {
  static const String paymentIntentPath =
      'https://api.stripe.com/v1/payment_intents';

  /// Stripe Keys
  static const String publishableKey =
      '';
  static const String secretKey =
      '';
}
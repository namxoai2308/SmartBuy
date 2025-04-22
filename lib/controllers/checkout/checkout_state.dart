part of 'checkout_cubit.dart';

@immutable
sealed class CheckoutState {}

/// Initial state
final class CheckoutInitial extends CheckoutState {}

/// Checkout data loading
final class CheckoutLoading extends CheckoutState {}

/// Checkout data loaded
final class CheckoutLoaded extends CheckoutState {
  final List<DeliveryMethod> deliveryMethods;
  final ShippingAddress? shippingAddress;
  final DeliveryMethod? selectedDeliveryMethod;
  final double? totalAmount;

  CheckoutLoaded({
    required this.deliveryMethods,
    this.selectedDeliveryMethod,
    this.shippingAddress,
    required this.totalAmount,
  });

  CheckoutLoaded copyWith({
    List<DeliveryMethod>? deliveryMethods,
    ShippingAddress? shippingAddress,
    DeliveryMethod? selectedDeliveryMethod,
    double? totalAmount,
  }) {
    return CheckoutLoaded(
      deliveryMethods: deliveryMethods ?? this.deliveryMethods,
      shippingAddress: shippingAddress ?? this.shippingAddress,
      selectedDeliveryMethod: selectedDeliveryMethod ?? this.selectedDeliveryMethod,
      totalAmount: totalAmount ?? this.totalAmount,
    );
  }
}

final class CheckoutLoadingFailed extends CheckoutState {
  final String error;

  CheckoutLoadingFailed(this.error);
}

/// Address-related states
final class FetchingAddresses extends CheckoutState {}

final class AddressesFetched extends CheckoutState {
  final List<ShippingAddress> shippingAddresses;

  AddressesFetched(this.shippingAddresses);
}

final class AddressesFetchingFailed extends CheckoutState {
  final String error;

  AddressesFetchingFailed(this.error);
}

final class AddingAddress extends CheckoutState {}

final class AddressAdded extends CheckoutState {}

final class AddressAddingFailed extends CheckoutState {
  final String error;

  AddressAddingFailed(this.error);
}

/// Card-related states
final class AddingCards extends CheckoutState {}

final class CardsAdded extends CheckoutState {}

final class CardsAddingFailed extends CheckoutState {
  final String error;

  CardsAddingFailed(this.error);
}

final class DeletingCards extends CheckoutState {
  final String paymentId;

  DeletingCards(this.paymentId);
}

final class CardsDeleted extends CheckoutState {}

final class CardsDeletingFailed extends CheckoutState {
  final String error;

  CardsDeletingFailed(this.error);
}

final class FetchingCards extends CheckoutState {}

final class CardsFetched extends CheckoutState {
  final List<PaymentMethod> paymentMethods;

  CardsFetched(this.paymentMethods);
}

final class CardsFetchingFailed extends CheckoutState {
  final String error;

  CardsFetchingFailed(this.error);
}

/// Preferred payment method states
final class MakingPreferred extends CheckoutState {}

final class PreferredMade extends CheckoutState {}

final class PreferredMakingFailed extends CheckoutState {
  final String error;

  PreferredMakingFailed(this.error);
}

/// Payment process states
final class MakingPayment extends CheckoutState {}

final class PaymentMade extends CheckoutState {}

final class PaymentMakingFailed extends CheckoutState {
  final String error;

  PaymentMakingFailed(this.error);
}

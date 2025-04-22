import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_ecommerce/models/delivery_method.dart';
import 'package:flutter_ecommerce/models/payment_method.dart';
import 'package:flutter_ecommerce/models/shipping_address.dart';
import 'package:flutter_ecommerce/services/auth_services.dart';
import 'package:flutter_ecommerce/services/checkout_services.dart';
import 'package:flutter_ecommerce/services/stripe_services.dart';
import 'package:meta/meta.dart';

part 'checkout_state.dart';

class CheckoutCubit extends Cubit<CheckoutState> {
  CheckoutCubit() : super(CheckoutInitial()) {
    print('--- CheckoutCubit Created (Instance: $hashCode) ---');
  }

  final checkoutServices = CheckoutServicesImpl();
  final authServices = AuthServicesImpl();
  final stripeServices = StripeServices.instance;

  @override
  void emit(CheckoutState state) {
    print('CheckoutCubit (Instance: $hashCode) Emitting State: ${state.runtimeType}');
    if (isClosed) {
      print('CheckoutCubit (Instance: $hashCode) Warning: Emitting on a closed cubit');
      return;
    }
    super.emit(state);
  }

  // Stripe Payment
  Future<void> makePayment(double amount) async {
    emit(MakingPayment());
    try {
      await stripeServices.makePayment(amount, 'usd');
      emit(PaymentMade());
    } catch (e) {
      emit(PaymentMakingFailed(e.toString()));
    }
  }

  Future<void> addCard(PaymentMethod paymentMethod) async {
    emit(AddingCards());
    try {
      await checkoutServices.setPaymentMethod(paymentMethod);
      emit(CardsAdded());
      await fetchCards();
    } catch (e) {
      emit(CardsAddingFailed(e.toString()));
    }
  }

  Future<void> deleteCard(PaymentMethod paymentMethod) async {
    emit(DeletingCards(paymentMethod.id));
    try {
      await checkoutServices.deletePaymentMethod(paymentMethod);
      emit(CardsDeleted());
      await fetchCards();
    } catch (e) {
      emit(CardsDeletingFailed(e.toString()));
    }
  }

  Future<void> fetchCards() async {
    emit(FetchingCards());
    try {
      final cards = await checkoutServices.paymentMethods();
      emit(CardsFetched(cards));
    } catch (e) {
      emit(CardsFetchingFailed(e.toString()));
    }
  }

Future<void> makePreferred(PaymentMethod paymentMethod) async {
  emit(MakingPreferred());
  try {
    final preferred = await checkoutServices.paymentMethods(true);
    for (var method in preferred) {
      await checkoutServices.setPaymentMethod(
        method.copyWith(isPreferred: false),
      );
    }
    await checkoutServices.setPaymentMethod(
      paymentMethod.copyWith(isPreferred: true),
    );

    final updatedPaymentMethods = await checkoutServices.paymentMethods();
    final updatedPreferred = updatedPaymentMethods.firstWhere(
      (method) => method.isPreferred,
      orElse: () => updatedPaymentMethods.isNotEmpty
          ? updatedPaymentMethods.first
          : PaymentMethod.empty(),
    );

    final currentState = state;
    if (currentState is CheckoutLoaded) {
      emit(currentState.copyWith(
        selectedPaymentMethod: updatedPreferred,
      ));
    }

    // 👉 Emit PreferredMade để trigger Navigator.pop & cập nhật UI ở màn trước
    emit(PreferredMade());
  } catch (e) {
    emit(PreferredMakingFailed(e.toString()));
  }
}



  Future<void> getCheckoutData() async {
    print('CheckoutCubit (Instance: $hashCode): getCheckoutData() Called');
    emit(CheckoutLoading());
    try {
      final user = authServices.currentUser;
      final addresses = await checkoutServices.shippingAddresses(user!.uid);
      final delivery = await checkoutServices.deliveryMethods();
      final paymentMethods = await checkoutServices.paymentMethods();

      emit(CheckoutLoaded(
        deliveryMethods: delivery,
        selectedDeliveryMethod: delivery.isNotEmpty ? delivery.first : null,
        shippingAddress: addresses.isNotEmpty ? addresses.first : ShippingAddress.empty(),
        selectedPaymentMethod: paymentMethods.isNotEmpty
            ? paymentMethods.firstWhere((m) => m.isPreferred, orElse: () => paymentMethods.first)
            : null,
        totalAmount: 0.0,
      ));
    } catch (e) {
      emit(CheckoutLoadingFailed(e.toString()));
    }
  }

  Future<void> getShippingAddresses() async {
    final currentState = state;
    emit(FetchingAddresses());
    try {
      final user = authServices.currentUser;
      final addresses = await checkoutServices.shippingAddresses(user!.uid);
      emit(AddressesFetched(addresses));

      if (currentState is CheckoutLoaded) {
        emit(currentState.copyWith(
          shippingAddress: addresses.isNotEmpty ? addresses.first : ShippingAddress.empty(),
        ));
      }
    } catch (e) {
      emit(AddressesFetchingFailed(e.toString()));
    }
  }

  Future<void> saveAddress(ShippingAddress address) async {
    emit(AddingAddress());
    try {
      final user = authServices.currentUser;

      if (address.isDefault) {
        final existing = await checkoutServices.shippingAddresses(user!.uid);
        for (var a in existing) {
          if (a.id != address.id && a.isDefault) {
            await checkoutServices.saveAddress(user.uid, a.copyWith(isDefault: false));
          }
        }
      }
      await checkoutServices.saveAddress(user!.uid, address);

      emit(AddressAdded());
      final currentState = state;
      if (currentState is CheckoutLoaded) {
        final updatedAddresses = await checkoutServices.shippingAddresses(user.uid);
        final updatedDefaultAddress = updatedAddresses.firstWhere(
          (a) => a.isDefault,
          orElse: () => updatedAddresses.isNotEmpty ? updatedAddresses.first : ShippingAddress.empty(),
        );
        emit(currentState.copyWith(
          shippingAddress: updatedDefaultAddress,
        ));
      } else {
        await getCheckoutData();
      }
    } catch (e) {
      emit(AddressAddingFailed(e.toString()));
    }
  }

  void setSelectedAddress(ShippingAddress address) {
    print('CheckoutCubit (Instance: $hashCode): setSelectedAddress() Called');
    final currentState = state;

    if (currentState is CheckoutLoaded) {
      emit(currentState.copyWith(shippingAddress: address));
    } else {
      print('Cannot set selected address: State is not CheckoutLoaded. Current state: $currentState');
    }
  }

  void selectDeliveryMethod(DeliveryMethod method) {
    final currentState = state;
    if (currentState is CheckoutLoaded) {
      emit(currentState.copyWith(selectedDeliveryMethod: method));
    }
  }

  void updateCartTotalAmount(double newAmount) {
    final currentState = state;
    if (currentState is CheckoutLoaded) {
      emit(currentState.copyWith(totalAmount: newAmount));
    }
  }

  @override
  Future<void> close() {
    print('--- CheckoutCubit Closing (Instance: $hashCode) ---');
    return super.close();
  }
}

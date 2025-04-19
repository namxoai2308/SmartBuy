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
  CheckoutCubit() : super(CheckoutInitial());

  final checkoutServices = CheckoutServicesImpl();
  final authServices = AuthServicesImpl();
  final stripeServices = StripeServices.instance;

  // Thanh toán bằng Stripe
  Future<void> makePayment(double amount) async {
    emit(MakingPayment());

    try {
      await stripeServices.makePayment(amount, 'usd');
      emit(PaymentMade());
    } catch (e) {
      debugPrint(e.toString());
      emit(PaymentMakingFailed(e.toString()));
    }
  }

  // Thêm phương thức thanh toán
  Future<void> addCard(PaymentMethod paymentMethod) async {
    emit(AddingCards());

    try {
      await checkoutServices.setPaymentMethod(paymentMethod);
      emit(CardsAdded());
    } catch (e) {
      emit(CardsAddingFailed(e.toString()));
    }
  }

  // Xóa phương thức thanh toán
  Future<void> deleteCard(PaymentMethod paymentMethod) async {
    emit(DeletingCards(paymentMethod.id));

    try {
      await checkoutServices.deletePaymentMethod(paymentMethod);
      emit(CardsDeleted());
      await fetchCards(); // Cập nhật danh sách sau khi xóa
    } catch (e) {
      emit(CardsDeletingFailed(e.toString()));
    }
  }

  // Lấy danh sách phương thức thanh toán
  Future<void> fetchCards() async {
    emit(FetchingCards());

    try {
      final paymentMethods = await checkoutServices.paymentMethods();
      emit(CardsFetched(paymentMethods));
    } catch (e) {
      emit(CardsFetchingFailed(e.toString()));
    }
  }

  // Chọn phương thức thanh toán ưu tiên
  Future<void> makePreferred(PaymentMethod paymentMethod) async {
    emit(FetchingCards());

    try {
      final preferredMethods = await checkoutServices.paymentMethods(true);

      for (var method in preferredMethods) {
        final newMethod = method.copyWith(isPreferred: false);
        await checkoutServices.setPaymentMethod(newMethod);
      }

      final updatedPreferred = paymentMethod.copyWith(isPreferred: true);
      await checkoutServices.setPaymentMethod(updatedPreferred);

      emit(PreferredMade());
    } catch (e) {
      emit(PreferredMakingFailed(e.toString()));
    }
  }

  // Lấy dữ liệu thanh toán ban đầu: địa chỉ, phương thức giao hàng, v.v.
  Future<void> getCheckoutData() async {
    emit(CheckoutLoading());

    try {
      final currentUser = authServices.currentUser;
      final shippingAddresses = await checkoutServices.shippingAddresses(currentUser!.uid);
      final deliveryMethods = await checkoutServices.deliveryMethods();

      emit(CheckoutLoaded(
        deliveryMethods: deliveryMethods,
        selectedDeliveryMethod: state is CheckoutLoaded
            ? (state as CheckoutLoaded).selectedDeliveryMethod
            : null,
        shippingAddress: shippingAddresses.isNotEmpty ? shippingAddresses.first : null,
        totalAmount: 0.0,
      ));
    } catch (e) {
      emit(CheckoutLoadingFailed(e.toString()));
    }
  }

  // Lấy danh sách địa chỉ giao hàng
  Future<void> getShippingAddresses() async {
    emit(FetchingAddresses());

    try {
      final currentUser = authServices.currentUser;
      final addresses = await checkoutServices.shippingAddresses(currentUser!.uid);

      emit(AddressesFetched(addresses));
    } catch (e) {
      emit(AddressesFetchingFailed(e.toString()));
    }
  }

  // Lưu địa chỉ mới
  Future<void> saveAddress(ShippingAddress address) async {
    emit(AddingAddress());

    try {
      final currentUser = authServices.currentUser;
      await checkoutServices.saveAddress(currentUser!.uid, address);
      emit(AddressAdded());
    } catch (e) {
      emit(AddressAddingFailed(e.toString()));
    }
  }

  // Chọn phương thức giao hàng
  void selectDeliveryMethod(DeliveryMethod method) {
    final currentState = state;

    if (currentState is CheckoutLoaded) {
      emit(CheckoutLoaded(
        deliveryMethods: currentState.deliveryMethods,
        shippingAddress: currentState.shippingAddress,
        selectedDeliveryMethod: method,
        totalAmount: currentState.totalAmount,
      ));
    }
  }

  // Cập nhật tổng tiền trong giỏ hàng
  void updateCartTotalAmount(double newAmount) {
    final currentState = state;

    if (currentState is CheckoutLoaded) {
      emit(CheckoutLoaded(
        deliveryMethods: currentState.deliveryMethods,
        selectedDeliveryMethod: currentState.selectedDeliveryMethod,
        shippingAddress: currentState.shippingAddress,
        totalAmount: newAmount,
      ));
    }
  }
}

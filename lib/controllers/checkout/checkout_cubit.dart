import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_ecommerce/models/checkout/delivery_method.dart';
import 'package:flutter_ecommerce/models/checkout/payment_method.dart';
import 'package:flutter_ecommerce/models/checkout/shipping_address.dart';
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

// Giả sử trong CheckoutCubit bạn có một biến thành viên để lưu totalAmount cuối cùng được cập nhật
// double _currentKnownTotalAmount = 0.0;
// Và hàm updateCartTotalAmount sẽ cập nhật biến này:
// void updateCartTotalAmount(double newAmount) {
//   _currentKnownTotalAmount = newAmount;
//   final currentState = state;
//   if (currentState is CheckoutLoaded) {
//     emit(currentState.copyWith(totalAmount: newAmount));
//   }
// }

Future<bool> makePreferred(PaymentMethod paymentMethodToMakePreferred) async {
  final CheckoutState stateBeforeAction = state; // Đổi tên biến để rõ ràng hơn
  print('CheckoutCubit: makePreferred - State BEFORE action: ${stateBeforeAction.runtimeType}');

  emit(MakingPreferred(paymentMethodId: paymentMethodToMakePreferred.id)); // Thêm ID để UI có thể hiển thị loading trên thẻ cụ thể

  try {
    // 1. Cập nhật isPreferred=false cho tất cả các thẻ khác của user (nếu có)
    // Điều này đảm bảo chỉ có một thẻ là preferred
    final allUserCards = await checkoutServices.paymentMethods(); // Lấy tất cả thẻ của user
    for (var card in allUserCards) {
      if (card.isPreferred && card.id != paymentMethodToMakePreferred.id) {
        await checkoutServices.setPaymentMethod(card.copyWith(isPreferred: false));
        print('CheckoutCubit: makePreferred - Unset preferred for card: ${card.id}');
      }
    }

    // 2. Cập nhật isPreferred=true cho thẻ được chọn
    await checkoutServices.setPaymentMethod(
      paymentMethodToMakePreferred.copyWith(isPreferred: true),
    );
    print('CheckoutCubit: makePreferred - Set preferred for card: ${paymentMethodToMakePreferred.id}');

    final newlySetPreferredMethod = paymentMethodToMakePreferred.copyWith(isPreferred: true);

    // 3. Chuẩn bị dữ liệu và emit CheckoutLoaded state mới
    ShippingAddress? currentShippingAddress;
    List<DeliveryMethod> currentDeliveryMethods = [];
    DeliveryMethod? currentSelectedDeliveryMethod;
    double finalTotalAmountForState = 0.0;

    if (stateBeforeAction is CheckoutLoaded) {
      print('CheckoutCubit: makePreferred - Building from previous CheckoutLoaded.');
      currentShippingAddress = stateBeforeAction.shippingAddress;
      currentDeliveryMethods = stateBeforeAction.deliveryMethods;
      currentSelectedDeliveryMethod = stateBeforeAction.selectedDeliveryMethod;
      finalTotalAmountForState = stateBeforeAction.totalAmount ?? 0.0;
    } else {
      // Nếu state trước đó không phải là CheckoutLoaded, fetch lại dữ liệu cần thiết
      print('CheckoutCubit: makePreferred - Previous state was ${stateBeforeAction.runtimeType}. Fetching additional data for CheckoutLoaded.');
      final user = authServices.currentUser;
      if (user != null) {
        final addresses = await checkoutServices.shippingAddresses(user.uid);
        // Cố gắng tìm default address, nếu không có thì lấy cái đầu tiên, nếu rỗng thì empty.
        currentShippingAddress = addresses.isNotEmpty
            ? addresses.firstWhere((a) => a.isDefault, orElse: () => addresses.first)
            : ShippingAddress.empty();
      } else {
        currentShippingAddress = ShippingAddress.empty();
        print('CheckoutCubit: makePreferred - User is null, cannot fetch addresses.');
        // Có thể throw lỗi hoặc trả về false ở đây nếu user là bắt buộc
      }
      currentDeliveryMethods = await checkoutServices.deliveryMethods();
      currentSelectedDeliveryMethod = currentDeliveryMethods.isNotEmpty ? currentDeliveryMethods.first : null;

      // Lấy totalAmount:
      // Ưu tiên 1: Nếu CheckoutCubit có lưu trữ _currentKnownTotalAmount (được cập nhật bởi CartCubit)
      // finalTotalAmountForState = _currentKnownTotalAmount;
      // Ưu tiên 2: Nếu không, giữ giá trị 0.0 hoặc lấy từ nguồn khác nếu có
      // Hiện tại để 0.0, CheckoutPage nên cập nhật nó sau.
      print('CheckoutCubit: makePreferred - totalAmount for new CheckoutLoaded will be $finalTotalAmountForState (default or from previous logic).');
    }

    // 4. Emit CheckoutLoaded với payment method mới và các thông tin khác
    emit(CheckoutLoaded(
      shippingAddress: currentShippingAddress,
      deliveryMethods: currentDeliveryMethods,
      selectedDeliveryMethod: currentSelectedDeliveryMethod,
      selectedPaymentMethod: newlySetPreferredMethod,
      totalAmount: finalTotalAmountForState,
    ));
    print('CheckoutCubit: makePreferred - Emitted CheckoutLoaded with new preferred payment.');

    // KHÔNG EMIT PreferredMade nữa.
    // KHÔNG CẦN Future.delayed nữa vì hàm này sẽ được await ở UI.
    return true; // Báo hiệu thành công

  } catch (e, s) { // Bắt cả StackTrace để debug dễ hơn
    print('CheckoutCubit: makePreferred - Error: $e');
    print('CheckoutCubit: makePreferred - StackTrace: $s');
    emit(PreferredMakingFailed(e.toString()));
    return false; // Báo hiệu thất bại
  }
}

// Và đừng quên sửa State MakingPreferred nếu bạn muốn có paymentMethodId
// part 'checkout_state.dart';
// @immutable
// abstract class CheckoutState extends Equatable {
//   const CheckoutState();
//   @override
//   List<Object?> get props => [];
// }
// ...
// class MakingPreferred extends CheckoutState {
//   final String? paymentMethodId; // ID của thẻ đang được xử lý
//   const MakingPreferred({this.paymentMethodId});
//   @override
//   List<Object?> get props => [paymentMethodId];
// }



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

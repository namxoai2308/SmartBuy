// lib/controllers/order/order_cubit.dart
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_ecommerce/controllers/auth/auth_cubit.dart'; // Cần để lấy userId
import 'package:flutter_ecommerce/models/order/order_model.dart';
import 'package:flutter_ecommerce/services/order_services.dart';
// `meta.dart` không còn cần thiết khi dùng Equatable và khai báo part of

part 'order_state.dart'; // Đảm bảo dòng này tồn tại

class OrderCubit extends Cubit<OrderState> {
  final OrderServices orderServices;
  final AuthCubit authCubit; // AuthCubit để lấy thông tin người dùng

  List<OrderModel> _masterOrderList = []; // Danh sách gốc chứa tất cả đơn hàng đã fetch
  OrderStatus? _currentFilterStatus; // Trạng thái filter hiện tại

  OrderCubit({required this.orderServices, required this.authCubit})
      : super(const OrderInitial()) {
    debugPrint('🚀 OrderCubit INITIALIZED - HashCode: $hashCode');
  }

  /// Fetches orders for the currently logged-in user.
  /// [defaultFilterStatus] is applied after fetching.
  Future<void> fetchOrders({OrderStatus defaultFilterStatus = OrderStatus.pending}) async {
    final authState = authCubit.state;

    if (authState is AuthSuccess) {
      final userId = authState.user.uid;
      debugPrint('🛒 OrderCubit: Fetching orders for CURRENT USER: $userId');
      emit(const OrderLoading());
      try {
        _masterOrderList = await orderServices.getOrders(userId); // Gọi service lấy đơn hàng của user
        debugPrint('🛒 OrderCubit: FETCHED ${_masterOrderList.length} orders for user $userId.');
        _currentFilterStatus = defaultFilterStatus; // Set filter mặc định
        _applyFilterAndEmit();
      } catch (e) {
        debugPrint('🛒 OrderCubit: ERROR fetching user orders: $e');
        _masterOrderList = []; // Xóa list nếu lỗi
        _currentFilterStatus = null;
        emit(OrderError(e.toString()));
      }
    } else {
      debugPrint('🛒 OrderCubit: Cannot fetch user orders, user not logged in.');
      _masterOrderList = [];
      _currentFilterStatus = null;
      emit(const OrderError('User not logged in. Cannot fetch orders.'));
    }
  }

  /// Fetches ALL orders from the system (for Admin).
  /// [defaultFilterStatus] is applied after fetching.
  /// **QUAN TRỌNG**: Bạn cần tạo phương thức `getAllOrders()` trong `OrderServices`.
  Future<void> fetchAllOrdersForAdmin({OrderStatus defaultFilterStatus = OrderStatus.pending}) async {
    // Có thể thêm kiểm tra quyền admin ở đây nếu cần,
    // nhưng thường trang admin đã được bảo vệ bởi Route Guard hoặc logic trong UI.
    debugPrint('🛒 OrderCubit: Fetching ALL orders for ADMIN.');
    emit(const OrderLoading());
    try {
      // Yêu cầu OrderServices phải có phương thức này:
      _masterOrderList = await orderServices.getAllOrders(); // Đây là phương thức MỚI cần tạo trong OrderServices
      debugPrint('🛒 OrderCubit: FETCHED ${_masterOrderList.length} total orders for admin.');
      _currentFilterStatus = defaultFilterStatus; // Set filter mặc định
      _applyFilterAndEmit();
    } catch (e) {
      debugPrint('🛒 OrderCubit: ERROR fetching all admin orders: $e');
      _masterOrderList = []; // Xóa list nếu lỗi
      _currentFilterStatus = null;
      emit(OrderError(e.toString()));
    }
  }

  /// Applies the [_currentFilterStatus] to the [_masterOrderList] and emits [OrderLoaded].
  void filterOrders(OrderStatus? status) {
    debugPrint('🛒 OrderCubit: FILTERING called with status: $status. Current master list size: ${_masterOrderList.length}');
    _currentFilterStatus = status;
    _applyFilterAndEmit();
  }

  void _applyFilterAndEmit() {
    debugPrint('🛒 OrderCubit: Applying filter. Selected filter: $_currentFilterStatus. Master list size: ${_masterOrderList.length}');

    // Nếu lần fetch đầu tiên đã lỗi và _masterOrderList rỗng, không nên emit OrderLoaded
    // mà giữ nguyên OrderError đã được emit trước đó từ fetchCurrentUserOrders/fetchAllOrdersForAdmin.
    if (state is OrderError && _masterOrderList.isEmpty) {
        debugPrint('🛒 OrderCubit: Master list is empty and current state is Error. Retaining Error state.');
        // Không emit gì cả, giữ nguyên state lỗi đã có.
        // Nếu muốn UI hiển thị "không có đơn hàng" thay vì lỗi, thì cần logic khác.
        // Ví dụ: emit(OrderLoaded([])); // nếu muốn bỏ qua lỗi và hiển thị list rỗng
        return;
    }

    List<OrderModel> ordersToEmit;

    if (_currentFilterStatus == null) {
      ordersToEmit = List.from(_masterOrderList); // Tạo bản sao, không filter
      debugPrint('🛒 OrderCubit: No filter applied. Emitting ALL ${ordersToEmit.length} orders from master list.');
    } else {
      ordersToEmit = _masterOrderList
          .where((order) => order.status == _currentFilterStatus)
          .toList();
      debugPrint('🛒 OrderCubit: Filtered for $_currentFilterStatus. Emitting ${ordersToEmit.length} orders.');
    }
    emit(OrderLoaded(ordersToEmit)); // Luôn emit OrderLoaded ở đây sau khi lọc/không lọc
  }

  /// Cancels an order by its ID. Updates the order status to 'cancelled'.
  Future<bool> cancelOrder(String orderId) async {
    // final previousState = state; // Lưu state trước đó để có thể revert nếu cần thiết
    // emit(OrderLoading()); // Cân nhắc emit loading nếu thao tác hủy tốn thời gian

    try {
      await orderServices.updateOrderStatus(orderId, OrderStatus.cancelled);

      final orderIndex = _masterOrderList.indexWhere((o) => o.id == orderId);
      if (orderIndex != -1) {
        final originalOrder = _masterOrderList[orderIndex];

        // Tạo một bản sao của OrderModel với status đã cập nhật.
        // Cách tốt nhất là dùng hàm `copyWith` nếu OrderModel có.
        // Nếu không có, bạn phải tạo lại thủ công như code gốc của bạn:
        final updatedOrder = OrderModel(
          id: originalOrder.id,
          userId: originalOrder.userId,
          items: originalOrder.items, // Giữ nguyên list items
          totalAmount: originalOrder.totalAmount,
          deliveryFee: originalOrder.deliveryFee,
          shippingAddress: originalOrder.shippingAddress, // Giữ nguyên object
          paymentMethodDetails: originalOrder.paymentMethodDetails, // Giữ nguyên object
          status: OrderStatus.cancelled, // <<--- TRẠNG THÁI MỚI
          createdAt: originalOrder.createdAt,
          trackingNumber: originalOrder.trackingNumber,
          deliveryMethodInfo: originalOrder.deliveryMethodInfo, // Giữ nguyên object
          discountInfo: originalOrder.discountInfo, // Giữ nguyên object
//           totalQuantity: originalOrder.totalQuantity, // Giả sử có trường này
          // ... đảm bảo tất cả các trường khác của OrderModel được sao chép
        );

        _masterOrderList[orderIndex] = updatedOrder;
        _applyFilterAndEmit(); // Áp dụng lại filter và emit state mới (OrderLoaded)
        debugPrint('✅ Order $orderId cancelled successfully in Cubit and state updated.');
        return true;
      } else {
        debugPrint('⚠️ Order $orderId not found in local master list after cancelling. It might have been removed or not fetched.');
        // Nếu không tìm thấy, có thể đơn hàng đã bị xóa hoặc danh sách không đồng bộ.
        // Trong trường hợp này, việc gọi lại fetch (user hoặc admin tùy ngữ cảnh) có thể hữu ích,
        // nhưng để đơn giản, ta chỉ log và giả định backend đã xử lý.
        // Nếu muốn đồng bộ hoàn toàn, bạn cần logic để fetch lại đúng view.
        _applyFilterAndEmit(); // Vẫn emit lại để UI có thể refresh (nếu có gì đó thay đổi từ nơi khác)
        return true; // Coi như thành công vì backend đã cập nhật
      }
    } catch (e) {
      debugPrint('🛒 OrderCubit: ERROR cancelling order $orderId: $e');
      // Nếu đã emit OrderLoading ở trên, cần emit lại state trước đó hoặc OrderError
      // if (previousState is OrderLoaded) {
      //   emit(previousState);
      // } else {
      //   emit(OrderError('Failed to cancel order $orderId: $e'));
      // }
      // Vì không emit loading ở trên, chỉ cần đảm bảo state lỗi được emit nếu cần
      // Hoặc để UI tự xử lý dựa trên kết quả false.
      // Hiện tại, _applyFilterAndEmit có thể sẽ emit OrderLoaded với list cũ.
      // Cân nhắc emit một state lỗi cụ thể cho hành động này nếu UI cần.
      // Tạm thời, chúng ta sẽ không thay đổi state hiện tại khi có lỗi hủy, UI sẽ xử lý việc không thành công.
      emit(OrderError('Failed to cancel order $orderId: $e. Please try again.')); // Emit lỗi để UI biết
      return false;
    }
  }

  /// Clears the current orders list and filter, then emits [OrderInitial].
  /// Useful when navigating away from an order list page or on user logout.
  void clearAndResetOrders() {
    debugPrint('🛒 OrderCubit: Clearing orders and resetting state.');
    _masterOrderList = [];
    _currentFilterStatus = null;
    emit(const OrderInitial()); // Reset về trạng thái ban đầu
  }

  @override
  Future<void> close() {
    debugPrint('💀 OrderCubit CLOSED - HashCode: $hashCode');
    // Bạn có thể thêm logic dọn dẹp khác ở đây nếu cần
    return super.close();
  }
}
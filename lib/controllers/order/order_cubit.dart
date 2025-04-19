// lib/controllers/order/order_cubit.dart
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart'; // Import để dùng debugPrint
import 'package:flutter_ecommerce/controllers/auth/auth_cubit.dart';
import 'package:flutter_ecommerce/models/order_model.dart';
import 'package:flutter_ecommerce/services/order_services.dart';
import 'package:meta/meta.dart';

part 'order_state.dart';

class OrderCubit extends Cubit<OrderState> {
  final OrderServices orderServices;
  final AuthCubit authCubit;

  List<OrderModel> _originalOrders = [];
  OrderStatus? _selectedFilter;

  OrderCubit({required this.orderServices, required this.authCubit})
      : super(const OrderInitial()) {
    debugPrint('🚀 OrderCubit INITIALIZED - HashCode: $hashCode');
  }

  Future<void> fetchOrders() async {
    final authState = authCubit.state;

    if (authState is AuthSuccess) {
      final userId = authState.user.uid;
      debugPrint('🛒 OrderCubit: Fetching orders for userId: $userId');
      emit(const OrderLoading());
      try {
        _originalOrders = await orderServices.getOrders(userId);
        debugPrint('🛒 OrderCubit: FETCHED ${_originalOrders.length} original orders.');
        // Áp dụng bộ lọc đang chọn (hoặc mặc định) sau khi fetch
        _emitFilteredOrders();
      } catch (e) {
        debugPrint('🛒 OrderCubit: ERROR fetching orders: $e');
        emit(OrderError(e.toString()));
      }
    } else {
      debugPrint('🛒 OrderCubit: Cannot fetch orders, user not logged in.');
      emit(const OrderError('User not logged in. Cannot fetch orders.'));
    }
  }

  void filterOrders(OrderStatus? status) {
    debugPrint('🛒 OrderCubit: FILTERING called with status: $status. Current filter: $_selectedFilter');
    debugPrint('🛒 OrderCubit: Original orders list size before filter: ${_originalOrders.length}');

    _selectedFilter = status;
    _emitFilteredOrders();
  }

  void _emitFilteredOrders() {
    debugPrint('🛒 OrderCubit: Emitting filtered orders. Selected filter: $_selectedFilter. Original list size: ${_originalOrders.length}');

    // Kiểm tra nếu state hiện tại không phải loaded và list gốc rỗng thì không làm gì nhiều
    // Hoặc emit lại state lỗi nếu trước đó là lỗi
    if (state is! OrderLoaded && _originalOrders.isEmpty) {
        debugPrint('🛒 OrderCubit: Cannot filter, original orders list is empty or state is not OrderLoaded.');
        if (state is OrderError) {
           emit(state); // Giữ nguyên lỗi
        } else if (state is OrderInitial || state is OrderLoading){
             emit(const OrderLoaded([])); // Emit rỗng nếu đang loading/initial mà gọi filter
        }
        return;
    }


    List<OrderModel> ordersToEmit;

    if (_selectedFilter == null) {
      // Tạo bản sao của list gốc
      ordersToEmit = List.from(_originalOrders);
      debugPrint('🛒 OrderCubit: Emitting ALL ${ordersToEmit.length} orders.');
    } else {
      // Lọc từ list gốc
      ordersToEmit = _originalOrders
          .where((order) => order.status == _selectedFilter)
          .toList();
      debugPrint('🛒 OrderCubit: Filtered for $_selectedFilter. Emitting ${ordersToEmit.length} orders.');
    }
    // Emit state mới, Equatable sẽ xử lý việc có cần rebuild UI hay không
    emit(OrderLoaded(ordersToEmit));
  }

  // --- HÀM MỚI ĐỂ HỦY ĐƠN HÀNG ---
  Future<bool> cancelOrder(String orderId) async {
    // Tùy chọn: Emit state riêng cho việc hủy đơn hàng để hiển thị loading/indicator
    // Ví dụ: emit(OrderActionLoading(orderId));

    final currentState = state; // Lưu state hiện tại để có thể revert nếu lỗi

    try {
      // Gọi service để cập nhật trạng thái đơn hàng trong Firestore
      await orderServices.updateOrderStatus(orderId, OrderStatus.cancelled);

      // Cập nhật lại danh sách đơn hàng trong state của Cubit (quan trọng!)
      // Cách 1: Cập nhật trực tiếp list gốc và emit lại (hiệu quả nếu list lớn)
      final orderIndex = _originalOrders.indexWhere((o) => o.id == orderId);
      if (orderIndex != -1) {
        // Tạo bản sao của đơn hàng với trạng thái mới
        // Sử dụng copyWith nếu có, nếu không tạo lại thủ công
         final originalOrder = _originalOrders[orderIndex];
         final updatedOrder = OrderModel( // Tạo lại object thủ công
            id: originalOrder.id,
            userId: originalOrder.userId,
            items: originalOrder.items,
            totalAmount: originalOrder.totalAmount,
            deliveryFee: originalOrder.deliveryFee,
            shippingAddress: originalOrder.shippingAddress,
            paymentMethodDetails: originalOrder.paymentMethodDetails,
            status: OrderStatus.cancelled, // <-- Cập nhật status
            createdAt: originalOrder.createdAt,
            trackingNumber: originalOrder.trackingNumber,
            deliveryMethodInfo: originalOrder.deliveryMethodInfo,
            discountInfo: originalOrder.discountInfo
         );
        _originalOrders[orderIndex] = updatedOrder; // Thay thế trong list gốc
        // Emit lại state với danh sách đã lọc theo filter hiện tại
        _emitFilteredOrders();
        debugPrint('✅ Order $orderId cancelled successfully in Cubit and state updated.');
        return true; // Trả về true để báo thành công
      } else {
        // Trường hợp hiếm: không tìm thấy đơn hàng trong list gốc
        // Fetch lại toàn bộ danh sách để đảm bảo đồng bộ
        debugPrint('⚠️ Order $orderId not found in local list after cancelling. Refetching...');
        await fetchOrders(); // Fetch lại có thể làm mất filter đang chọn
        return true; // Vẫn coi là thành công vì backend đã cập nhật
      }

      // Cách 2: Fetch lại toàn bộ danh sách (đơn giản hơn nhưng tốn kém hơn)
      // await fetchOrders();
      // return true;

    } catch (e) {
      debugPrint('🛒 OrderCubit: ERROR cancelling order $orderId: $e');
      // Tùy chọn: Emit state lỗi riêng cho việc hủy đơn
      // Ví dụ: emit(OrderActionFailed(orderId, e.toString()));

      // Hoặc dùng state lỗi chung và giữ nguyên danh sách hiện tại
      emit(OrderError('Failed to cancel order $orderId: $e'));
      // Rất quan trọng: Emit lại state loaded cũ để UI không bị treo ở loading (nếu có)
      // Hoặc emit lại state đã lọc trước đó nếu currentState là OrderLoaded
       if (currentState is OrderLoaded) {
          // Cần đảm bảo _selectedFilter vẫn đúng
          _emitFilteredOrders();
       }

      return false; // Trả về false để báo thất bại
    }
  }
  // ------------------------------------

  @override
  Future<void> close() {
    debugPrint('💀 OrderCubit CLOSED - HashCode: $hashCode');
    return super.close();
  }
}
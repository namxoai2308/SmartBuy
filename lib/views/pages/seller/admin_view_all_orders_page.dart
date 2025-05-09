import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_ecommerce/controllers/order/order_cubit.dart';
import 'package:flutter_ecommerce/models/order/order_model.dart'; // For OrderStatus and statusToString
import 'package:flutter_ecommerce/views/pages/profile/order_details_page.dart';
// Giả sử OrderSummaryCard được tách ra file riêng hoặc bạn sẽ copy/paste nó vào đây
// import 'package:flutter_ecommerce/views/widgets/order_summary_card.dart'; // Nếu tách ra
import 'package:intl/intl.dart';

// IMPORTANT: Lớp OrderSummaryCard và hàm _getStatusColor, statusToString
// hiện đang nằm trong file MyOrdersPage.dart của bạn.
// Bạn NÊN tách OrderSummaryCard (và các helper liên quan nếu cần) ra một file widget riêng
// (ví dụ: lib/views/widgets/order_summary_card.dart) và import vào cả MyOrdersPage và AdminViewAllOrdersPage.
// Dưới đây, tôi giả định bạn sẽ làm vậy hoặc tạm thời copy code của OrderSummaryCard vào file này.
// Để ví dụ này chạy, bạn cần đảm bảo OrderSummaryCard, statusToString, OrderStatus được truy cập đúng.

// Nếu chưa tách OrderSummaryCard, bạn có thể copy định nghĩa của nó từ MyOrdersPage.dart vào đây.
// (Bao gồm cả _getStatusColor nếu nó là một phần của OrderSummaryCard hoặc MyOrdersPage's state)
// Tạm thời, chúng ta sẽ copy nó vào đây để code hoàn chỉnh.

// COPY_PASTE_MY_ORDERS_PAGE_ORDER_SUMMARY_CARD_HERE (bao gồm OrderStatus, statusToString nếu chưa import)
// Nếu OrderStatus và statusToString đã có trong order_model.dart thì chỉ cần import là đủ.

class AdminViewAllOrdersPage extends StatefulWidget {
  const AdminViewAllOrdersPage({super.key});

  @override
  State<AdminViewAllOrdersPage> createState() => _AdminViewAllOrdersPageState();
}

class _AdminViewAllOrdersPageState extends State<AdminViewAllOrdersPage> {
  OrderStatus _selectedStatus = OrderStatus.pending; // Trạng thái lọc mặc định

  @override
  void initState() {
    super.initState();
    // Đảm bảo cubit được reset hoặc tải đúng dữ liệu cho view này
    // context.read<OrderCubit>().clearOrders(); // Cân nhắc nếu cần reset state từ view trước

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final orderCubit = context.read<OrderCubit>();
        // 1. Yêu cầu Cubit tải TẤT CẢ đơn hàng cho admin.
        //    Phương thức này nên emit OrderLoading, sau đó là OrderLoaded (với tất cả đơn hàng) hoặc OrderError.
        orderCubit.fetchAllOrdersForAdmin().then((_) {
          // 2. Sau khi tất cả đơn hàng đã được tải (và cubit ở trạng thái OrderLoaded với _allOrdersForCurrentView đã được cập nhật),
          //    áp dụng bộ lọc mặc định của trang này (_selectedStatus).
          //    Lưu ý: Nếu fetchAllOrdersForAdmin đã tự áp dụng filter mặc định rồi thì dòng filterOrders dưới đây có thể không cần thiết
          //    hoặc cần logic để đồng bộ _selectedStatus. Dựa trên logic cubit ở trên, fetchAllOrdersForAdmin tự filter.
          //    Nếu fetchAllOrdersForAdmin *không* tự filter, thì dòng dưới là cần thiết:
          // if (mounted && orderCubit.state is OrderLoaded) { // Chỉ filter nếu đã load thành công
          //   orderCubit.filterOrders(_selectedStatus);
          // }
          // Vì OrderCubit ví dụ ở trên đã tự filter, chúng ta không cần gọi lại filterOrders ở đây
          // trừ khi muốn đảm bảo _selectedStatus của trang đồng bộ với filter của cubit.
          // Để an toàn, hãy cập nhật _selectedStatus của trang dựa trên filter hiện tại của cubit (nếu có)
          if (mounted && orderCubit.state is OrderLoaded) {
              // Đồng bộ _selectedStatus của trang với trạng thái filter hiện tại của Cubit
              // (Giả sử Cubit có một getter cho _currentFilterStatus)
              // setState(() {
              //   _selectedStatus = orderCubit.currentFilterStatus ?? OrderStatus.pending;
              // });
              // Hoặc nếu fetchAllOrdersForAdmin đã gọi filterOrders(_selectedStatus), thì không cần làm gì thêm.
          }

        }).catchError((error) {
          if (mounted && context.read<OrderCubit>().state is! OrderError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Failed to load orders: $error"))
            );
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final orderCubit = context.read<OrderCubit>();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.search),
                    onPressed: () {
                      // TODO: Implement search functionality for admin orders
                    },
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                'All Customer Orders', // Tiêu đề cho trang admin
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Wrap(
                  spacing: 8.0,
                  // Admin có thể muốn xem tất cả các trạng thái
                  children: OrderStatus.values.map((status) {
                    bool isSelected = _selectedStatus == status;
                    return ChoiceChip(
                      label: Text(
                        // Đảm bảo hàm statusToString có sẵn và hoạt động đúng
                        statusToString(status)[0].toUpperCase() + statusToString(status).substring(1),
                      ),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _selectedStatus = status;
                          });
                          orderCubit.filterOrders(status);
                        }
                      },
                      selectedColor: Colors.black,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : Colors.black54,
                        fontWeight: FontWeight.w500,
                      ),
                      backgroundColor: Colors.grey[200],
                      shape: const StadiumBorder(),
                      side: BorderSide.none,
                      visualDensity: VisualDensity.compact,
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: BlocBuilder<OrderCubit, OrderState>(
                builder: (context, state) {
                  if (state is OrderLoading || state is OrderInitial) {
                    return const Center(child: CircularProgressIndicator.adaptive());
                  } else if (state is OrderError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline, color: Colors.red, size: 50),
                            const SizedBox(height: 16),
                            Text(
                              'Error: ${state.message}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.red),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              icon: const Icon(Icons.refresh),
                              label: const Text('Try Again'),
                              onPressed: () {
                                // Gọi lại fetchAllOrdersForAdmin và sau đó filter
                                orderCubit.fetchAllOrdersForAdmin().then((_){
                                   if(mounted && orderCubit.state is OrderLoaded) {
                                    //  orderCubit.filterOrders(_selectedStatus); // Nếu cubit không tự filter
                                   }
                                });
                              },
                              style: ElevatedButton.styleFrom(
                                foregroundColor: Colors.white, backgroundColor: Colors.black87,
                              ),
                            )
                          ],
                        ),
                      ),
                    );
                  } else if (state is OrderLoaded) {
                    final ordersToShow = state.orders;

                    if (ordersToShow.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.receipt_long_outlined, size: 60, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text(
                              'No orders found with status\n"${statusToString(_selectedStatus)}".',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 16.0),
                      itemCount: ordersToShow.length,
                      itemBuilder: (context, index) {
                        final order = ordersToShow[index];
                        // Sử dụng lại OrderSummaryCard. Đảm bảo nó được import hoặc định nghĩa ở đây.
                        return OrderSummaryCard(
                          order: order,
                          orderCubit: orderCubit,
                        );
                      },
                    );
                  } else {
                    return const Center(child: Text('An unknown error occurred.'));
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- QUAN TRỌNG ---
// Lớp OrderSummaryCard và các thành phần phụ thuộc của nó (như _getStatusColor)
// được định nghĩa trong file MyOrdersPage.dart của bạn.
// BẠN NÊN TÁCH OrderSummaryCard RA MỘT FILE RIÊNG (ví dụ: lib/views/widgets/order_summary_card.dart)
// và import nó vào cả MyOrdersPage.dart và admin_view_all_orders_page.dart.
// Để đoạn code trên hoạt động, bạn cần làm điều này hoặc copy/paste code của OrderSummaryCard vào đây.
// Ví dụ, nếu bạn copy OrderSummaryCard từ MyOrdersPage.dart, nó sẽ trông như thế này:

class OrderSummaryCard extends StatelessWidget {
  final OrderModel order;
  final OrderCubit orderCubit;

  const OrderSummaryCard({
    super.key,
    required this.order,
    required this.orderCubit,
  });

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.delivered:
        return Colors.green.shade700;
      case OrderStatus.cancelled:
        return Colors.red.shade700;
      // Thêm các case khác nếu có: processing, shipped
      case OrderStatus.processing:
        return Colors.blue.shade700;
//       case OrderStatus.shipped:
//         return Colors.purple.shade700;
      default: // pending
        return Colors.orange.shade700;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final formattedDate = DateFormat('dd-MM-yyyy').format(order.createdAt.toDate());

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      elevation: 1.0,
      shadowColor: Colors.grey.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Order №${order.id.substring(0, 8)}',
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  formattedDate,
                  style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                ),
              ],
            ),
            const SizedBox(height: 4.0),
            // Hiển thị User ID cho Admin (tùy chọn)
             Text(
               'User ID: ${order.userId.substring(0,10)}...', // Hiển thị một phần UserID
               style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[700]),
               maxLines: 1,
               overflow: TextOverflow.ellipsis,
             ),
            const SizedBox(height: 8.0),
            RichText(
              text: TextSpan(
                style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                children: [
                  const TextSpan(text: 'Tracking number: '),
                  TextSpan(
                    text: order.trackingNumber,
                    style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500, color: Colors.black87),
                  ),
                ],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                RichText(
                  text: TextSpan(
                    style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                    children: [
                      const TextSpan(text: 'Quantity: '),
                      TextSpan(
                        text: '${order.totalQuantity}',
                        style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500, color: Colors.black87),
                      ),
                    ],
                  ),
                ),
                RichText(
                  text: TextSpan(
                    style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                    children: [
                      const TextSpan(text: 'Total Amount: '),
                      TextSpan(
                        text: '\$${order.totalAmount.toStringAsFixed(2)}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                OutlinedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => OrderDetailsPage( // Trang này có thể cần được điều chỉnh cho admin view
                          order: order,
                          orderCubit: orderCubit,
                        ),
                      ),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20.0),
                    ),
                    side: BorderSide(color: Colors.grey.shade400),
                  ),
                  child: const Text('Details', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w500)),
                ),
                Text(
                  // Đảm bảo statusToString có sẵn
                  statusToString(order.status)[0].toUpperCase() + statusToString(order.status).substring(1),
                  style: TextStyle(
                    color: _getStatusColor(order.status),
                    fontWeight: FontWeight.bold,
                  ),
                )
              ],
            )
          ],
        ),
      ),
    );
  }
}
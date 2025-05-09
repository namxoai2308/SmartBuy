import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_ecommerce/controllers/order/order_cubit.dart';
import 'package:flutter_ecommerce/controllers/auth/auth_cubit.dart';
import 'package:flutter_ecommerce/models/order/order_model.dart';
import 'package:flutter_ecommerce/views/pages/profile/order_details_page.dart';
import 'package:intl/intl.dart';

class MyOrdersPage extends StatefulWidget {
  const MyOrdersPage({super.key});

  @override
  State<MyOrdersPage> createState() => _MyOrdersPageState();
}

class _MyOrdersPageState extends State<MyOrdersPage> {
  OrderStatus _selectedStatus = OrderStatus.pending;

@override
void initState() {
  super.initState();
  debugPrint('[MyOrdersPage] initState called'); // LOG 1
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (mounted) {
      debugPrint('[MyOrdersPage] addPostFrameCallback - mounted'); // LOG 2
      try {
        final authCubitState = context.read<AuthCubit>().state;
        debugPrint('[MyOrdersPage] Current AuthState in MyOrdersPage: $authCubitState'); // LOG 3

        final orderCubit = context.read<OrderCubit>();
        debugPrint('[MyOrdersPage] Attempting to fetchCurrentUserOrders...'); // LOG 4
        orderCubit.fetchOrders(defaultFilterStatus: _selectedStatus);
        debugPrint('[MyOrdersPage] fetchCurrentUserOrders called'); // LOG 5
      } catch (e) {
        debugPrint('[MyOrdersPage] ERROR in initState: $e'); // LOG LỖI
      }
    } else {
      debugPrint('[MyOrdersPage] addPostFrameCallback - NOT mounted');
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
                    onPressed: () {},
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                'My Orders',
                style: TextStyle(
                  fontSize: 32,
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
                  children: OrderStatus.values.map((status) {
                    if (status == OrderStatus.delivered ||
                        status == OrderStatus.cancelled ||
                        status == OrderStatus.pending) {
                      bool isSelected = _selectedStatus == status;
                      return ChoiceChip(
                        label: Text(
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
                    } else {
                      return const SizedBox.shrink();
                    }
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
                                orderCubit.fetchOrders();
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
                              _selectedStatus == null
                                  ? 'You haven\'t placed any orders yet.'
                                  : 'No orders found with status\n"${statusToString(_selectedStatus)}".',
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
      default:
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
                        builder: (_) => OrderDetailsPage(
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

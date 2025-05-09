import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_ecommerce/controllers/order/order_cubit.dart';
import 'package:flutter_ecommerce/models/order/order_item_model.dart';
import 'package:flutter_ecommerce/models/order/order_model.dart';
import 'package:intl/intl.dart';

class OrderDetailsPage extends StatelessWidget {
  final OrderModel order;
  final OrderCubit orderCubit;

  const OrderDetailsPage({
    super.key,
    required this.order,
    required this.orderCubit,
  });

  void _handleCancelOrder(BuildContext pageContext) async {
    final confirmed = await showDialog<bool>(
      context: pageContext,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Cancel Order'),
          content: const Text(
              'Are you sure you want to cancel this order? This action cannot be undone.'),
          actions: <Widget>[
            TextButton(
              child: const Text('No'),
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
            ),
            TextButton(
              child: Text('Yes, Cancel', style: TextStyle(color: Colors.red.shade700)),
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
            ),
          ],
        );
      },
    );

    if (confirmed == true && pageContext.mounted) {
      final success = await orderCubit.cancelOrder(order.id);
      if (success && pageContext.mounted) {
        ScaffoldMessenger.of(pageContext).showSnackBar(
          const SnackBar(
            content: Text('Order cancelled successfully.'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(pageContext).pop();
      }
    }
  }

  Widget _buildInfoRow(BuildContext context, String label, String value, {bool isTotal = false}) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final formattedDate = DateFormat('dd-MM-yyyy').format(order.createdAt.toDate());

    Color getStatusColor(OrderStatus status) {
      switch (status) {
        case OrderStatus.delivered: return Colors.green.shade700;
        case OrderStatus.cancelled: return Colors.red.shade700;
        default: return Colors.orange.shade700;
      }
    }

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Order Details'),
        centerTitle: true,
        elevation: 1,
        shadowColor: Colors.grey.withOpacity(0.2),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Order №${order.id.substring(0, 8)}',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  formattedDate,
                  style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                ),
              ],
            ),
            const SizedBox(height: 8.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: RichText(
                    text: TextSpan(
                      style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                      children: [
                        const TextSpan(text: 'Tracking number: '),
                        TextSpan(
                          text: order.trackingNumber,
                          style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500, color: Colors.black87),
                        ),
                      ],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  statusToString(order.status)[0].toUpperCase() + statusToString(order.status).substring(1),
                  style: TextStyle(
                      color: getStatusColor(order.status),
                      fontWeight: FontWeight.bold
                  ),
                )
              ],
            ),
            const SizedBox(height: 20.0),
            Text(
              '${order.items.length} ${order.items.length > 1 ? "items" : "item"}',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12.0),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: order.items.length,
              itemBuilder: (context, index) {
                final item = order.items[index];
                return OrderItemDetailsCard(item: item);
              },
              separatorBuilder: (context, index) => const SizedBox(height: 12),
            ),
            const SizedBox(height: 24.0),
            Text(
              'Order information',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12.0),
            _buildInfoRow(context, 'Shipping Address:', order.shippingAddress),
            _buildInfoRow(context, 'Payment method:', order.paymentMethodDetails),
            _buildInfoRow(context, 'Delivery method:', order.deliveryMethodInfo),
            if (order.discountInfo != null && order.discountInfo!.isNotEmpty)
              _buildInfoRow(context, 'Discount:', order.discountInfo!),
            const Divider(height: 20, thickness: 0.5),
            _buildInfoRow(context, 'Total Amount:', '\$${order.totalAmount.toStringAsFixed(2)}', isTotal: true),
            const SizedBox(height: 32.0),
            if (order.status == OrderStatus.pending)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  child: const Text('Cancel Order', style: TextStyle(color: Colors.white)),
                  onPressed: () => _handleCancelOrder(context),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25.0),
                    ),
                    backgroundColor: Colors.red.shade700,
                    foregroundColor: Colors.white,
                    elevation: 2,
                  ),
                ),
              )
            else if (order.status == OrderStatus.cancelled)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: order.items.isEmpty ? null : () {},
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25.0),
                        ),
                        side: BorderSide(color: order.items.isEmpty ? Colors.grey.shade300 : Colors.grey.shade600),
                        disabledForegroundColor: Colors.grey.shade400.withOpacity(0.38),
                        disabledBackgroundColor: Colors.transparent,
                      ),
                      child: Text('Reorder', style: TextStyle(color: order.items.isEmpty ? Colors.grey.shade400 : Colors.black87)),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: ElevatedButton(
                      child: const Text('Leave feedback'),
                      onPressed: null,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25.0),
                        ),
                        elevation: 0,
                        disabledBackgroundColor: Colors.grey.shade300,
                        disabledForegroundColor: Colors.grey.shade500,
                      ),
                    ),
                  ),
                ],
              )
            else if (order.status == OrderStatus.delivered || order.status == OrderStatus.processing)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: order.items.isEmpty ? null : () {},
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25.0),
                        ),
                        side: BorderSide(color: order.items.isEmpty ? Colors.grey.shade300 : Colors.grey.shade600),
                        disabledForegroundColor: Colors.grey.shade400.withOpacity(0.38),
                        disabledBackgroundColor: Colors.transparent,
                      ),
                      child: Text('Reorder', style: TextStyle(color: order.items.isEmpty ? Colors.grey.shade400 : Colors.black87)),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: ElevatedButton(
                      child: const Text('Leave feedback', style: TextStyle(color: Colors.white)),
                      onPressed: order.status == OrderStatus.delivered ? () {} : null,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25.0),
                        ),
                        elevation: 2,
                        disabledBackgroundColor: Colors.grey.shade300,
                        disabledForegroundColor: Colors.grey.shade500,
                      ),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 16.0),
          ],
        ),
      ),
    );
  }
}

class OrderItemDetailsCard extends StatelessWidget {
  final OrderItemModel item;
  const OrderItemDetailsCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8.0),
          border: Border.all(color: Colors.grey.shade200, width: 1)
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8.0),
            child: Image.network(
              item.imgUrl,
              width: 70,
              height: 70,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(width: 70, height: 70, color: Colors.grey[200], child: Icon(Icons.broken_image_outlined, color: Colors.grey[400], size: 30)),
              loadingBuilder:(context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(width: 70, height: 70, color: Colors.grey[200], child: Center(child: CircularProgressIndicator(strokeWidth: 2, value: loadingProgress.expectedTotalBytes != null ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes! : null,)));
              },
            ),
          ),
          const SizedBox(width: 16.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4.0),
                Text(
                  'Brand/Category Placeholder',
                  style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8.0),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if(item.color != null && item.color!.isNotEmpty) ...[
                      Text('Color: ', style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600])),
                      Text(item.color!, style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500, color: Colors.black87)),
                      const SizedBox(width: 12.0),
                    ],
                    if(item.size != null && item.size!.isNotEmpty) ...[
                      Text('Size: ', style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600])),
                      Text(item.size!, style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500, color: Colors.black87)),
                    ]
                  ],
                ),
                const SizedBox(height: 8.0),
                Text(
                  '\$${item.price.toStringAsFixed(2)}',
                  style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16.0),
          Text(
            'x${item.quantity}',
            style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold, color: Colors.black87),
          ),
        ],
      ),
    );
  }
}
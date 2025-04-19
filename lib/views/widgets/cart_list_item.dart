import 'package:flutter/material.dart';
import 'package:flutter_ecommerce/models/add_to_cart_model.dart';

class CartListItem extends StatelessWidget {
  final AddToCartModel cartItem;
  final VoidCallback onRemove;
  final VoidCallback onIncrease;
  final VoidCallback onDecrease;

  const CartListItem({
    Key? key,
    required this.cartItem,
    required this.onRemove,
    required this.onIncrease,
    required this.onDecrease,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
    color: Colors.white,
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: SizedBox(
          height: 100,
          child: Stack(
            children: [
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      cartItem.imgUrl,
                      width: 70,
                      height: 70,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 12),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          cartItem.title,
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Color: ${cartItem.color}    Size: ${cartItem.size}',
                          style:
                              const TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            _buildQuantityButton(
                              icon: Icons.remove,
                              onTap: onDecrease,
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12),
                              child: Text(
                                '${cartItem.quantity}',
                                style: const TextStyle(fontSize: 16),
                              ),
                            ),
                            _buildQuantityButton(
                              icon: Icons.add,
                              onTap: onIncrease,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 48),
                ],
              ),

              Positioned(
                top: 0,
                right: -10,
                child: PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'remove') onRemove();
                  },
                  itemBuilder: (BuildContext context) => [
                    const PopupMenuItem<String>(
                      value: 'remove',
                      child: Text('Remove'),
                    ),
                  ],
                  icon: Icon(Icons.more_vert, color: Colors.grey[600]),
                  padding: EdgeInsets.zero,
                  offset: const Offset(0, 30),
                ),
              ),

              Positioned(
                bottom: 5,
                right: 0,
                child: Text(
                  '${(cartItem.price * cartItem.quantity).toStringAsFixed(0)}\$',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 17),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuantityButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Icon(icon, size: 16),
      ),
    );
  }
}

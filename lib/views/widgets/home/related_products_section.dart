import 'package:flutter/material.dart';
import 'package:flutter_ecommerce/models/product.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:flutter_ecommerce/utilities/routes.dart';

class YouMayAlsoLikeSection extends StatelessWidget {
  final List<Product> relatedProducts;
  final Function(Product) onProductTapped;

  const YouMayAlsoLikeSection({
    Key? key,
    required this.relatedProducts,
    required this.onProductTapped,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "You may also like",
            style: Theme.of(context).textTheme.titleLarge!.copyWith(
            fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 320, // Tăng chiều cao để đủ chứa nội dung
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: relatedProducts.length,
              itemBuilder: (context, index) {
                final product = relatedProducts[index];

                return Padding(
                  padding: const EdgeInsets.only(right: 12.0),
                  child: _ProductCard(
                    product: product,
                    isNew: true,
                    onTap: () => onProductTapped(product),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  bool _isNewProduct(DateTime createdAt) {
    final now = DateTime.now();
    final difference = now.difference(createdAt);
    return difference.inDays <= 30; // Sản phẩm tạo trong vòng 30 ngày => NEW
  }
}

class _ProductCard extends StatelessWidget {
  final Product product;
  final bool isNew;
  final VoidCallback onTap;

  const _ProductCard({
    Key? key,
    required this.product,
    required this.isNew,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bool isDiscounted = product.discountValue != null && product.discountValue! > 0;
    final double discount = (product.discountValue ?? 0).toDouble();

    return InkWell(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12.0),
                  child: Image.network(
                    product.imgUrl,
                    fit: BoxFit.contain,
                  ),
                ),
              ),

              // Badge: Sale or New
              Positioned(
                top: 8,
                left: 8,
                child: SizedBox(
                  width: 50,
                  height: 25,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16.0),
                      color: isDiscounted
                          ? Colors.red
                          : (isNew ? Colors.black : Colors.transparent),
                    ),
                    child: isDiscounted || isNew
                        ? Padding(
                            padding: const EdgeInsets.all(4.0),
                            child: Center(
                              child: Text(
                                isDiscounted
                                    ? '-${discount.toStringAsFixed(0)}%'
                                    : 'NEW',
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall!
                                    .copyWith(color: Colors.white),
                              ),
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8.0),

          // Product info section
          Container(
            width: 200,
            color: Colors.grey[100],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Rating bar
                Row(
                  children: [
                    RatingBarIndicator(
                      itemSize: 20.0,
                      rating: product.rate?.toDouble() ?? 4.0,
                      itemBuilder: (context, _) => const Icon(
                        Icons.star,
                        color: Colors.amber,
                      ),
                      direction: Axis.horizontal,
                    ),
                    const SizedBox(width: 4.0),
                    Text(
                      '(${product.reviewCount})',
                      style: Theme.of(context).textTheme.labelSmall!.copyWith(
                            color: Colors.grey,
                          ),
                    ),
                  ],
                ),

                const SizedBox(height: 6.0),

                // Brand
                if (product.brand != null)
                  Text(
                    '${product.brand!}',
                    style: Theme.of(context).textTheme.labelSmall!.copyWith(
                          color: Colors.grey,
                        ),
                  ),

                // Title
                Text(
                  product.title,
                  style: Theme.of(context).textTheme.labelMedium!.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),

                // In stock status
                if (product.inStock != null)
                  Text(
                    product.inStock! ? 'In Stock' : 'Out of Stock',
                    style: Theme.of(context).textTheme.labelSmall!.copyWith(
                          color: product.inStock! ? Colors.green : Colors.red,
                        ),
                  ),

                const SizedBox(height: 6.0),

                // Price and discount
                isDiscounted
                    ? Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: '${product.price}\$  ',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelMedium!
                                  .copyWith(
                                    color: Colors.grey,
                                    decoration: TextDecoration.lineThrough,
                                  ),
                            ),
                            TextSpan(
                              text:
                                  '${(product.price * (1 - discount / 100)).toStringAsFixed(2)}\$',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelMedium!
                                  .copyWith(
                                    color: Colors.red,
                                  ),
                            ),
                          ],
                        ),
                      )
                    : Text(
                        '${product.price}\$',
                        style: Theme.of(context).textTheme.labelMedium,
                      ),

                const SizedBox(height: 8.0),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

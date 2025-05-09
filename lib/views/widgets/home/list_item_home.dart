import 'package:flutter/material.dart';
import 'package:flutter_ecommerce/controllers/database_controller.dart';
import 'package:flutter_ecommerce/models/home/product.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:flutter_ecommerce/utilities/assets.dart';
import 'package:flutter_ecommerce/utilities/routes.dart';
import 'package:provider/provider.dart';

class ListItemHome extends StatelessWidget {
  final Product product;
  final bool isNew;
  final VoidCallback? addToFavorites;
  bool isFavorite;

  ListItemHome({
    super.key,
    required this.product,
    required this.isNew,
    this.addToFavorites,
    this.isFavorite = false,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final bool isDiscounted = product.discountValue != null && product.discountValue! > 0;
    final double discount = (product.discountValue ?? 0).toDouble();

    return InkWell(
      onTap: () => Navigator.of(context, rootNavigator: true).pushNamed(
        AppRoutes.productDetailsRoute,
        arguments: product.id,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  color: colorScheme.surfaceVariant,
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
                          : (isNew ? colorScheme.onSurface : Colors.transparent),
                    ),
                    child: isDiscounted || isNew
                        ? Padding(
                            padding: const EdgeInsets.all(4.0),
                            child: Center(
                              child: Text(
                                isDiscounted
                                    ? '-${discount.toStringAsFixed(0)}%'
                                    : 'NEW',
                                style: theme.textTheme.labelSmall!.copyWith(color: Colors.white),
                              ),
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                ),
              ),

              // Favorite (heart) icon button
              Positioned(
                right: 8,
                bottom: 8,
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        blurRadius: 5,
                        color: colorScheme.surface,
                        spreadRadius: 2,
                      )
                    ],
                  ),
                  child: CircleAvatar(
                    backgroundColor: colorScheme.onPrimary,
                    radius: 20.0,
                    child: InkWell(
                      onTap: addToFavorites,
                      child: Icon(
                        isFavorite ? Icons.favorite : Icons.favorite_outline,
                        size: 20.0,
                        color: isFavorite ? Colors.red : colorScheme.onSurface.withOpacity(0.5),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 4.0),

          // Product info section
          Container(
              width: 200,
              padding: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                color: colorScheme.onPrimary,
                borderRadius: BorderRadius.circular(12.0),
                boxShadow: [
                  BoxShadow(
                    color: theme.shadowColor.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
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
                    const SizedBox(width: 2.0),
                    Text(
                      '(${product.reviewCount})',
                      style: theme.textTheme.labelSmall!.copyWith(
                        color: colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 2.0),

                // Brand
                if (product.brand != null)
                  Text(
                    '${product.brand!}',
                    style: theme.textTheme.labelSmall!.copyWith(
                      color: colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),

                // Title
                Text(
                  product.title,
                  style: theme.textTheme.labelMedium!.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),

                // In stock status
                if (product.inStock != null)
                  Text(
                    product.inStock! ? 'In Stock' : 'Out of Stock',
                    style: theme.textTheme.labelSmall!.copyWith(
                      color: product.inStock! ? Colors.green : Colors.red,
                    ),
                  ),

                const SizedBox(height: 4.0),

                // Price and discount
                isDiscounted
                    ? Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: '${product.price}\$  ',
                              style: theme.textTheme.labelSmall!.copyWith(
                                color: colorScheme.onSurface.withOpacity(0.5),
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                            TextSpan(
                              text:
                                  '${(product.price * (1 - discount / 100)).toStringAsFixed(2)}\$',
                              style: theme.textTheme.labelSmall!.copyWith(
                                color: colorScheme.error,
                              ),
                            ),
                          ],
                        ),
                      )
                    : Text(
                        '${product.price}\$',
                        style: theme.textTheme.labelSmall!.copyWith(
                          color: colorScheme.onSurface,
                        ),
                      ),

                const SizedBox(height: 4.0),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

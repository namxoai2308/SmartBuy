import 'package:flutter/material.dart';
import 'package:flutter_ecommerce/controllers/database_controller.dart';
import 'package:flutter_ecommerce/models/product.dart';
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

    final bool isDiscounted = product.discountValue != null && product.discountValue! > 0;
    final double discount = (product.discountValue ?? 0).toDouble();

    return InkWell(
      onTap: () => Navigator.of(context, rootNavigator: true).pushNamed(
        AppRoutes.productDetailsRoute,
        arguments: product.id,
      ),
      child: Stack(
        children: [
          Stack(
            children: [
              // Product Image
              ClipRRect(
                borderRadius: BorderRadius.circular(12.0),
                child: Image.network(
                  product.imgUrl,
                  width: 200,
                  height: 200,
                  fit: BoxFit.cover,
                ),
              ),

              // Badge: Sale or New
              Padding(
                padding: const EdgeInsets.all(8.0),
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

          // Favorite (heart) icon button
          Positioned(
            left: size.width * 0.35,
            bottom: size.height * 0.11,
            child: Container(
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    blurRadius: 5,
                    color: Colors.grey,
                    spreadRadius: 2,
                  )
                ],
              ),
              child: CircleAvatar(
                backgroundColor: Colors.white,
                radius: 20.0,
                child: InkWell(
                  onTap: addToFavorites,
                  child: Icon(
                    isFavorite ? Icons.favorite : Icons.favorite_outline,
                    size: 20.0,
                    color: isFavorite ? Colors.red : Colors.grey,
                  ),
                ),
              ),
            ),
          ),

          // Product info section
          Positioned(
            bottom: 5,
            child: SizedBox(
              width: 200,
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
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

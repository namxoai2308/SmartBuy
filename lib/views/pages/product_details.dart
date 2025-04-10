import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_ecommerce/controllers/product_details/product_details_cubit.dart';
import 'package:flutter_ecommerce/models/review.dart';
import 'package:flutter_ecommerce/views/widgets/drop_down_menu.dart';
import 'package:flutter_ecommerce/views/widgets/main_button.dart';

class ProductDetails extends StatefulWidget {
  const ProductDetails({super.key});

  @override
  State<ProductDetails> createState() => _ProductDetailsState();
}

class _ProductDetailsState extends State<ProductDetails> {
  bool isFavorite = false;
  late String dropdownValue;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final productDetailsCubit = BlocProvider.of<ProductDetailsCubit>(context);

    return BlocBuilder<ProductDetailsCubit, ProductDetailsState>(
      bloc: productDetailsCubit,
      buildWhen: (previous, current) =>
          current is ProductDetailsLoading ||
          current is ProductDetailsLoaded ||
          current is ProductDetailsError,
      builder: (context, state) {
        if (state is ProductDetailsLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator.adaptive()),
          );
        } else if (state is ProductDetailsError) {
          return Scaffold(
            body: Center(child: Text(state.error)),
          );
        } else if (state is ProductDetailsLoaded) {
          final product = state.product;

          return Scaffold(
            appBar: AppBar(
              title: Text(
                product.title,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              actions: [
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.share),
                ),
              ],
            ),
            body: SingleChildScrollView(
              child: Column(
                children: [
                  Image.network(
                    product.imgUrl,
                    width: double.infinity,
                    height: size.height * 0.55,
                    fit: BoxFit.cover,
                  ),
                  const SizedBox(height: 8.0),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: SizedBox(
                                height: 60,
                                child: DropDownMenuComponent(
                                  items: const ['S', 'M', 'L', 'XL', 'XXL'],
                                  hint: 'Size',
                                  onChanged: (String? newValue) =>
                                      productDetailsCubit.setSize(newValue!),
                                ),
                              ),
                            ),
                            const Spacer(),
                            InkWell(
                              onTap: () {
                                setState(() {
                                  isFavorite = !isFavorite;
                                });
                              },
                              child: SizedBox(
                                height: 60,
                                width: 60,
                                child: DecoratedBox(
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white,
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Icon(
                                      isFavorite
                                          ? Icons.favorite
                                          : Icons.favorite_border_outlined,
                                      color:
                                          isFavorite ? Colors.redAccent : Colors.black45,
                                      size: 30,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24.0),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              product.title,
                              style: Theme.of(context).textTheme.titleLarge!.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                            Text(
                              '\$${product.price}',
                              style: Theme.of(context).textTheme.titleLarge!.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8.0),
                        Text(
                          product.category,
                          style: Theme.of(context).textTheme.labelMedium!.copyWith(
                                color: Colors.black54,
                              ),
                        ),
                        const SizedBox(height: 16.0),

                        // --- Info Section ---
                        if (product.brand != null)
                          _buildInfoRow('Brand', product.brand!),

                        if (product.inStock != null)
                          _buildInfoRow('Availability', product.inStock! ? 'In Stock' : 'Out of Stock'),

                        if (product.description != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 12.0),
                            child: Text(
                              product.description!,
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                          ),

                        const SizedBox(height: 24.0),
                        BlocConsumer<ProductDetailsCubit, ProductDetailsState>(
                          bloc: productDetailsCubit,
                          listenWhen: (previous, current) =>
                              current is AddedToCart || current is AddToCartError,
                          listener: (context, state) {
                            if (state is AddedToCart) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Product added to the cart!')),
                              );
                            } else if (state is AddToCartError) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(state.error)),
                              );
                            }
                          },
                          builder: (context, state) {
                            if (state is AddingToCart) {
                              return MainButton(
                                child: const CircularProgressIndicator.adaptive(),
                              );
                            }
                            return MainButton(
                              text: 'Add to cart',
                              onTap: () async => await productDetailsCubit.addToCart(product),
                              hasCircularBorder: true,
                            );
                          },
                        ),
                        const SizedBox(height: 32.0),

                        // --- Reviews Section ---
                        const Divider(),
                        Text(
                          'Reviews',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 12.0),
                        if (product.reviews.isEmpty)
                          Text(
                            'No reviews yet.',
                            style: Theme.of(context).textTheme.bodyMedium,
                          )
                        else ...[
                          Row(
                            children: [
                              const Icon(Icons.star, color: Colors.amber),
                              const SizedBox(width: 4),
                              Text('${product.averageRating.toStringAsFixed(1)} / 5'),
                              const SizedBox(width: 8),
                              Text('(${product.reviewCount} reviews)'),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: product.reviews.length,
                            itemBuilder: (context, index) {
                              final review = product.reviews[index];
                              return ListTile(
                                leading: const Icon(Icons.person),
                                title: Text(review.userName),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: List.generate(
                                        5,
                                        (i) => Icon(
                                          i < review.rating
                                              ? Icons.star
                                              : Icons.star_border,
                                          size: 16,
                                          color: Colors.amber,
                                        ),
                                      ),
                                    ),
                                    Text(review.comment),
                                  ],
                                ),
                              );
                            },
                          ),
                        ],
                        const SizedBox(height: 32.0),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        } else {
          return const SizedBox.shrink();
        }
      },
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

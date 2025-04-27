import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_ecommerce/controllers/product_details/product_details_cubit.dart';
import 'package:flutter_ecommerce/views/widgets/drop_down_menu.dart';
import 'package:flutter_ecommerce/views/widgets/main_button.dart';

class ProductDetails extends StatefulWidget {
  const ProductDetails({super.key});

  @override
  State<ProductDetails> createState() => _ProductDetailsState();
}

class _ProductDetailsState extends State<ProductDetails> {
  bool isFavorite = false;
  bool isHovering = false;

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
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              actions: [
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.share),
                ),
              ],
            ),
            body: Stack(
              children: [
                SingleChildScrollView(
                  padding: const EdgeInsets.only(bottom: 80),
                  child: Column(
                    children: [
                      Image.network(
                        product.imgUrl,
                        width: double.infinity,
                        height: size.height * 0.5,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(height: 8.0),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                SizedBox(
                                  width: 140,
                                  height: 50,
                                  child: DropDownMenuComponent(
                                    items: const ['S', 'M', 'L', 'XL', 'XXL'],
                                    hint: 'Size',
                                    onChanged: (String? newValue) =>
                                        productDetailsCubit.setSize(newValue!),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                SizedBox(
                                  width: 140,
                                  height: 50,
                                  child: DropDownMenuComponent(
                                    items: const ['Red', 'Blue', 'Green', 'Black', 'White'],
                                    hint: 'Color',
                                    onChanged: (String? newValue) =>
                                        productDetailsCubit.setColor(newValue!),
                                  ),
                                ),
                                const Spacer(),
                                InkWell(
                                  onTap: () {
                                    setState(() {
                                      isFavorite = !isFavorite;
                                    });
                                  },
                                  child: Container(
                                    height: 50,
                                    width: 50,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.white,
                                    ),
                                    child: Icon(
                                      isFavorite ? Icons.favorite : Icons.favorite_border_outlined,
                                      color: isFavorite ? Colors.redAccent : Colors.black45,
                                      size: 26,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24.0),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    product.title,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context).textTheme.titleLarge!.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                  ),
                                ),
                                const SizedBox(width: 8),
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

                // Nút Add to Cart cố định góc dưới phải + hover hiệu ứng
                Positioned(
                  bottom: 16,
                  right: 16,
                  child: MouseRegion(
                    onEnter: (_) => setState(() => isHovering = true),
                    onExit: (_) => setState(() => isHovering = false),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      transform: isHovering
                          ? (Matrix4.identity()..scale(1.05))
                          : Matrix4.identity(),
                      child: FloatingActionButton.extended(
                        backgroundColor: Colors.red,
                        label: const Text('Add to Cart',style: TextStyle(color: Colors.white)),
                        icon: const Icon(Icons.shopping_cart, color: Colors.white),
                        onPressed: () async {
                          await productDetailsCubit.addToCart(product);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Product added to cart!')),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ],
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

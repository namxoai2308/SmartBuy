import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:flutter_ecommerce/controllers/auth/auth_cubit.dart';
import 'package:flutter_ecommerce/controllers/chat/chat_cubit.dart';
import 'package:flutter_ecommerce/views/pages/chat/chat_seller_target_waiting_page.dart';

import 'package:flutter_ecommerce/controllers/product_details/product_details_cubit.dart';
import 'package:flutter_ecommerce/views/widgets/drop_down_menu.dart';
import 'package:flutter_ecommerce/views/widgets/main_button.dart';
import 'package:flutter_ecommerce/views/widgets/home/related_products_section.dart';
import 'package:flutter_ecommerce/models/home/product.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

import 'package:flutter_ecommerce/controllers/cart/cart_cubit.dart';
// ProductDetails widget displays the detailed view of a selected product.
class ProductDetails extends StatefulWidget {
  final String productId;
  const ProductDetails({super.key, required this.productId});

  @override
  State<ProductDetails> createState() => _ProductDetailsState();
}

class _ProductDetailsState extends State<ProductDetails> {
  bool isFavorite = false;  // Track whether the product is marked as favorite.
  bool isHovering = false;  // Track if the user is hovering over the add to cart button.
  String? selectedSize;  // Selected size of the product.
  String? selectedColor; // Selected color of the product.

  // Initialize the product details after the widget is built.
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final cubit = BlocProvider.of<ProductDetailsCubit>(context);
      cubit.getProductDetails(widget.productId);  // Fetch product details.
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;  // Get screen size for layout adjustments.
    final productDetailsCubit = BlocProvider.of<ProductDetailsCubit>(context);
    final cartCubit = context.read<CartCubit>();

    return BlocBuilder<ProductDetailsCubit, ProductDetailsState>(
      bloc: productDetailsCubit,
      buildWhen: (previous, current) =>
          current is ProductDetailsLoading ||
          current is ProductDetailsLoaded ||
          current is ProductDetailsError,
      builder: (context, state) {
        // Handle loading state
        if (state is ProductDetailsLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator.adaptive()), // Show loading indicator
          );
        } else if (state is ProductDetailsError) {
          return Scaffold(
            body: Center(child: Text(state.error)), // Show error message if fetching fails
          );
        } else if (state is ProductDetailsLoaded) {
          final product = state.product;

          // Return the product details screen after product is successfully loaded
          return Scaffold(
            backgroundColor: Colors.grey[100],
            appBar: AppBar(
              title: Text(
                product.title,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              actions: [
              IconButton(
                    tooltip: 'Chat with Support',
                    onPressed: () {
                        final authState = context.read<AuthCubit>().state;
                        if (authState is! AuthSuccess) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please log in to chat with support.')),
                          );
                          return;
                        }
                        if (authState.user.role.toLowerCase() != 'buyer') {
                           ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Only buyers can initiate support chat.')),
                          );
                          return;
                        }
                        context.read<ChatCubit>().startChatWithAdmin(
                          productIdContext: product.id,
                          productNameContext: product.title,
                          productImageUrlContext: product.imgUrl,
                        );
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const ChatSellerTargetWaitingPage()),
                        );
                    },
                    icon: const Icon(Icons.support_agent_outlined),
                  ),
                IconButton(
                  onPressed: () {},  // Share functionality (currently empty)
                  icon: const Icon(Icons.share),
                ),
              ],
            ),
            body: Stack(
              children: [
                SingleChildScrollView(
                  padding: const EdgeInsets.only(bottom: 80),  // Add padding at the bottom
                  child: Column(
                    children: [
                      Container(
                        width: double.infinity,
                        height: size.height * 0.5,  // Set image height to 50% of screen height
                        color: Colors.white,
                        child: Image.network(
                          product.imgUrl,
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(height: 8.0),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                _buildSelectOptionButton(
                                  label: selectedSize ?? 'Size',
                                  title: 'Select Size',
                                  options: ['S', 'M', 'L', 'XL', 'XXL'],
                                  onSelected: (value) {
                                    setState(() => selectedSize = value);
                                    productDetailsCubit.setSize(value);  // Set selected size
                                  },
                                ),
                                const SizedBox(width: 16),
                                _buildSelectOptionButton(
                                  label: selectedColor ?? 'Color',
                                  title: 'Select Color',
                                  options: ['Red', 'Blue', 'Green', 'Black', 'White'],
                                  onSelected: (value) {
                                    setState(() => selectedColor = value);
                                    productDetailsCubit.setColor(value);  // Set selected color
                                  },
                                ),
                                const Spacer(),
                                InkWell(
                                  onTap: () {
                                    setState(() {
                                      isFavorite = !isFavorite;  // Toggle favorite status
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
                                          fontSize: 24,
                                        ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '\$${product.price}',
                                  style: Theme.of(context).textTheme.titleLarge!.copyWith(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 24,
                                      ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8.0),
                            Text(
                              product.category.isNotEmpty
                                  ? product.category[0].toUpperCase() + product.category.substring(1)
                                  : '',
                              style: Theme.of(context).textTheme.labelMedium!.copyWith(
                                    color: Colors.black54,
                                    fontSize: 14,
                                  ),
                            ),
                            const SizedBox(height: 16.0),
                            if (product.brand != null)
                              _buildInfoRow('Brand', product.brand!, fontSize: 18,),
                            if (product.inStock != null)
                              _buildInfoRow('Availability', product.inStock! ? 'In Stock' : 'Out of Stock', fontSize: 18,),
                            if (product.description != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 12.0),
                                child: Text(
                                  product.description!,
                                  style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                                  fontSize: 18,
                                  ),
                                ),
                              ),
                            const SizedBox(height: 24.0),
                            YouMayAlsoLikeSection(
                              relatedProducts: state.allProducts
                                  .where((p) => product.relatedProductIds.contains(p.id))
                                  .toList(),
                              onProductTapped: (Product tappedProduct) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => BlocProvider(
                                      create: (_) {
                                        final cubit = ProductDetailsCubit();
                                        cubit.getProductDetails(tappedProduct.id);
                                        return cubit;
                                      },
                                      child: ProductDetails(productId: tappedProduct.id),
                                    ),
                                  ),
                                );
                              },
                            ),
                            const Divider(),
                            Text(
                              'Reviews',
                              style: Theme.of(context).textTheme.titleLarge!.copyWith(
                                                                     fontSize: 24,
                                                                     fontWeight: FontWeight.bold,
                                                                   ),
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
                                  return Card(
                                  color: Colors.white,
                                    elevation: 2,
                                    margin: const EdgeInsets.symmetric(vertical: 8),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    child: Padding(
                                      padding: const EdgeInsets.all(12.0),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          CircleAvatar(
                                            radius: 22,
                                            backgroundColor: Colors.grey.shade300,
                                            child: const Icon(Icons.person, color: Colors.white),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  review.userName,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Row(
                                                  children: [
                                                    RatingBarIndicator(
                                                      rating: review.rating.toDouble(),
                                                      itemBuilder: (context, _) => const Icon(
                                                        Icons.star,
                                                        color: Colors.amber,
                                                      ),
                                                      itemCount: 5,
                                                      itemSize: 18.0,
                                                      direction: Axis.horizontal,
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Text(
                                                      '${review.rating}/5',
                                                      style: const TextStyle(color: Colors.black54),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 8),
                                                Text(
                                                  review.comment,
                                                  style: const TextStyle(fontSize: 15),
                                                ),
                                                const SizedBox(height: 6),
                                                Text(
                                                  review.createdAt.toString(),
                                                  style: const TextStyle(
                                                    color: Colors.grey,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
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
                Positioned(
                  bottom: 16,
                  right: 16,
                  child: MouseRegion(
                    onEnter: (_) => setState(() => isHovering = true),
                    onExit: (_) => setState(() => isHovering = false),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      transform: isHovering
                          ? (Matrix4.identity()..scale(1.05))  // Scale button when hovered
                          : Matrix4.identity(),
                      child: FloatingActionButton.extended(
                        backgroundColor: Colors.red,
                        label: const Text('Add to Cart', style: TextStyle(color: Colors.white)),
                        icon: const Icon(Icons.shopping_cart, color: Colors.white),
                        onPressed: () async {
                          // Show message if color or size is not selected
                          if (selectedColor == null || selectedSize == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Please select color and size')),
                            );
                            return;
                          }

                          // Add product to the cart and show confirmation
                          await productDetailsCubit.addToCart(product);

                          cartCubit.getCartItems();
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
          return const SizedBox.shrink();  // Return an empty widget if no state is matched.
        }
      },
    );
  }

  // Helper method to build information rows
  Widget _buildInfoRow(String label, String value, {double fontSize = 14.0}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: fontSize,),
          ),
          Expanded(child: Text(
          value,
          style: TextStyle(
             fontSize: fontSize,
           ),),),
        ],
      ),
    );
  }

  // Helper method to build select option buttons for size and color
  Widget _buildSelectOptionButton({
    required String label,
    required String title,
    required List<String> options,
    required Function(String) onSelected,
  }) {
    return SizedBox(
      width: 165,
      height: 50,
      child: InkWell(
        onTap: () {
          showSelectOptionBottomSheet(
            context: context,
            title: title,
            options: options,
            onSelected: onSelected,
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.centerLeft,
          child: Text(label),
        ),
      ),
    );
  }
}

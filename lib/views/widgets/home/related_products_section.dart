import 'package:flutter/material.dart';
import 'package:flutter_ecommerce/models/product.dart';

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
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 200, // Điều chỉnh theo nhu cầu
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: relatedProducts.length,
              itemBuilder: (context, index) {
                final product = relatedProducts[index];
                return GestureDetector(
                  onTap: () {
                    onProductTapped(product); // Gọi callback khi nhấn vào sản phẩm
                  },
                  child: Card(
                    child: Column(
                      children: [
                        Image.network(
                          product.imgUrl,
                          width: 120,
                          height: 120,
                          fit: BoxFit.cover,
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            product.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

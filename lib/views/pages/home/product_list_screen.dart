import 'package:flutter/material.dart';
import 'package:flutter_ecommerce/models/home/product.dart';
import 'package:flutter_ecommerce/views/widgets/home/list_item_home.dart';

class ProductListScreen extends StatelessWidget {
  final List<Product> products;
  final String title;

  const ProductListScreen({
    Key? key,
    required this.products,
    required this.title,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = theme.appBarTheme.foregroundColor ?? theme.textTheme.titleLarge?.color;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.appBarTheme.backgroundColor,
        centerTitle: true,
        elevation: theme.appBarTheme.elevation ?? 0,
        title: Text(
          title,
          style: TextStyle(color: textColor),
        ),
        iconTheme: IconThemeData(color: textColor),
      ),
      body: products.isEmpty
          ? Center(
              child: Text(
                'No products available',
                style: theme.textTheme.bodyMedium,
              ),
            )
          : GridView.builder(
              padding: const EdgeInsets.all(16.0),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.62,
              ),
              itemCount: products.length,
              itemBuilder: (context, index) {
                return ListItemHome(
                  product: products[index],
                  isNew: true,
                );
              },
            ),
    );
  }
}

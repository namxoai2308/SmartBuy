import 'package:flutter/material.dart';
import 'package:flutter_ecommerce/models/home/product.dart';
import 'package:flutter_ecommerce/services/home_services.dart';

class ManageLocalProductsPage extends StatefulWidget {
  const ManageLocalProductsPage({Key? key}) : super(key: key);

  @override
  State<ManageLocalProductsPage> createState() => _ManageLocalProductsPageState();
}

class _ManageLocalProductsPageState extends State<ManageLocalProductsPage> {
  late Future<List<Product>> _productsFuture;
  final HomeServicesImpl _homeServices = HomeServicesImpl();
  List<Product> _products = [];

  @override
  void initState() {
    super.initState();
    _productsFuture = _homeServices.getAllProducts();
  }

  void _deleteProduct(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirm Delete"),
        content: const Text("Are you sure you want to delete this product?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _products.removeAt(index);
              });
              Navigator.of(context).pop();
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _editProduct(Product product) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(title: const Text('Edit Product')),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Name: ${product.title}'),
                Text('Price: \$${product.price.toStringAsFixed(2)}'),
                Text('Category: ${product.category}'),
                Text('Brand: ${product.brand ?? "None"}'),
                Text('In Stock: ${product.inStock == true ? "Yes" : "No"}'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _addProduct() {
    // Placeholder action
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Add product button pressed')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Products'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.black),
            tooltip: 'Add Product',
            onPressed: _addProduct,
          ),
        ],
      ),
      body: FutureBuilder<List<Product>>(
        future: _productsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator.adaptive());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error loading products: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No products found.'));
          } else {
            _products = snapshot.data!;
            return ListView.builder(
              itemCount: _products.length,
              itemBuilder: (context, index) {
                final product = _products[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 3,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: product.imgUrl.isNotEmpty
                              ? Image.network(
                                  product.imgUrl,
                                  width: 60,
                                  height: 60,
                                  fit: BoxFit.cover,
                                )
                              : const Icon(Icons.image_not_supported, size: 60, color: Colors.grey),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(product.title,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  )),
                              const SizedBox(height: 4),
                              Text('Price: \$${product.price.toStringAsFixed(2)}'),
                              Text('Category: ${product.category}'),
                              if (product.brand != null) Text('Brand: ${product.brand}'),
                              Text('In Stock: ${product.inStock == true ? "Yes" : "No"}'),
                            ],
                          ),
                        ),
                        Column(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.grey),
                              onPressed: () => _editProduct(product),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.grey),
                              onPressed: () => _deleteProduct(index),
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }
}
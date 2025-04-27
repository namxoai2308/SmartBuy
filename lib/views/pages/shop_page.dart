import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_ecommerce/controllers/home/home_cubit.dart';
import 'package:flutter_ecommerce/models/product.dart';
import 'package:flutter_ecommerce/views/widgets/list_item_home.dart';

class ShopPage extends StatefulWidget {
  const ShopPage({Key? key}) : super(key: key);

  @override
  State<ShopPage> createState() => _ShopPageState();
}

class _ShopPageState extends State<ShopPage> {
  bool isSearching = false;
  String searchQuery = '';
  final TextEditingController searchController = TextEditingController();

  String selectedCategory = 'All'; // Lọc theo danh mục
  bool sortAscending = true; // Điều chỉnh sắp xếp giá

  // Danh sách các category giả định
  List<String> categories = ['All', 'Clothing', 'Shoes', 'Jewelry'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: isSearching
            ? TextField(
                controller: searchController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Search...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      setState(() {
                        searchQuery = '';
                        searchController.clear();
                        isSearching = false;
                      });
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    searchQuery = value;
                  });
                },
              )
            : const Text(
                '',
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
        actions: [
          IconButton(
            icon: Icon(
              isSearching ? Icons.cancel : Icons.search,
              color: Colors.black,
              size: 28,
            ),
            onPressed: () {
              setState(() {
                isSearching = !isSearching;
                if (!isSearching) {
                  searchQuery = '';
                  searchController.clear();
                }
              });
            },
          ),
        ],
        centerTitle: false,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Move "My Shop" text here
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              'My Shop',
              style: TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Filters + Price
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.menu),
                  onPressed: () {
                    // Hiển thị danh sách danh mục khi người dùng nhấn vào menu
                    showModalBottomSheet(
                      context: context,
                      builder: (context) {
                        return ListView(
                          children: categories.map((category) {
                            return ListTile(
                              title: Text(category),
                              onTap: () {
                                setState(() {
                                  selectedCategory = category;
                                });
                                Navigator.pop(context);
                              },
                            );
                          }).toList(),
                        );
                      },
                    );
                  },
                ),
                const SizedBox(width: 8),
                Text(
                  'Filters: $selectedCategory',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.swap_vert),
                  onPressed: () {
                    setState(() {
                      sortAscending = !sortAscending;
                    });
                  },
                ),
                const SizedBox(width: 4),
                Text(
                  'Price: ${sortAscending ? 'lowest to high' : 'high to lowest'}',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Products Grid
          Expanded(
            child: BlocBuilder<HomeCubit, HomeState>(
              builder: (context, state) {
                if (state is HomeLoading) {
                  return const Center(child: CircularProgressIndicator());
                } else if (state is HomeSuccess) {
                  final allProducts = state.allProducts;

                  // Lọc sản phẩm theo tìm kiếm
                  final filteredProducts = allProducts
                      .where((product) => product.title
                          .toLowerCase()
                          .contains(searchQuery.toLowerCase()) &&
                          (selectedCategory == 'All' ||
                              product.category == selectedCategory))
                      .toList();

                  // Sắp xếp sản phẩm theo giá
                  filteredProducts.sort((a, b) {
                    final priceA = a.price ?? 0.0;
                    final priceB = b.price ?? 0.0;
                    return sortAscending
                        ? priceA.compareTo(priceB)
                        : priceB.compareTo(priceA);
                  });

                  if (filteredProducts.isEmpty) {
                    return const Center(child: Text('No products available'));
                  }

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0),
                    child: GridView.builder(
                      padding: const EdgeInsets.only(top: 8),
                      itemCount: filteredProducts.length,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 24,
                        childAspectRatio: 0.58,
                      ),
                      itemBuilder: (context, index) {
                        final product = filteredProducts[index];
                        return Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: ListItemHome(
                            product: product,
                            isNew: false,
                            addToFavorites: () {
                              // logic yêu thích
                            },
                          ),
                        );
                      },
                    ),
                  );
                } else if (state is HomeFailed) {
                  return Center(child: Text('Error: ${state.error}'));
                } else {
                  return const SizedBox.shrink();
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

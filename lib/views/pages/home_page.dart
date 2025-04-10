import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_ecommerce/controllers/home/home_cubit.dart';
import 'package:flutter_ecommerce/utilities/assets.dart';
import 'package:flutter_ecommerce/views/widgets/header_of_list.dart';
import 'package:flutter_ecommerce/views/widgets/list_item_home.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool isSearching = false;
  String searchQuery = '';
  final TextEditingController searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final homeCubit = BlocProvider.of<HomeCubit>(context);

    return SafeArea(
      top: false,
      child: BlocBuilder<HomeCubit, HomeState>(
        bloc: homeCubit,
        buildWhen: (previous, current) =>
            current is HomeSuccess ||
            current is HomeLoading ||
            current is HomeFailed,
        builder: (context, state) {
          if (state is HomeLoading) {
            return const Center(child: CircularProgressIndicator.adaptive());
          } else if (state is HomeFailed) {
            return Center(child: Text(state.error));
          } else if (state is HomeSuccess) {
            final salesProducts = state.salesProducts;
            final newProducts = state.newProducts;

            // Áp dụng tìm kiếm nếu có query
            final filteredSales = salesProducts
                .where((p) => p.title.toLowerCase().contains(searchQuery.toLowerCase()))
                .toList();
            final filteredNew = newProducts
                .where((p) => p.title.toLowerCase().contains(searchQuery.toLowerCase()))
                .toList();

            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Banner
                  Stack(
                    alignment: Alignment.bottomLeft,
                    children: [
                      Image.network(
                        AppAssets.topBannerHomePageAsset,
                        width: double.infinity,
                        height: size.height * 0.3,
                        fit: BoxFit.cover,
                      ),
                      Opacity(
                        opacity: 0.3,
                        child: Container(
                          width: double.infinity,
                          height: size.height * 0.3,
                          color: Colors.black,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24.0,
                          vertical: 16.0,
                        ),
                        child: Text(
                          'Street Clothes',
                          style: Theme.of(context).textTheme.titleLarge!.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // 🔍 Thanh tìm kiếm (ẩn hiện)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Row(
                      children: [
                        if (isSearching)
                          Expanded(
                            child: TextField(
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
                            ),
                          )
                        else
                          Expanded(
                            child: Text(
                              '',
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                          ),
                        const SizedBox(width: 12),
                        if (!isSearching)
                          IconButton(
                            icon: const Icon(Icons.search),
                            onPressed: () {
                              setState(() {
                                isSearching = true;
                              });
                            },
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24.0),

                  // Danh sách Sale
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      children: [
                        HeaderOfList(
                          onTap: () {},
                          title: 'Sale',
                          description: 'Super Summer Sale!!',
                        ),
                        const SizedBox(height: 8.0),
                        SizedBox(
                          height: 330,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: filteredSales.length,
                            itemBuilder: (_, int index) => Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: ListItemHome(
                                product: filteredSales[index],
                                isNew: true,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12.0),

                        // Danh sách New
                        HeaderOfList(
                          onTap: () {},
                          title: 'New',
                          description: 'Super New Products!!',
                        ),
                        const SizedBox(height: 8.0),
                        SizedBox(
                          height: 330,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: filteredNew.length,
                            itemBuilder: (_, int index) => Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: ListItemHome(
                                product: filteredNew[index],
                                isNew: true,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          } else {
            return const SizedBox.shrink();
          }
        },
      ),
    );
  }
}

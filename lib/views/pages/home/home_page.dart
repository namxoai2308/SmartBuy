import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_ecommerce/controllers/home/home_cubit.dart';
import 'package:flutter_ecommerce/utilities/assets.dart';
import 'package:flutter_ecommerce/views/widgets/home/header_of_list.dart';
import 'package:flutter_ecommerce/views/widgets/home/list_item_home.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter_ecommerce/views/widgets/home/banner.dart';
import 'package:flutter_ecommerce/views/pages/home/product_list_screen.dart';


class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

void navigateWithSlide(BuildContext context, Widget page) {
  Navigator.push(
    context,
    PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.ease;
        var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
        var offsetAnimation = animation.drive(tween);

        return SlideTransition(
          position: offsetAnimation,
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 300),
    ),
  );
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
            final recommendedProducts = state.recommendedProducts;

            // Áp dụng tìm kiếm nếu có query
            final filteredSales = salesProducts
                .where((p) => p.title.toLowerCase().contains(searchQuery.toLowerCase()))
                .toList();
            final filteredNew = newProducts
                .where((p) => p.title.toLowerCase().contains(searchQuery.toLowerCase()))
                .toList();
            final filteredRecommended = recommendedProducts
                .where((p) => p.title.toLowerCase().contains(searchQuery.toLowerCase()))
                .toList();

            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Banner
                  const BannerSlider(),
                  const SizedBox(height: 30.0),

                  // Suggested for You
                  if (filteredRecommended.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Column(
                        children: [
                          HeaderOfList(
                            onTap: () {
                              navigateWithSlide(
                                    context,
                                    ProductListScreen(
                                      title: 'Suggested for You',
                                      products: filteredRecommended,
                                    ),
                                  );
                            },
                            title: 'Suggested for You',
                            description: 'Products you may like!',
                          ),
                          const SizedBox(height: 8.0),
                          SizedBox(
                            height: 330,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: filteredRecommended.length,
                              itemBuilder: (_, int index) => Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: ListItemHome(
                                  product: filteredRecommended[index],
                                  isNew: true,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20.0),
                        ],
                      ),
                    ),
                  ],

                  // Danh sách Sale
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      children: [
                        HeaderOfList(
                          onTap: () {
                            navigateWithSlide(
                              context,
                              ProductListScreen(
                                title: 'Sale',
                                products: filteredSales,
                              ),
                            );
                          },
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
                                isNew: false,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20.0),
                      ],
                    ),
                  ),

                  // Danh sách New
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      children: [
                        HeaderOfList(
                          onTap: () {
                            navigateWithSlide(
                              context,
                              ProductListScreen(
                                title: 'New',
                                products: filteredNew,
                              ),
                            );
                          },
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

import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_ecommerce/utilities/assets.dart';

class BannerSlider extends StatefulWidget {
  const BannerSlider({super.key});

  @override
  State<BannerSlider> createState() => _BannerSliderState();
}

class _BannerSliderState extends State<BannerSlider> {
  int _current = 0;

  final List<Map<String, String>> banners = [
    {
      'image': AppAssets.topBannerHomePageAsset1,
      'title': 'Street Clothes',
    },
    {
      'image': AppAssets.topBannerHomePageAsset2,
      'title': 'Fashion Sale',
    },
    {
      'image': AppAssets.topBannerHomePageAsset3,
      'title': 'Summer Sale',
    },
    {
      'image': AppAssets.topBannerHomePageAsset4,
      'title': 'Trending',
    },
    {
      'image': AppAssets.topBannerHomePageAsset5,
      'title': 'New Collection!',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      children: [
        CarouselSlider.builder(
          itemCount: banners.length,
          options: CarouselOptions(
            height: size.height * 0.3,
            autoPlay: true,
            autoPlayInterval: const Duration(seconds: 5),
            viewportFraction: 1.0,
            onPageChanged: (index, reason) {
              setState(() {
                _current = index;
              });
            },
            enlargeCenterPage: false,
            scrollPhysics: const BouncingScrollPhysics(),
            pageSnapping: true,
          ),
          itemBuilder: (context, index, realIndex) {
            return AnimatedSwitcher(
              duration: const Duration(milliseconds: 500),
              child: Container(
                key: ValueKey<String>(banners[index]['image']!),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      banners[index]['image']!,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return const Center(child: CircularProgressIndicator.adaptive());
                      },
                      errorBuilder: (context, error, stackTrace) =>
                          const Center(child: Icon(Icons.error)),
                    ),
                    Container(
                      color: Colors.black.withOpacity(0.3),
                    ),
                  ],
                ),
              ),
            );
          },
        ),

        // Title
        Positioned(
          bottom: 30.0,
          left: 24.0,
          child: Text(
            banners[_current]['title'] ?? '',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 34.0,
                ),
          ),
        ),

        // Indicator
        Positioned(
          bottom: 16.0,
          left: 0,
          right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: banners.asMap().entries.map((entry) {
              return Container(
                width: _current == entry.key ? 10.0 : 8.0,
                height: _current == entry.key ? 10.0 : 8.0,
                margin: const EdgeInsets.symmetric(horizontal: 4.0),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _current == entry.key
                      ? (isDark ? Colors.white : Colors.black)
                      : (isDark ? Colors.white.withOpacity(0.4) : Colors.black.withOpacity(0.4)),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

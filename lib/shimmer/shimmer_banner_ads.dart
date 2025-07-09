import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class ShimmerBannerAds extends StatelessWidget {
  const ShimmerBannerAds({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: Colors.black, width: 1)),
          color: Colors.white,
        ),
        child: Shimmer.fromColors(
          period: const Duration(milliseconds: 500),
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.white,
          child: ContentPlaceholder(50),
        ),
      ),
    );
  }
}

class ContentPlaceholder extends StatelessWidget {
  const ContentPlaceholder(this.height, {Key? key}) : super(key: key);

  final double height;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      height: 10.0,
                      color: Colors.white,
                      margin: const EdgeInsets.only(bottom: 8.0),
                    ),
                    Container(
                      width: double.infinity,
                      height: 10.0,
                      color: Colors.white,
                      margin: const EdgeInsets.only(bottom: 8.0),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12.0),
              Container(
                clipBehavior: Clip.hardEdge,
                width: 50.0,
                height: 30.0,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

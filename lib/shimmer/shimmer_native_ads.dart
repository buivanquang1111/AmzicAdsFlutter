import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class ShimmerNativeAds extends StatelessWidget {
  final double height;

  const ShimmerNativeAds({super.key, required this.height});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), color: Colors.white),
        child: Shimmer.fromColors(
          period: const Duration(milliseconds: 500),
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.white,
          child: ContentPlaceholder(height),
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
          Container(
            width: double.infinity,
            height: 120,
            color: Colors.white,
            margin: const EdgeInsets.only(bottom: 8.0),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                clipBehavior: Clip.hardEdge,
                width: 50.0,
                height: 30.0,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              const SizedBox(width: 12.0),
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
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            height: 48,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), color: Colors.white),
          ),
        ],
      ),
    );
  }
}

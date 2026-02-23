import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class RepoSkeleton extends StatelessWidget {
  const RepoSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Container(
        padding: const EdgeInsets.all(6), // Smaller padding
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(6), // Smaller radius
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min, // Important: wrap content
          children: [
            // Title
            Container(height: 11, width: 110, color: Colors.grey),
            const SizedBox(height: 4),

            // Description line 1
            Container(height: 8, width: double.infinity, color: Colors.grey),
            const SizedBox(height: 3),

            // Description line 2
            Container(height: 8, width: 150, color: Colors.grey),
            const SizedBox(height: 5),

            // Bottom row
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(height: 7, width: 40, color: Colors.grey),
                const SizedBox(width: 6),
                Container(height: 7, width: 28, color: Colors.grey),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

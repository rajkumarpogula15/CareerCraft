import 'package:flutter/material.dart';

import 'app_skeleton.dart';

class RepoSkeleton extends StatelessWidget {
  const RepoSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return AppSkeleton(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SkeletonBox(width: 120, height: 12),
            SizedBox(height: 8),
            SkeletonBox(width: double.infinity, height: 8),
            SizedBox(height: 6),
            SkeletonBox(width: 170, height: 8),
            SizedBox(height: 10),
            Row(
              children: [
                SkeletonBox(width: 44, height: 8),
                SizedBox(width: 8),
                SkeletonBox(width: 32, height: 8),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

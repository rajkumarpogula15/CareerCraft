import 'package:flutter/material.dart';

import 'app_skeleton.dart';

class SectionSkeleton extends StatelessWidget {
  final int count;
  final double itemHeight;

  const SectionSkeleton({
    super.key,
    this.count = 3,
    this.itemHeight = 84,
  });

  @override
  Widget build(BuildContext context) {
    return AppSkeleton(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        child: Column(
          children: List.generate(
            count,
            (_) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Container(
                height: itemHeight,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

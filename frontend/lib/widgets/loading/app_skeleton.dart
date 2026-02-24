import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class AppSkeleton extends StatelessWidget {
  final Widget child;

  const AppSkeleton({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Shimmer.fromColors(
      baseColor: scheme.surfaceContainerHighest,
      highlightColor: scheme.surfaceContainerLow,
      period: const Duration(milliseconds: 1200),
      child: child,
    );
  }
}

class SkeletonBox extends StatelessWidget {
  final double width;
  final double height;
  final BorderRadiusGeometry? borderRadius;

  const SkeletonBox({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: borderRadius ?? BorderRadius.circular(8),
      ),
    );
  }
}

class CardListSkeleton extends StatelessWidget {
  final int itemCount;
  final double itemHeight;

  const CardListSkeleton({
    super.key,
    this.itemCount = 4,
    this.itemHeight = 90,
  });

  @override
  Widget build(BuildContext context) {
    return AppSkeleton(
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: itemCount,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (_, _) => Container(
          height: itemHeight,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}

class ProfileSkeleton extends StatelessWidget {
  const ProfileSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return AppSkeleton(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 24),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Column(
                children: [
                  SkeletonBox(width: 96, height: 96, borderRadius: BorderRadius.all(Radius.circular(48))),
                  SizedBox(height: 12),
                  SkeletonBox(width: 180, height: 18),
                  SizedBox(height: 8),
                  SkeletonBox(width: 140, height: 14),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: const [
                Expanded(child: SkeletonBox(width: double.infinity, height: 88)),
                SizedBox(width: 12),
                Expanded(child: SkeletonBox(width: double.infinity, height: 88)),
                SizedBox(width: 12),
                Expanded(child: SkeletonBox(width: double.infinity, height: 88)),
              ],
            ),
            const SizedBox(height: 20),
            const SkeletonBox(width: double.infinity, height: 48),
            const SizedBox(height: 10),
            const SkeletonBox(width: double.infinity, height: 48),
          ],
        ),
      ),
    );
  }
}

class ChatScreenSkeleton extends StatelessWidget {
  const ChatScreenSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return AppSkeleton(
      child: Column(
        children: [
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: 7,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (_, index) {
                final isUser = index.isEven;
                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: SkeletonBox(
                    width: isUser ? 180 : 240,
                    height: isUser ? 46 : 62,
                    borderRadius: BorderRadius.circular(14),
                  ),
                );
              },
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(12, 8, 12, 12),
            child: SkeletonBox(width: double.infinity, height: 52, borderRadius: BorderRadius.all(Radius.circular(12))),
          ),
        ],
      ),
    );
  }
}

class FormSectionSkeleton extends StatelessWidget {
  const FormSectionSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return AppSkeleton(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          SkeletonBox(width: 180, height: 20),
          SizedBox(height: 12),
          SkeletonBox(width: double.infinity, height: 48),
          SizedBox(height: 10),
          SkeletonBox(width: double.infinity, height: 48),
          SizedBox(height: 10),
          SkeletonBox(width: double.infinity, height: 48),
          SizedBox(height: 20),
          SkeletonBox(width: 120, height: 20),
          SizedBox(height: 12),
          SkeletonBox(width: double.infinity, height: 100),
          SizedBox(height: 12),
          SkeletonBox(width: double.infinity, height: 100),
        ],
      ),
    );
  }
}

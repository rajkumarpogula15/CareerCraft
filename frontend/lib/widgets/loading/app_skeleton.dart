import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class AppSkeleton extends StatelessWidget {
  final Widget child;

  const AppSkeleton({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Shimmer.fromColors(
      baseColor: isDark
          ? scheme.surfaceContainerHigh
          : scheme.surfaceContainerHighest,
      highlightColor: isDark ? scheme.surfaceContainer : scheme.surface,
      period: const Duration(milliseconds: 1200),
      direction: ShimmerDirection.ltr,
      child: child,
    );
  }
}

class SkeletonBox extends StatelessWidget {
  final double? width;
  final double height;
  final BorderRadiusGeometry? borderRadius;
  final BoxShape shape;

  const SkeletonBox({
    super.key,
    this.width,
    required this.height,
    this.borderRadius,
    this.shape = BoxShape.rectangle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        shape: shape,
        borderRadius: shape == BoxShape.circle
            ? null
            : borderRadius ?? BorderRadius.circular(8),
      ),
    );
  }
}

class TextSkeleton extends StatelessWidget {
  final double? width;
  final double height;
  final EdgeInsetsGeometry margin;

  const TextSkeleton({
    super.key,
    this.width,
    this.height = 14,
    this.margin = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: margin,
      child: SkeletonBox(
        width: width,
        height: height,
        borderRadius: BorderRadius.circular(height / 2),
      ),
    );
  }
}

class AvatarSkeleton extends StatelessWidget {
  final double size;

  const AvatarSkeleton({super.key, this.size = 40});

  @override
  Widget build(BuildContext context) {
    return SkeletonBox(width: size, height: size, shape: BoxShape.circle);
  }
}

class SkeletonPill extends StatelessWidget {
  final double width;
  final double height;

  const SkeletonPill({
    super.key,
    required this.width,
    this.height = 28,
  });

  @override
  Widget build(BuildContext context) {
    return SkeletonBox(
      width: width,
      height: height,
      borderRadius: BorderRadius.circular(999),
    );
  }
}

class SkeletonSectionTitle extends StatelessWidget {
  final double width;

  const SkeletonSectionTitle({super.key, this.width = 170});

  @override
  Widget build(BuildContext context) {
    return TextSkeleton(width: width, height: 18);
  }
}

class RepoCardSkeleton extends StatelessWidget {
  final bool expanded;

  const RepoCardSkeleton({super.key, this.expanded = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: theme.dividerColor.withValues(alpha: 0.4),
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: const [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextSkeleton(width: 150, height: 18),
                      SizedBox(height: 6),
                      TextSkeleton(height: 12),
                    ],
                  ),
                ),
                SizedBox(width: 8),
                SkeletonBox(width: 18, height: 18),
                SizedBox(width: 4),
                SkeletonBox(width: 22, height: 22),
              ],
            ),
            if (expanded) ...const [
              SizedBox(height: 14),
              _ActionRowSkeleton(),
              _ActionRowSkeleton(),
              _ActionRowSkeleton(),
              _ActionRowSkeleton(),
            ],
          ],
        ),
      ),
    );
  }
}

class _ActionRowSkeleton extends StatelessWidget {
  const _ActionRowSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          SkeletonBox(width: 20, height: 20),
          SizedBox(width: 12),
          Expanded(child: TextSkeleton(height: 14)),
        ],
      ),
    );
  }
}

class ActivityCardSkeleton extends StatelessWidget {
  const ActivityCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0.5,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            SkeletonBox(width: 20, height: 20),
            SizedBox(width: 12),
            Expanded(child: TextSkeleton(height: 14)),
          ],
        ),
      ),
    );
  }
}

class ContinueSessionSkeleton extends StatelessWidget {
  const ContinueSessionSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SkeletonSectionTitle(width: 220),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceVariant.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(24),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonBox(
                    width: 42,
                    height: 42,
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextSkeleton(width: 120, height: 18),
                        SizedBox(height: 6),
                        TextSkeleton(width: 90, height: 12),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              TextSkeleton(height: 14),
              SizedBox(height: 20),
              SkeletonBox(
                height: 36,
                borderRadius: BorderRadius.all(Radius.circular(14)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class SuggestionSectionSkeleton extends StatelessWidget {
  const SuggestionSectionSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        SkeletonSectionTitle(width: 180),
        SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: PrimaryActionSkeleton()),
            SizedBox(width: 8),
            Expanded(child: PrimaryActionSkeleton()),
          ],
        ),
        SizedBox(height: 12),
        SkeletonSectionTitle(width: 160),
        SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            SuggestionChipSkeleton(width: 220),
            SuggestionChipSkeleton(width: 190),
            SuggestionChipSkeleton(width: 240),
          ],
        ),
        SizedBox(height: 8),
        SkeletonBox(height: 1),
      ],
    );
  }
}

class PrimaryActionSkeleton extends StatelessWidget {
  const PrimaryActionSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: theme.colorScheme.primaryContainer,
      borderRadius: BorderRadius.circular(14),
      elevation: 1,
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Row(
          children: [
            SkeletonBox(
              width: 36,
              height: 36,
              borderRadius: BorderRadius.all(Radius.circular(10)),
            ),
            SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: TextSkeleton(width: 90, height: 16)),
                      SizedBox(width: 8),
                      SkeletonPill(width: 82, height: 20),
                    ],
                  ),
                  SizedBox(height: 6),
                  TextSkeleton(height: 12),
                  SizedBox(height: 4),
                  TextSkeleton(width: 120, height: 12),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SuggestionChipSkeleton extends StatelessWidget {
  final double width;

  const SuggestionChipSkeleton({
    super.key,
    required this.width,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SkeletonBox(width: 16, height: 16),
          SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextSkeleton(height: 12),
                SizedBox(height: 4),
                TextSkeleton(width: 110, height: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class HomeHeaderSkeleton extends StatelessWidget {
  const HomeHeaderSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            AvatarSkeleton(size: 44),
            SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextSkeleton(width: 170, height: 18),
                  SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      SkeletonPill(width: 110, height: 26),
                      SkeletonPill(width: 118, height: 26),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(width: 4),
            SkeletonBox(width: 20, height: 20),
          ],
        ),
      ),
    );
  }
}

class HomeFooterSkeleton extends StatelessWidget {
  const HomeFooterSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(2),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: const Column(
          children: [
            TextSkeleton(width: 120, height: 24),
            SizedBox(height: 8),
            TextSkeleton(width: 190, height: 14),
            SizedBox(height: 16),
            Wrap(
              spacing: 20,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: [
                SkeletonPill(width: 62, height: 20),
                SkeletonPill(width: 54, height: 20),
                SkeletonPill(width: 48, height: 20),
                SkeletonPill(width: 78, height: 20),
                SkeletonPill(width: 42, height: 20),
              ],
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SkeletonBox(width: 18, height: 18),
                SizedBox(width: 16),
                SkeletonBox(width: 18, height: 18),
                SizedBox(width: 16),
                SkeletonBox(width: 18, height: 18),
                SizedBox(width: 16),
                SkeletonBox(width: 18, height: 18),
              ],
            ),
            SizedBox(height: 12),
            SkeletonBox(height: 1),
            SizedBox(height: 8),
            TextSkeleton(width: 150, height: 12),
          ],
        ),
      ),
    );
  }
}

class WorkspaceSkeleton extends StatelessWidget {
  const WorkspaceSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SkeletonSectionTitle(width: 176),
        SizedBox(height: 8),
        RepoCardSkeleton(),
        RepoCardSkeleton(),
        RepoCardSkeleton(),
        SizedBox(height: 2),
        SkeletonSectionTitle(width: 126),
        SizedBox(height: 8),
        ActivityCardSkeleton(),
        ActivityCardSkeleton(),
        SizedBox(height: 2),
      ],
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
        itemBuilder: (_, __) => Container(
          height: itemHeight,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                SkeletonBox(
                  width: 24,
                  height: 24,
                  borderRadius: BorderRadius.all(Radius.circular(8)),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextSkeleton(width: 180, height: 16),
                      SizedBox(height: 8),
                      TextSkeleton(height: 12),
                      SizedBox(height: 4),
                      TextSkeleton(width: 120, height: 12),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ReposScreenSkeleton extends StatelessWidget {
  const ReposScreenSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final columns = width >= 1240 ? 3 : width >= 760 ? 2 : 1;
        final horizontal = width >= 760 ? 20.0 : 16.0;

        return AppSkeleton(
          child: CustomScrollView(
            slivers: [
              const SliverAppBar(
                pinned: true,
                elevation: 0,
                title: TextSkeleton(width: 120, height: 18),
              ),
              SliverPadding(
                padding: EdgeInsets.fromLTRB(horizontal, 8, horizontal, 18),
                sliver: SliverToBoxAdapter(
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: List.generate(
                      columns == 1 ? 6 : 9,
                      (_) => SizedBox(
                        width: columns == 1
                            ? constraints.maxWidth - (horizontal * 2)
                            : ((constraints.maxWidth -
                                        (horizontal * 2) -
                                        (12 * (columns - 1))) /
                                    columns),
                        child: const RepoCardSkeleton(),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class HomeLoggedInSkeleton extends StatelessWidget {
  const HomeLoggedInSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return AppSkeleton(
      child: const SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(4, 8, 4, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            HomeHeaderSkeleton(),
            SizedBox(height: 10),
            SuggestionSectionSkeleton(),
            SizedBox(height: 10),
            ContinueSessionSkeleton(),
            SizedBox(height: 8),
            WorkspaceSkeleton(),
            HomeFooterSkeleton(),
          ],
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
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 16, horizontal: 14),
              child: Column(
                children: [
                  AvatarSkeleton(size: 80),
                  SizedBox(height: 10),
                  TextSkeleton(width: 140, height: 22),
                  SizedBox(height: 8),
                  TextSkeleton(width: 90, height: 14),
                  SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      SkeletonPill(width: 116, height: 28),
                      SkeletonPill(width: 124, height: 28),
                    ],
                  ),
                  SizedBox(height: 10),
                  SkeletonBox(
                    width: 154,
                    height: 40,
                    borderRadius: BorderRadius.all(Radius.circular(20)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          const SkeletonBox(
            height: 48,
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
          const SizedBox(height: 12),
          const Row(
            children: [
              Expanded(child: _ProfileStatSkeleton()),
              SizedBox(width: 10),
              Expanded(child: _ProfileStatSkeleton()),
              SizedBox(width: 10),
              Expanded(child: _ProfileStatSkeleton()),
            ],
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const TextSkeleton(width: 150, height: 18),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: List.generate(
                      35,
                      (_) => SkeletonBox(
                        width: 18,
                        height: 18,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const TextSkeleton(width: 170, height: 12),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: const Padding(
              padding: EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextSkeleton(width: 130, height: 18),
                  SizedBox(height: 12),
                  TextSkeleton(height: 14),
                  SizedBox(height: 8),
                  TextSkeleton(width: 220, height: 14),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Align(
            child: SkeletonBox(
              width: 110,
              height: 36,
              borderRadius: BorderRadius.all(Radius.circular(18)),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileStatSkeleton extends StatelessWidget {
  const _ProfileStatSkeleton();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        child: Column(
          children: [
            SkeletonBox(width: 20, height: 20),
            SizedBox(height: 8),
            TextSkeleton(width: 26, height: 18),
            SizedBox(height: 4),
            TextSkeleton(width: 60, height: 12),
          ],
        ),
      ),
    );
  }
}

class ChatBubbleSkeleton extends StatelessWidget {
  final bool isUser;
  final bool hasCodeBlock;
  final double? width;

  const ChatBubbleSkeleton({
    super.key,
    required this.isUser,
    this.hasCodeBlock = false,
    this.width,
  });

  BorderRadius _radius() {
    return BorderRadius.only(
      topLeft: const Radius.circular(18),
      topRight: const Radius.circular(18),
      bottomLeft: isUser ? const Radius.circular(18) : const Radius.circular(4),
      bottomRight: isUser ? const Radius.circular(4) : const Radius.circular(18),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: Container(
          width: width,
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
          decoration: BoxDecoration(
            color: isUser
                ? theme.colorScheme.primaryContainer
                : theme.colorScheme.surfaceContainerLow,
            borderRadius: _radius(),
            boxShadow: [
              BoxShadow(
                color: theme.shadowColor.withValues(alpha: 0.05),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const TextSkeleton(height: 14),
              const SizedBox(height: 6),
              const TextSkeleton(width: 180, height: 14),
              if (hasCodeBlock) ...const [
                SizedBox(height: 12),
                CodeBlockSkeleton(),
              ],
              if (!isUser) ...const [
                SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: SkeletonPill(width: 112, height: 28),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class CodeBlockSkeleton extends StatelessWidget {
  const CodeBlockSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextSkeleton(width: 210, height: 12),
            SizedBox(height: 6),
            TextSkeleton(width: 250, height: 12),
            SizedBox(height: 6),
            TextSkeleton(width: 180, height: 12),
            SizedBox(height: 6),
            TextSkeleton(width: 225, height: 12),
          ],
        ),
      ),
    );
  }
}

class ChatComposerSkeleton extends StatelessWidget {
  const ChatComposerSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
        decoration: BoxDecoration(
          color: colorScheme.surface.withValues(alpha: 0.94),
          border: Border(
            top: BorderSide(
              color: colorScheme.outlineVariant.withValues(alpha: 0.35),
            ),
          ),
          boxShadow: [
            BoxShadow(
              blurRadius: 18,
              offset: const Offset(0, -6),
              color: colorScheme.shadow.withValues(alpha: 0.08),
            ),
          ],
        ),
        child: const Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: SkeletonBox(
                height: 52,
                borderRadius: BorderRadius.all(Radius.circular(24)),
              ),
            ),
            SizedBox(width: 10),
            SkeletonBox(width: 48, height: 48, shape: BoxShape.circle),
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            colorScheme.surface,
            colorScheme.surfaceContainerLowest,
            isDark
                ? colorScheme.surfaceContainerLow
                : colorScheme.primary.withValues(alpha: 0.05),
          ],
        ),
      ),
      child: AppSkeleton(
        child: SafeArea(
          child: Column(
            children: const [
              Expanded(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(16, 20, 16, 24),
                  child: Column(
                    children: [
                      Padding(
                        padding: EdgeInsets.only(left: 4, right: 40),
                        child: ChatBubbleSkeleton(
                          isUser: false,
                          hasCodeBlock: true,
                        ),
                      ),
                      SizedBox(height: 12),
                      Padding(
                        padding: EdgeInsets.only(left: 40, right: 4),
                        child: ChatBubbleSkeleton(isUser: true, width: 220),
                      ),
                      SizedBox(height: 12),
                      Padding(
                        padding: EdgeInsets.only(left: 4, right: 40),
                        child: ChatBubbleSkeleton(isUser: false, width: 280),
                      ),
                      SizedBox(height: 12),
                      Padding(
                        padding: EdgeInsets.only(left: 40, right: 4),
                        child: ChatBubbleSkeleton(isUser: true, width: 170),
                      ),
                    ],
                  ),
                ),
              ),
              ChatComposerSkeleton(),
            ],
          ),
        ),
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
          SkeletonSectionTitle(width: 110),
          SizedBox(height: 12),
          _FieldSkeleton(),
          _FieldSkeleton(),
          _FieldSkeleton(),
          _FieldSkeleton(),
          SizedBox(height: 12),
          SkeletonSectionTitle(width: 170),
          SizedBox(height: 12),
          SkeletonBox(
            height: 104,
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
          SizedBox(height: 16),
          SkeletonSectionTitle(width: 70),
          SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              SkeletonPill(width: 92, height: 32),
              SkeletonPill(width: 74, height: 32),
              SkeletonPill(width: 82, height: 32),
            ],
          ),
          SizedBox(height: 12),
          SkeletonBox(
            height: 48,
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
          SizedBox(height: 16),
          SkeletonSectionTitle(width: 102),
          SizedBox(height: 12),
          _FormCardSkeleton(),
          SizedBox(height: 12),
          SkeletonBox(
            height: 40,
            borderRadius: BorderRadius.all(Radius.circular(18)),
          ),
          SizedBox(height: 16),
          SkeletonSectionTitle(width: 66),
          SizedBox(height: 12),
          RepoCardSkeleton(expanded: true),
          RepoCardSkeleton(),
        ],
      ),
    );
  }
}

class _FieldSkeleton extends StatelessWidget {
  const _FieldSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextSkeleton(width: 90, height: 12),
          SizedBox(height: 8),
          SkeletonBox(
            height: 48,
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
        ],
      ),
    );
  }
}

class _FormCardSkeleton extends StatelessWidget {
  const _FormCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: const [
            _FieldSkeleton(),
            _FieldSkeleton(),
            _FieldSkeleton(),
          ],
        ),
      ),
    );
  }
}

class SheetPreviewSkeleton extends StatelessWidget {
  final bool showHandle;
  final bool showCloseButton;
  final bool showDualActions;

  const SheetPreviewSkeleton({
    super.key,
    this.showHandle = false,
    this.showCloseButton = true,
    this.showDualActions = false,
  });

  @override
  Widget build(BuildContext context) {
    return AppSkeleton(
      child: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            children: [
              if (showHandle) ...const [
                SkeletonBox(
                  width: 40,
                  height: 4,
                  borderRadius: BorderRadius.all(Radius.circular(4)),
                ),
                SizedBox(height: 16),
              ],
              Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextSkeleton(width: 190, height: 24),
                        SizedBox(height: 8),
                        TextSkeleton(width: 120, height: 13),
                      ],
                    ),
                  ),
                  if (showCloseButton)
                    const SkeletonBox(
                      width: 40,
                      height: 40,
                      borderRadius: BorderRadius.all(Radius.circular(20)),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: Theme.of(context).colorScheme.surfaceContainerLowest,
                  ),
                  child: const SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextSkeleton(height: 16),
                        SizedBox(height: 8),
                        TextSkeleton(width: 210, height: 16),
                        SizedBox(height: 16),
                        TextSkeleton(width: 96, height: 18),
                        SizedBox(height: 8),
                        TextSkeleton(height: 14),
                        SizedBox(height: 6),
                        TextSkeleton(width: 240, height: 14),
                        SizedBox(height: 16),
                        CodeBlockSkeleton(),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              if (showDualActions)
                const Row(
                  children: [
                    Expanded(
                      child: SkeletonBox(
                        height: 48,
                        borderRadius: BorderRadius.all(Radius.circular(16)),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: SkeletonBox(
                        height: 48,
                        borderRadius: BorderRadius.all(Radius.circular(16)),
                      ),
                    ),
                  ],
                )
              else
                const SkeletonBox(
                  height: 52,
                  borderRadius: BorderRadius.all(Radius.circular(16)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class SearchResultsSkeleton extends StatelessWidget {
  const SearchResultsSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return AppSkeleton(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(10, 2, 10, 12),
        children: const [
          Padding(
            padding: EdgeInsets.fromLTRB(8, 4, 8, 6),
            child: TextSkeleton(width: 100, height: 16),
          ),
          _SearchTileSkeleton(),
          _SearchTileSkeleton(),
          SizedBox(height: 8),
          Padding(
            padding: EdgeInsets.fromLTRB(8, 4, 8, 6),
            child: TextSkeleton(width: 68, height: 16),
          ),
          _SearchTileSkeleton(),
          _SearchTileSkeleton(),
        ],
      ),
    );
  }
}

class _SearchTileSkeleton extends StatelessWidget {
  const _SearchTileSkeleton();

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            SkeletonBox(width: 24, height: 24),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextSkeleton(width: 140, height: 14),
                  SizedBox(height: 6),
                  TextSkeleton(height: 12),
                ],
              ),
            ),
            SizedBox(width: 12),
            SkeletonBox(width: 20, height: 20),
          ],
        ),
      ),
    );
  }
}

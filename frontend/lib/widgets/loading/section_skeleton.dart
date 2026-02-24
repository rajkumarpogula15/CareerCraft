import 'package:flutter/material.dart';

import 'repo_skeleton.dart';

class SectionSkeleton extends StatelessWidget {
  final int count;

  const SectionSkeleton({super.key, this.count = 3});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: List.generate(
          count,
          (_) => const Padding(
            padding: EdgeInsets.only(bottom: 10),
            child: RepoSkeleton(),
          ),
        ),
      ),
    );
  }
}

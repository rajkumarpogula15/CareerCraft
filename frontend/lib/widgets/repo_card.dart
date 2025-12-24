import 'package:flutter/material.dart';

class RepoCard extends StatelessWidget {
  final String name;
  final String description;
  final bool isPrivate;

  const RepoCard({
    super.key,
    required this.name,
    required this.description,
    required this.isPrivate,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(isPrivate ? Icons.lock : Icons.public),
        title: Text(name),
        subtitle: Text(description),
      ),
    );
  }
}

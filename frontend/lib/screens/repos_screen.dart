import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../state/app_state.dart';
import '../widgets/repo_card.dart';
import '../config/app_config.dart';

class ReposScreen extends StatefulWidget {
  const ReposScreen({super.key});

  @override
  State<ReposScreen> createState() => _ReposScreenState();
}

class _ReposScreenState extends State<ReposScreen> {
  final String backendUrl = AppConfig.backendBaseUrl;
  bool loading = true;
  List repos = [];

  @override
  void initState() {
    super.initState();
    if (AppState.isLoggedIn) {
      fetchRepos();
    }
  }

  Future<void> fetchRepos() async {
    final res = await http.get(Uri.parse('$backendUrl/auth/github/repos'));

    if (res.statusCode == 200) {
      setState(() {
        repos = json.decode(res.body);
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!AppState.isLoggedIn) {
      return const Center(child: Text('Login to view repositories'));
    }

    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(title: const Text('My Repositories')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: repos.length,
        itemBuilder: (context, index) {
          final repo = repos[index];
          return RepoCard(
            name: repo['name'],
            description: repo['description'] ?? 'No description',
            isPrivate: repo['private'],
          );
        },
      ),
    );
  }
}

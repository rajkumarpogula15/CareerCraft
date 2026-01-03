import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../state/app_state.dart';
import '../config/app_config.dart';
import '../models/favourite_repo.dart';

class RepositoryService {
  /* =========================
     ADD TO FAVOURITES
  ========================= */
  static Future<void> addFavourite(Map<String, dynamic> repo) async {
    final token = AppState.jwt;

    if (token == null) {
      throw Exception('User not authenticated');
    }

    final int repoId = repo['id'];
    final String url =
        '${AppConfig.backendBaseUrl}/repositories/$repoId/favourite';

    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(repo),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to add favourite');
    }
  }

  /* =========================
     REMOVE FROM FAVOURITES
  ========================= */
  static Future<void> removeFavourite(int repoId) async {
    final token = AppState.jwt;

    if (token == null) {
      throw Exception('User not authenticated');
    }

    final String url =
        '${AppConfig.backendBaseUrl}/repositories/$repoId/favourite';

    final response = await http.delete(
      Uri.parse(url),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to remove favourite');
    }
  }

  /* =========================
     FETCH FAVOURITE REPOS
  ========================= */
  static Future<List<FavouriteRepo>> fetchFavourites() async {
    final token = AppState.jwt;

    if (token == null) {
      throw Exception('User not authenticated');
    }

    final String url = '${AppConfig.backendBaseUrl}/repositories/favourites';

    final response = await http.get(
      Uri.parse(url),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch favourites');
    }

    final List<dynamic> data = jsonDecode(response.body);

    return data
        .map<FavouriteRepo>((json) => FavouriteRepo.fromJson(json))
        .toList();
  }
}

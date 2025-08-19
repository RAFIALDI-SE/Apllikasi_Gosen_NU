import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class FavoriteController {
  static const String baseUrl = 'http://10.0.2.2:8000/api/buyer';

  static Future<bool> addToFavorites(int productId, String? token) async {
    try {
      final response = await http.post(
        Uri.parse('http://10.0.2.2:8000/api/buyer/favorites/$productId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        print('✅ Favorite berhasil ditambahkan');
        return true;
      } else {
        print('❌ Gagal menambahkan favorite: ${response.body}');
        return false;
      }
    } catch (e) {
      print('❌ Error saat menambahkan favorite: $e');
      return false;
    }
  }

  static Future<bool> removeFromFavorites(int productId, String token) async {
    final url = Uri.parse('$baseUrl/api/buyer/favorites/$productId');
    try {
      final response = await http.delete(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        print('✅ Favorit dihapus');
        return true;
      } else {
        print('❌ Gagal hapus favorit: ${response.body}');
        return false;
      }
    } catch (e) {
      print('❌ Error hapus favorit: $e');
      return false;
    }
  }
}

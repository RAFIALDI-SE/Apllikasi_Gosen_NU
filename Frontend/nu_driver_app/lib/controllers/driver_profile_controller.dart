// lib/controllers/profile_controller.dart

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
// import 'package:geocoding/geocoding.dart';
// import 'package:geolocator/geolocator.dart';

class ProfileController {
  final String baseUrl = 'http://10.0.2.2:8000/api/driver';

  Future<Map<String, dynamic>?> fetchCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final response = await http.get(
      Uri.parse('http://10.0.2.2:8000/api/driver/me'),
      headers: {'Authorization': 'Bearer $token'},
    );

    print("📢 Status Code: ${response.statusCode}");
    print("📢 Body: ${response.body}");

    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      print("✅ Data user: ${jsonData['user']}");
      return jsonData['user'];
    }

    print('❌ Gagal fetch user, status: ${response.statusCode}');
    return null;
  }
}

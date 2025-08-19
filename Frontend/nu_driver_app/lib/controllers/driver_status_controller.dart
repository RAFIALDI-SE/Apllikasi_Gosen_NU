import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:latlong2/latlong.dart';

class DriverStatusController {
  final String baseUrl = 'http://10.0.2.2:8000/api/driver';

  Future<bool> getStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/status'),
        headers: {'Authorization': 'Bearer $token'},
      );

      debugPrint('GET Status Response: ${response.statusCode}');
      debugPrint('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return json['is_active'] ?? false;
      } else {
        debugPrint(
            'Gagal mengambil status, statusCode: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      debugPrint('Error saat getStatus: $e');
      return false;
    }
  }

  Future<bool> toggleStatus(bool currentStatus) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/toggle-active'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {'is_active': currentStatus ? '1' : '0'},
      );

      debugPrint('POST Toggle Status Response: ${response.statusCode}');
      debugPrint('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return json['is_active'] ?? false;
      } else {
        debugPrint('Gagal mengubah status, statusCode: ${response.statusCode}');
        return currentStatus;
      }
    } catch (e) {
      debugPrint('Error saat toggleStatus: $e');
      return currentStatus;
    }
  }

  Future<LatLng?> fetchDriverLocation() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final response = await http.get(
      Uri.parse('http://10.0.2.2:8000/api/driver/location'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return LatLng(
        double.parse(data['latitude'].toString()),
        double.parse(data['longitude'].toString()),
      );
    } else {
      return null;
    }
  }
}

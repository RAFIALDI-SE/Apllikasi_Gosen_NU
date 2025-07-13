import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthController {
  final String baseUrl = 'http://10.0.2.2:8000/api';

  Future<void> registerSeller(String name, String email, String password,
      String address, BuildContext context) async {
    final response = await http.post(
      Uri.parse('$baseUrl/register'),
      headers: {'Accept': 'application/json'},
      body: {
        'name': name,
        'email': email,
        'password': password,
        'password_confirmation': password, // penting!
        'role': 'seller',
        'address': address,
        'latitude': '-7.79', // Dummy dulu
        'longitude': '110.41',
      },
    );

    final data = json.decode(response.body);

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Register berhasil, login sekarang')));
      Navigator.pushNamed(context, '/login');
    } else {
      final error = data['message'] ?? 'Register gagal';
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error)));
    }
  }

  Future<bool> loginSeller(
      String email, String password, BuildContext context) async {
    final response = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: {'Accept': 'application/json'},
      body: {
        'email': email,
        'password': password,
      },
    );

    final data = json.decode(response.body);

    if (response.statusCode == 200) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', data['token']);

      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Login berhasil!')));
      return true; // ✅ sukses
    } else {
      final error = data['message'] ?? 'Login gagal';
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error)));
      return false; // ❌ gagal
    }
  }

  static Future<void> logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    Navigator.pushReplacementNamed(context, '/login');
  }
}

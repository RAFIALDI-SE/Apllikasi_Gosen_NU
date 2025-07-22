import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthController {
  final String baseUrl = 'http://10.0.2.2:8000/api';

  Future<void> registerSeller(
    String name,
    String email,
    String password,
    String phone,
    BuildContext context,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/register'),
      headers: {'Accept': 'application/json'},
      body: {
        'name': name,
        'email': email,
        'password': password,
        'password_confirmation': password,
        'role': 'seller',
        'phone': phone,
        'address': 'kosong',
        'latitude': '-7.79', // Dummy dulu
        'longitude': '110.41',
      },
    );

    final data = json.decode(response.body);

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Register berhasil, silakan login')),
      );
      Navigator.pushNamed(context, '/login');
    } else if (response.statusCode == 422) {
      // Laravel validation error
      final errors = data['errors'];
      if (errors != null) {
        String errorMessage = '';
        if (errors['name'] != null) {
          errorMessage += 'Nama: ${errors['name'][0]}\n';
        }
        if (errors['email'] != null) {
          errorMessage += 'Email: ${errors['email'][0]}\n';
        }
        if (errors['phone'] != null) {
          errorMessage += 'Nomor HP: ${errors['phone'][0]}\n';
        }
        if (errors['password'] != null) {
          errorMessage += 'Password: ${errors['password'][0]}\n';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage.trim())),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Terjadi kesalahan validasi')),
        );
      }
    } else {
      final error = data['message'] ?? 'Register gagal';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
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

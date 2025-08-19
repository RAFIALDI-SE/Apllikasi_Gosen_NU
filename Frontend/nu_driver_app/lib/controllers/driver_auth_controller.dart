import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class DriverAuthController {
  final String baseUrl = 'http://10.0.2.2:8000/api';

  Future<bool> login({
    required String email,
    required String password,
    required BuildContext context,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/login/driver'), // endpoint khusus driver
      headers: {'Accept': 'application/json'},
      body: {'email': email, 'password': password},
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', data['token']);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Login driver berhasil!')),
      );
      return true;
    } else {
      final error = data['message'] ?? 'Login gagal';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
      return false;
    }
  }

  Future<void> registerDriver(
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
        'role': 'driver',
        'phone': phone,
        'address': 'Belum diisi',
        'latitude': '-7.80',
        'longitude': '110.41',
      },
    );

    final data = json.decode(response.body);

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Register driver berhasil, silakan login')),
      );
      Navigator.pushNamed(context, '/driver/login');
    } else if (response.statusCode == 422) {
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

  Future<void> logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final response = await http.post(
      Uri.parse('$baseUrl/logout'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      await prefs.remove('token');
      Navigator.pushReplacementNamed(context, '/driver/login');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Logout gagal')),
      );
    }
  }
}

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class BuyerOrderHistoryController with ChangeNotifier {
  List<Map<String, dynamic>> _orders = [];
  bool _loading = false;

  List<Map<String, dynamic>> get orders => _orders;
  bool get loading => _loading;

  Future<void> fetchOrderHistory() async {
    _loading = true;
    notifyListeners();

    SharedPreferences prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final response = await http.get(
      Uri.parse('http://10.0.2.2:8000/api/buyer/orders'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      try {
        print('Response body: ${response.body}');
        final decoded = json.decode(response.body);
        final data = decoded['orders'];
        if (data != null && data is List) {
          _orders = List<Map<String, dynamic>>.from(data);
        } else {
          _orders = [];
        }
      } catch (e) {
        print('Error saat decoding JSON: $e');
        _orders = [];
      }
    } else {
      print('HTTP Error: ${response.statusCode}');
      _orders = [];
    }

    _loading = false;
    notifyListeners();
  }
}

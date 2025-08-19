import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SellerOrderDetailController {
  static String formatCurrency(dynamic value) {
    final formatter =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);
    double parsedValue = 0;
    try {
      parsedValue = value is String ? double.parse(value) : value.toDouble();
    } catch (_) {
      parsedValue = 0;
    }
    return formatter.format(parsedValue);
  }

  static void launchWhatsApp(String phone, String message) async {
    final url =
        Uri.parse("https://wa.me/$phone?text=${Uri.encodeComponent(message)}");
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      debugPrint("Tidak bisa membuka WhatsApp");
    }
  }

  static Future<void> confirmOrder(BuildContext context, int orderId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    final response = await http.post(
      Uri.parse('http://10.0.2.2:8000/api/seller/orders/$orderId/confirm'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Status pesanan berhasil diubah ke confirmed')),
      );
      Navigator.pop(context);
    } else {
      final error = json.decode(response.body);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error['message'] ?? 'Gagal mengubah status')),
      );
    }
  }

  static Future<void> markAsDelivering(
      BuildContext context, int orderId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    final response = await http.post(
      Uri.parse('http://10.0.2.2:8000/api/seller/orders/$orderId/delivering'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Status pesanan diubah ke delivering')),
      );
      Navigator.pop(context);
    } else {
      final error = json.decode(response.body);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error['message'] ?? 'Gagal update status')),
      );
    }
  }
}

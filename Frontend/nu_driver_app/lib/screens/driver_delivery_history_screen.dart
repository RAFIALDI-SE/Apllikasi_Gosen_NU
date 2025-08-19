import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

import 'driver_delivery_history_detail_screen.dart';

class DriverDeliveryHistoryScreen extends StatefulWidget {
  const DriverDeliveryHistoryScreen({super.key});

  @override
  State<DriverDeliveryHistoryScreen> createState() =>
      _DriverDeliveryHistoryScreenState();
}

class _DriverDeliveryHistoryScreenState
    extends State<DriverDeliveryHistoryScreen> {
  List<dynamic> _deliveries = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    fetchDeliveries();
  }

  Future<void> fetchDeliveries() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    try {
      final response = await http.get(
        Uri.parse('http://10.0.2.2:8000/api/driver/deliveries/history'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        print('Response body: ${response.body}');
        final data = json.decode(response.body);
        final deliveries = data['data'];

        if (deliveries is List) {
          setState(() {
            _deliveries = deliveries;
            _loading = false;
          });
        } else {
          setState(() {
            _deliveries = [];
            _loading = false;
          });
        }
      } else {
        debugPrint('Gagal memuat data: ${response.body}');
        setState(() {
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('Terjadi kesalahan: $e');
      setState(() {
        _loading = false;
      });
    }
  }

  String formatCurrency(dynamic value) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Pengantaran'),
        backgroundColor: const Color(0xFF0066CC),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _deliveries.isEmpty
              ? const Center(child: Text('Belum ada pengantaran'))
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _deliveries.length,
                  itemBuilder: (context, index) {
                    final delivery = _deliveries[index];
                    final orderItems = delivery['order_items'] ?? [];
                    final buyer = delivery['buyer'];
                    final seller = delivery['seller'];
                    final product =
                        orderItems.isNotEmpty ? orderItems[0]['product'] : null;
                    final image = product?['image'];

                    final rawDate = delivery['delivered_at'] ??
                        delivery['created_at'] ??
                        DateTime.now().toString();

                    final formattedDate = DateFormat('dd MMM yyyy, HH:mm')
                        .format(DateTime.tryParse(rawDate) ?? DateTime.now());

                    final total = formatCurrency(delivery['total_amount']);
                    final status = delivery['status'] ?? 'unknown';
                    // Warna status badge
                    Color getStatusColor(String status) {
                      switch (status) {
                        case 'pending':
                          return Colors.grey;
                        case 'confirmed':
                          return Colors.blue;
                        case 'delivering':
                          return Colors.orange;
                        case 'delivered':
                          return Colors.green;
                        case 'cancelled':
                          return Colors.red;
                        default:
                          return Colors.black;
                      }
                    }

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 6,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(12),
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: image != null && image.toString().isNotEmpty
                              ? Image.network(
                                  'http://10.0.2.2:8000/storage/$image',
                                  width: 60,
                                  height: 60,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      width: 60,
                                      height: 60,
                                      color: Colors.grey[300],
                                      child: const Icon(Icons.broken_image,
                                          color: Colors.grey),
                                    );
                                  },
                                )
                              : Container(
                                  width: 60,
                                  height: 60,
                                  color: Colors.grey[300],
                                  child: const Icon(Icons.image_not_supported),
                                ),
                        ),
                        title: Text(
                          product != null ? product['name'] : 'Produk',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Pembeli: ${buyer?['name'] ?? '-'}"),
                              Text("Toko: ${seller?['name'] ?? '-'}"),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: getStatusColor(status)
                                          .withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      status.toUpperCase(),
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: getStatusColor(status),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    formattedDate,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "Total: $total",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1A8754),
                                ),
                              ),
                            ],
                          ),
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  DriverDeliveryDetailScreen(order: delivery),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
    );
  }
}

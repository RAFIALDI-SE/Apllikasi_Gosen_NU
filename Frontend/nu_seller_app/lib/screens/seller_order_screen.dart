import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

import 'seller_order_detail_screen.dart';

class SellerOrderScreen extends StatefulWidget {
  const SellerOrderScreen({super.key});

  @override
  State<SellerOrderScreen> createState() => _SellerOrderScreenState();
}

class _SellerOrderScreenState extends State<SellerOrderScreen> {
  List<dynamic> _orders = [];
  bool _loading = true;
  bool _errorParsing = false;

  @override
  void initState() {
    super.initState();
    fetchOrders();
  }

  // Fungsi untuk memberikan warna berdasarkan status
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

  Future<void> fetchOrders() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    final response = await http.get(
      Uri.parse('http://10.0.2.2:8000/api/seller/orders'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      try {
        final decoded = json.decode(response.body);
        final data = decoded['orders'];
        if (data != null && data is List) {
          setState(() {
            _orders = data;
            _loading = false;
          });
        } else {
          setState(() {
            _orders = [];
            _loading = false;
          });
        }
      } catch (e) {
        print('Error parsing JSON: $e');
        setState(() {
          _orders = [];
          _loading = false;
          _errorParsing = true;
        });
      }
    } else {
      print('Gagal memuat pesanan: ${response.body}');
      setState(() {
        _loading = false;
        _orders = [];
      });
    }
  }

  String formatCurrency(dynamic value) {
    final formatter =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);
    double parsedValue = 0;

    try {
      parsedValue = value is String ? double.parse(value) : value.toDouble();
    } catch (e) {
      parsedValue = 0;
    }

    return formatter.format(parsedValue);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pesanan Masuk'),
        backgroundColor: const Color(0xFF1A8754),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _errorParsing
              ? const Center(
                  child: Text(
                    'Terjadi kesalahan saat membaca data.\nSilakan coba beberapa saat lagi.',
                    textAlign: TextAlign.center,
                  ),
                )
              : RefreshIndicator(
                  onRefresh: fetchOrders,
                  child: _orders.isEmpty
                      ? ListView(
                          children: const [
                            SizedBox(height: 150),
                            Center(child: Text('Belum ada pesanan')),
                          ],
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: _orders.length,
                          itemBuilder: (context, index) {
                            final order = _orders[index];
                            final buyer = order['buyer'];
                            final driver = order['driver'];
                            final orderItems =
                                order['order_items'] as List<dynamic>;
                            final firstProduct = orderItems.isNotEmpty
                                ? orderItems[0]['product']
                                : null;
                            final productImage = firstProduct != null
                                ? firstProduct['image']
                                : null;

                            final formattedDate =
                                DateFormat('dd MMM yyyy, HH:mm').format(
                                    DateTime.parse(order['created_at']));
                            final totalPrice =
                                formatCurrency(order['total_amount']);

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
                                  child: productImage != null
                                      ? Image.network(
                                          'http://10.0.2.2:8000/storage/$productImage',
                                          width: 60,
                                          height: 60,
                                          fit: BoxFit.cover,
                                        )
                                      : Container(
                                          width: 60,
                                          height: 60,
                                          color: Colors.grey[300],
                                          child: const Icon(
                                              Icons.image_not_supported),
                                        ),
                                ),
                                title: Text(
                                  firstProduct != null
                                      ? firstProduct['name']
                                      : 'Produk',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text("Pembeli: ${buyer?['name'] ?? '-'}"),
                                      Text("Driver: ${driver?['name'] ?? '-'}"),
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: getStatusColor(
                                                      order['status'])
                                                  .withOpacity(0.1),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              order['status'].toUpperCase(),
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                color: getStatusColor(
                                                    order['status']),
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
                                        "Total: $totalPrice",
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
                                          SellerOrderDetailScreen(order: order),
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                        ),
                ),
    );
  }
}

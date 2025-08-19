import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
// import halaman detail
import 'driver_delivery_history_detail_screen.dart';

class DriverTodayOrdersScreen extends StatefulWidget {
  const DriverTodayOrdersScreen({super.key});

  @override
  State<DriverTodayOrdersScreen> createState() =>
      _DriverTodayOrdersScreenState();
}

class _DriverTodayOrdersScreenState extends State<DriverTodayOrdersScreen> {
  List _orders = [];
  bool _isLoading = true;

  final Color primaryColor = const Color(0xFF0066CC);

  @override
  void initState() {
    super.initState();
    fetchTodayOrders();
  }

  Future<void> fetchTodayOrders() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    if (token == null) {
      print('Token tidak ditemukan!');
      setState(() => _isLoading = false);
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('http://10.0.2.2:8000/api/driver/deliveries/today'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final orders = data['data'] ?? [];

        setState(() {
          _orders = orders;
          _isLoading = false;
        });
      } else {
        throw Exception('Gagal memuat data pesanan hari ini.');
      }
    } catch (e) {
      print("Terjadi error saat fetch: $e");
      setState(() => _isLoading = false);
    }
  }

  String formatCurrency(num number) {
    return 'Rp ${number.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (match) => '${match[1]}.',
        )}';
  }

  num parseToNum(dynamic value) {
    if (value is num) return value;
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: fetchTodayOrders,
              child: _orders.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: const [
                        SizedBox(height: 200),
                        Center(
                          child: Text(
                            "Tidak ada pesanan hari ini",
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ],
                    )
                  : ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(12),
                      itemCount: _orders.length,
                      itemBuilder: (context, index) {
                        final order = _orders[index];
                        final buyer = order['buyer'] ?? {};
                        final items = order['order_items'] ?? [];

                        final profileUrl = buyer['profile_picture'] != null
                            ? 'http://10.0.2.2:8000/storage/${buyer['profile_picture']}'
                            : null;

                        final createdAt = order['created_at'] ?? '';
                        final status = order['status'] ?? 'unknown';

                        // Format tanggal & jam
                        final formattedDateTime = createdAt.isNotEmpty
                            ? DateTime.tryParse(createdAt)
                                    ?.toLocal()
                                    .toString()
                                    .substring(0, 16)
                                    .replaceAll('T', ' ') ??
                                '-'
                            : '-';

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

                        return InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    DriverDeliveryDetailScreen(order: order),
                              ),
                            );
                          },
                          child: Card(
                            elevation: 3,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            margin: const EdgeInsets.only(bottom: 16),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 20,
                                        backgroundColor: Colors.grey.shade300,
                                        backgroundImage: profileUrl != null
                                            ? NetworkImage(profileUrl)
                                            : null,
                                        child: profileUrl == null
                                            ? Icon(Icons.person,
                                                color: primaryColor)
                                            : null,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              buyer['name'] ??
                                                  'Pembeli tidak diketahui',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                                color: primaryColor,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              formattedDateTime,
                                              style: const TextStyle(
                                                  fontSize: 13,
                                                  color: Colors.grey),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: getStatusColor(status)
                                              .withOpacity(0.15),
                                          border: Border.all(
                                              color: getStatusColor(status)),
                                          borderRadius:
                                              BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          status.toUpperCase(),
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: getStatusColor(status),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  ...items.map<Widget>((item) {
                                    final product = item['product'] ?? {};
                                    final qty = parseToNum(item['quantity']);
                                    final price = parseToNum(product['price']);

                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 6),
                                      child: Text(
                                        "• ${product['name'] ?? 'Produk'} x$qty - ${formatCurrency(price)}",
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                    );
                                  }).toList(),
                                  const Divider(height: 20),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      Icon(Icons.receipt_long,
                                          color: primaryColor),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Total: ${formatCurrency(parseToNum(order['total_amount']))}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}

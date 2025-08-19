import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'buyer_delivery_map_page.dart';

class BuyerOrderDetailScreen extends StatefulWidget {
  final Map<String, dynamic> order;

  const BuyerOrderDetailScreen({super.key, required this.order});

  @override
  State<BuyerOrderDetailScreen> createState() => _BuyerOrderDetailScreenState();
}

class _BuyerOrderDetailScreenState extends State<BuyerOrderDetailScreen> {
  late Map<String, dynamic> order;
  final String baseImageUrl = 'http://10.0.2.2:8000/storage/';

  final TextEditingController _reviewController = TextEditingController();
  double _rating = 0.0;
  Map<String, dynamic>? myReview;

  @override
  void initState() {
    super.initState();
    order = widget.order;
    _fetchMyReview();
  }

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  Future<void> _fetchMyReview() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final productId = order['order_items'][0]['product']['id'];

    final response = await http.get(
      Uri.parse('http://10.0.2.2:8000/api/buyer/products/$productId/my-review'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data != null && data.isNotEmpty) {
        setState(() {
          myReview = data;
          _rating = data['rating']?.toDouble() ?? 0.0;
          _reviewController.text = data['comment'] ?? '';
        });
      }
    } else {
      print("Gagal ambil review: ${response.body}");
    }
  }

  Future<void> _submitReview() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final productId = order['order_items'][0]['product']['id'];

    final response = await http.post(
      Uri.parse('http://10.0.2.2:8000/api/buyer/products/$productId/reviews'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
      body: {
        'rating': _rating.toInt().toString(),
        'comment': _reviewController.text,
      },
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Review berhasil disimpan')),
      );
      _fetchMyReview();
      _reviewController.clear();
      setState(() {
        _rating = 0.0;
      });
    } else {
      final message =
          json.decode(response.body)['message'] ?? 'Gagal kirim review';
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _deleteReview() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final productId = order['order_items'][0]['product']['id'];

    final response = await http.delete(
      Uri.parse('http://10.0.2.2:8000/api/buyer/products/$productId/reviews'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('🗑️ Review berhasil dihapus')),
      );
      setState(() {
        myReview = null;
        _reviewController.clear();
        _rating = 0.0;
      });
      _fetchMyReview();
    } else {
      final msg = json.decode(response.body)['message'] ?? 'Gagal hapus review';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  Future<void> _refreshData() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final response = await http.get(
      Uri.parse('http://10.0.2.2:8000/api/buyer/ordersdetail/${order['id']}'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body)['order'];
      setState(() {
        order = data;
      });
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal memuat ulang data')),
        );
      }
    }
  }

  void _launchWhatsApp(String phone) async {
    final uri = Uri.parse("https://wa.me/$phone");
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      debugPrint("Could not launch WhatsApp for $phone");
    }
  }

  Color _statusColor(String? status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'confirmed':
        return Colors.blue;
      case 'delivering':
        return Colors.amber;
      case 'delivered':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Color _paymentColor(String? paymentStatus) {
    switch (paymentStatus) {
      case 'paid':
        return Colors.green;
      case 'unpaid':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  bool _canCancel(String createdAt) {
    final orderTime = DateTime.tryParse(createdAt);
    if (orderTime == null) return false;
    return DateTime.now().difference(orderTime).inMinutes < 5;
  }

  @override
  Widget build(BuildContext context) {
    final orderItems = order['order_items'] as List<dynamic>? ?? [];

    const primaryColor = Color(0xFF1A8754);
    const lightGrey = Color(0xFFF0F0F0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Pesanan',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      backgroundColor: lightGrey,
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (order['buyer']?['latitude'] != null &&
                  order['buyer']?['longitude'] != null &&
                  order['driver']?['latitude'] != null &&
                  order['driver']?['longitude'] != null &&
                  order['order_items']?[0]?['product']?['user']?['latitude'] !=
                      null &&
                  order['order_items']?[0]?['product']?['user']?['longitude'] !=
                      null)
                _buildLocationSection(context, order),
              const SizedBox(height: 16),
              _buildOrderInfoSection(order, _statusColor, _paymentColor),
              const SizedBox(height: 16),
              _buildNoteSection(order),
              const SizedBox(height: 16),
              _buildProductSection(orderItems, baseImageUrl),
              const SizedBox(height: 16),
              _buildDriverSection(order, _launchWhatsApp),
              const SizedBox(height: 16),
              _buildActionButtons(order, context, _canCancel),
              const SizedBox(height: 16),
              _buildReviewSection(
                order,
                myReview,
                _rating,
                _reviewController,
                _deleteReview,
                _submitReview,
                (double newRating) {
                  setState(() {
                    _rating = newRating;
                  });
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLocationSection(
      BuildContext context, Map<String, dynamic> order) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "📍 Lokasi Pengiriman",
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A5D1A)),
            ),
            const SizedBox(height: 12),
            Container(
              height: 250,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: FlutterMap(
                  options: MapOptions(
                    initialCenter: LatLng(
                      double.parse(order['buyer']['latitude'].toString()),
                      double.parse(order['buyer']['longitude'].toString()),
                    ),
                    initialZoom: 13,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.nu_buyer_app',
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: LatLng(
                            double.parse(order['buyer']['latitude'].toString()),
                            double.parse(
                                order['buyer']['longitude'].toString()),
                          ),
                          child: const Icon(Icons.person_pin_circle,
                              color: Colors.blue, size: 40),
                        ),
                        Marker(
                          point: LatLng(
                            double.parse(order['order_items'][0]['product']
                                    ['user']['latitude']
                                .toString()),
                            double.parse(order['order_items'][0]['product']
                                    ['user']['longitude']
                                .toString()),
                          ),
                          child: const Icon(Icons.store,
                              color: Colors.green, size: 40),
                        ),
                        Marker(
                          point: LatLng(
                            double.parse(
                                order['driver']['latitude'].toString()),
                            double.parse(
                                order['driver']['longitude'].toString()),
                          ),
                          child: const Icon(Icons.local_shipping,
                              color: Colors.red, size: 40),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMapLegend(
                    Icons.person_pin_circle, "Pembeli", Colors.blue),
                _buildMapLegend(Icons.store, "Penjual", Colors.green),
                _buildMapLegend(Icons.local_shipping, "Driver", Colors.red),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapLegend(IconData icon, String label, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _buildOrderInfoSection(Map<String, dynamic> order,
      Function(String?) statusColor, Function(String?) paymentColor) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "🧾 Info Pesanan",
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A5D1A)),
            ),
            const Divider(height: 24),
            _buildInfoRow("ID Pesanan:", order['id'].toString()),
            _buildStatusRow("Status:", order['status'], statusColor),
            _buildStatusRow(
                "Pembayaran:", order['payment_status'], paymentColor),
            _buildInfoRow(
                "Tanggal:", order['created_at'].toString().substring(0, 10)),
            const Divider(height: 24),
            _buildInfoRow(
              "Total Pesanan:",
              "Rp ${order['total_amount']}",
              isBold: true,
              fontSize: 18,
              color: const Color(0xFF1A5D1A),
            ),
            if (order['delivery_proof'] != null) ...[
              const Divider(height: 24),
              const Text(
                "📷 Bukti Pengiriman:",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  'http://10.0.2.2:8000/storage/' + order['delivery_proof'],
                  width: double.infinity,
                  height: 200,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: double.infinity,
                    height: 200,
                    color: Colors.grey.shade300,
                    child: const Icon(Icons.broken_image,
                        size: 40, color: Colors.red),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildNoteSection(Map<String, dynamic> order) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "🗒️ Catatan Pembeli",
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A5D1A)),
            ),
            const Divider(height: 24),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Text(
                order['note']?.isNotEmpty == true
                    ? order['note']
                    : 'Tidak ada catatan.',
                style: const TextStyle(fontSize: 16, color: Colors.black87),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value,
      {bool isBold = false, double fontSize = 14, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontSize: fontSize,
              color: color,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontSize: fontSize,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusRow(
      String label, String? status, Function(String?) colorFunction) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: colorFunction(status),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              status?.toUpperCase() ?? '-',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductSection(List<dynamic> orderItems, String baseImageUrl) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "📦 Produk Dipesan",
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A5D1A)),
            ),
            const Divider(height: 24),
            ...orderItems.map((item) {
              final product = item['product'] ?? {};
              final productName = product['name'] ?? 'Produk';
              final imageUrl = product['image'] != null
                  ? baseImageUrl + product['image']
                  : '';
              final seller = product['user'] ?? {};
              final sellerPhone = seller['phone']?.toString();

              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: imageUrl.isNotEmpty
                          ? Image.network(
                              imageUrl,
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                            )
                          : Container(
                              width: 80,
                              height: 80,
                              color: Colors.grey.shade200,
                              child: const Icon(Icons.image_not_supported),
                            ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            productName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1A5D1A),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text('Jumlah: ${item['quantity']}',
                              style: const TextStyle(color: Colors.black54)),
                          Text('Harga: Rp ${item['price_at_order_time']}',
                              style: const TextStyle(color: Colors.black54)),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  "Penjual: ${seller['name'] ?? '-'}",
                                  style: const TextStyle(
                                      color: Colors.grey,
                                      fontStyle: FontStyle.italic),
                                ),
                              ),
                              if (sellerPhone != null && sellerPhone.isNotEmpty)
                                IconButton(
                                  icon: const Icon(FontAwesomeIcons.whatsapp,
                                      color: Colors.green, size: 20),
                                  onPressed: () => _launchWhatsApp(sellerPhone),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildDriverSection(
      Map<String, dynamic> order, Function(String) launchWhatsApp) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "🚚 Info Driver",
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A5D1A)),
            ),
            const Divider(height: 24),
            if (order['driver'] != null) ...[
              _buildInfoRow("Nama:", order['driver']['name'] ?? '-'),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text("Telepon: ${order['driver']['phone'] ?? '-'}",
                        style: const TextStyle(color: Colors.black)),
                  ),
                  if ((order['driver']['phone'] ?? '').toString().isNotEmpty)
                    IconButton(
                      icon: const Icon(FontAwesomeIcons.whatsapp,
                          color: Colors.green, size: 20),
                      onPressed: () =>
                          launchWhatsApp(order['driver']['phone'].toString()),
                    ),
                ],
              ),
            ] else
              const Text("Belum ada driver yang ditugaskan.",
                  style: TextStyle(fontStyle: FontStyle.italic)),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(Map<String, dynamic> order, BuildContext context,
      Function(String) canCancel) {
    Future<void> _cancelOrder() async {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Konfirmasi'),
          content: const Text('Yakin ingin membatalkan pesanan ini?'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Tidak')),
            TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Ya')),
          ],
        ),
      );

      if (confirm == true) {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('token');
        final response = await http.post(
          Uri.parse(
              'http://10.0.2.2:8000/api/buyer/orders/${order['id']}/cancel'),
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json'
          },
        );

        if (response.statusCode == 200) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Pesanan berhasil dibatalkan')),
            );
            Navigator.pop(context);
          }
        } else {
          final msg =
              json.decode(response.body)['message'] ?? 'Gagal membatalkan';
          if (context.mounted) {
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text(msg)));
          }
        }
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (order['status'] == 'pending' && canCancel(order['created_at']))
          ElevatedButton.icon(
            onPressed: _cancelOrder,
            icon: const Icon(Icons.cancel),
            label: const Text('Batalkan Pesanan',
                style: TextStyle(fontWeight: FontWeight.w600)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              elevation: 2,
            ),
          ),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: () {
            if (order['buyer'] != null &&
                order['order_items'] != null &&
                order['order_items'].isNotEmpty &&
                order['order_items'][0]['product'] != null &&
                order['order_items'][0]['product']['user'] != null &&
                order['driver'] != null) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DeliveryMapPage(
                    seller: LatLng(
                      double.parse(order['order_items'][0]['product']['user']
                              ['latitude']
                          .toString()),
                      double.parse(order['order_items'][0]['product']['user']
                              ['longitude']
                          .toString()),
                    ),
                    buyer: LatLng(
                      double.parse(order['buyer']['latitude'].toString()),
                      double.parse(order['buyer']['longitude'].toString()),
                    ),
                    driver: LatLng(
                      double.parse(order['driver']['latitude'].toString()),
                      double.parse(order['driver']['longitude'].toString()),
                    ),
                  ),
                ),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Data lokasi tidak lengkap')),
              );
            }
          },
          icon: const Icon(Icons.map, size: 20),
          label: const Text(
            "Lihat Simulasi Pengiriman",
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green[600],
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 2,
          ),
        ),
      ],
    );
  }

  Widget _buildReviewSection(
    Map<String, dynamic> order,
    Map<String, dynamic>? myReview,
    double rating,
    TextEditingController reviewController,
    Function() deleteReview,
    Function() submitReview,
    Function(double) onRatingChanged,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "📝 Ulasan Produk",
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A5D1A)),
            ),
            const Divider(height: 24),
            if (myReview != null) ...[
              _buildInfoRow("Rating:", "${myReview['rating']} ⭐"),
              const SizedBox(height: 4),
              Text("Ulasan: ${myReview['comment']}",
                  style: const TextStyle(fontSize: 14)),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: deleteReview,
                icon: const Icon(Icons.delete),
                label: const Text("Hapus Ulasan"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ] else if (order['status'] == 'delivered') ...[
              const Text("Beri ulasan setelah produk diterima:",
                  style: TextStyle(fontStyle: FontStyle.italic)),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return IconButton(
                    onPressed: () => onRatingChanged(index + 1.0),
                    icon: Icon(
                      index < rating ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                    ),
                  );
                }),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: reviewController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Tulis ulasan...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: rating > 0 && reviewController.text.isNotEmpty
                      ? submitReview
                      : null,
                  icon: const Icon(Icons.send),
                  label: const Text("Kirim Ulasan",
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
            ] else ...[
              const Text("Ulasan dapat diberikan setelah pesanan dikirim.",
                  style: TextStyle(fontStyle: FontStyle.italic)),
            ],
          ],
        ),
      ),
    );
  }
}

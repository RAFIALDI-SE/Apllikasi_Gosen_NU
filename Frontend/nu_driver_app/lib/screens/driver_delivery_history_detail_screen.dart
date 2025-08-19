import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class DriverDeliveryDetailScreen extends StatefulWidget {
  final Map<String, dynamic> order;

  const DriverDeliveryDetailScreen({super.key, required this.order});

  @override
  State<DriverDeliveryDetailScreen> createState() =>
      _DriverDeliveryDetailScreenState();
}

class _DriverDeliveryDetailScreenState
    extends State<DriverDeliveryDetailScreen> {
  final String baseImageUrl = 'http://10.0.2.2:8000/storage/';
  File? _proofImage;

  void _launchWhatsApp(String phone) async {
    final uri = Uri.parse("https://wa.me/$phone");
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      debugPrint("Tidak bisa membuka WhatsApp untuk $phone");
    }
  }

  Future<void> pickProofImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.camera);

    if (picked != null) {
      setState(() {
        _proofImage = File(picked.path);
      });
    }
  }

  Future<void> submitDeliveryProof() async {
    if (_proofImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Silakan ambil foto bukti terlebih dahulu.')),
      );
      return;
    }

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    final request = http.MultipartRequest(
      'POST',
      Uri.parse(
          'http://10.0.2.2:8000/api/driver/orders/${widget.order['id']}/delivered'),
    );

    request.headers['Authorization'] = 'Bearer $token';
    request.headers['Accept'] = 'application/json';

    request.files.add(
        await http.MultipartFile.fromPath('proof_image', _proofImage!.path));

    try {
      final streamedResponse = await request.send();
      final responseBody = await streamedResponse.stream.bytesToString();
      final result = json.decode(responseBody);

      if (streamedResponse.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Pesanan ditandai sebagai delivered')),
          );
          Navigator.pop(context);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(result['message'] ?? 'Gagal menyimpan bukti')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Terjadi kesalahan: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final orderItems = order['order_items'] as List<dynamic>? ?? [];
    final seller = order['seller'] ?? {};
    final sellerName = seller['name'] ?? '-';
    final sellerPhone = seller['phone']?.toString() ?? '';
    final buyer = order['buyer'] ?? {};
    final buyerName = buyer['name'] ?? '-';
    final buyerPhone = buyer['phone']?.toString() ?? '';
    final String note = order['note'] ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Pengantaran'),
        backgroundColor: const Color(0xFF0066CC),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("📦 Produk yang Diantar",
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0066CC))),
                    const Divider(height: 24),
                    ...orderItems.map((item) {
                      final product = item['product'] ?? {};
                      final productName = product['name'] ?? 'Produk';
                      final imageUrl = product['image'] != null
                          ? baseImageUrl + product['image']
                          : '';

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: imageUrl.isNotEmpty
                                  ? Image.network(
                                      imageUrl,
                                      width: 70,
                                      height: 70,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) =>
                                              Container(
                                        width: 70,
                                        height: 70,
                                        color: Colors.grey.shade300,
                                        child: const Icon(Icons.broken_image,
                                            color: Colors.red),
                                      ),
                                    )
                                  : Container(
                                      width: 70,
                                      height: 70,
                                      color: Colors.grey.shade200,
                                      child:
                                          const Icon(Icons.image_not_supported),
                                    ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(productName,
                                      style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF0066CC))),
                                  Text('Jumlah: ${item['quantity']}'),
                                  Text(
                                      'Harga: Rp ${item['price_at_order_time']}'),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    const Divider(height: 32),
                    const Text("🧾 Info Pesanan",
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0066CC))),
                    const SizedBox(height: 8),
                    if (order['delivery_proof'] != null &&
                        order['delivery_proof'].toString().isNotEmpty)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "📷 Bukti Pengiriman:",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.network(
                              baseImageUrl + order['delivery_proof'],
                              width: double.infinity,
                              height: 200,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  width: double.infinity,
                                  height: 200,
                                  color: Colors.grey.shade300,
                                  child: const Icon(Icons.broken_image,
                                      size: 40, color: Colors.red),
                                );
                              },
                            ),
                          ),
                          const Divider(height: 24),
                        ],
                      ),
                    Text("ID Pesanan: ${order['id']}"),
                    Text("Status: ${order['status']}"),
                    Text(
                        "Tanggal: ${order['created_at'].toString().substring(0, 10)}"),
                    const SizedBox(height: 12),
                    Text("Total: Rp ${order['total_amount']}",
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0066CC))),

                    // NOTE SECTION
                    if (note.isNotEmpty) ...[
                      const Divider(height: 24),
                      const Text("🗒️ Catatan Pembeli:",
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Text(note, style: const TextStyle(fontSize: 14)),
                      ),
                    ],

                    const Divider(height: 32),
                    const Text("👤 Pembeli",
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0066CC))),
                    const SizedBox(height: 8),
                    Text("Nama: $buyerName"),
                    Row(
                      children: [
                        Expanded(
                          child: Text("Telepon: $buyerPhone"),
                        ),
                        if (buyerPhone.isNotEmpty)
                          IconButton(
                            icon: const Icon(FontAwesomeIcons.whatsapp,
                                color: Colors.green, size: 20),
                            onPressed: () => _launchWhatsApp(buyerPhone),
                          ),
                      ],
                    ),
                    const Divider(height: 32),
                    const Text("🏪 Penjual",
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0066CC))),
                    const SizedBox(height: 8),
                    Text("Nama: $sellerName"),
                    Row(
                      children: [
                        Expanded(child: Text("Telepon: $sellerPhone")),
                        if (sellerPhone.isNotEmpty)
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
            ),
            const SizedBox(height: 24),
            if (order['status'] == 'delivering') ...[
              if (_proofImage != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text("📷 Bukti Pengantaran:",
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(_proofImage!,
                          width: double.infinity,
                          height: 200,
                          fit: BoxFit.cover),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: submitDeliveryProof,
                      icon: const Icon(Icons.check, color: Colors.white),
                      label: const Text("Tandai Sudah Dikirim",
                          style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade700,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 4,
                      ),
                    ),
                  ],
                )
              else
                ElevatedButton.icon(
                  onPressed: pickProofImage,
                  icon: const Icon(Icons.camera_alt, color: Colors.white),
                  label: const Text("Upload Bukti Foto",
                      style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange.shade700,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 4,
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

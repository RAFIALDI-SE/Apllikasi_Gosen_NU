import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../controllers/seller_order_detail_controller.dart';

class SellerOrderDetailScreen extends StatelessWidget {
  final Map<String, dynamic> order;

  const SellerOrderDetailScreen({super.key, required this.order});

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

  @override
  Widget build(BuildContext context) {
    final buyer = order['buyer'];
    final driver = order['driver'];
    final items = order['order_items'];
    final String baseImageUrl = 'http://10.0.2.2:8000/storage/';
    final String note = order['note'] ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF4F5F7),
      appBar: AppBar(
        title: const Text('Invoice Pesanan',
            style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF1E824C),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // INVOICE CARD
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(
                    color: Colors.black12, blurRadius: 6, offset: Offset(0, 2))
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text("INVOICE",
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87)),
                    const Spacer(),
                    IconButton(
                      onPressed: () {
                        SellerOrderDetailController.launchWhatsApp(
                          buyer['phone'],
                          "Halo ${buyer['name']}, saya seller dari pesanan kamu.",
                        );
                      },
                      icon: const FaIcon(FontAwesomeIcons.whatsapp,
                          size: 20, color: Colors.green),
                      tooltip: "Chat Buyer",
                    )
                  ],
                ),
                const SizedBox(height: 8),
                Text("Nama Buyer: ${buyer['name']}",
                    style: const TextStyle(fontSize: 16)),
                const SizedBox(height: 4),
                Text("Alamat Pengiriman:",
                    style: const TextStyle(fontWeight: FontWeight.w500)),
                Text(order['delivery_address'],
                    style: const TextStyle(color: Colors.black87)),

                // NOTE SECTION
                if (note.isNotEmpty) ...[
                  const Divider(height: 28),
                  Text("Catatan Pembeli:",
                      style: const TextStyle(fontWeight: FontWeight.w500)),
                  const SizedBox(height: 4),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Text(note,
                        style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black87,
                            fontStyle: FontStyle.italic)),
                  ),
                ],

                if (driver != null) ...[
                  const Divider(height: 28),
                  Row(
                    children: [
                      const Text("Informasi Driver",
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                      const Spacer(),
                      if (driver['phone'] != null)
                        IconButton(
                          onPressed: () {
                            SellerOrderDetailController.launchWhatsApp(
                              driver['phone'],
                              "Halo ${driver['name']}, ini pesanan yang kamu antar.",
                            );
                          },
                          icon: const FaIcon(FontAwesomeIcons.whatsapp,
                              size: 20, color: Colors.green),
                          tooltip: "Chat Driver",
                        )
                    ],
                  ),
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
                        const SizedBox(height: 12),
                      ],
                    ),
                  Text("Nama: ${driver['name']}"),
                  Text("Nomor HP: ${driver['phone'] ?? '-'}"),
                  Text("Alamat: ${driver['address'] ?? '-'}"),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Text("Pembayaran: "),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _paymentColor(order['payment_status']),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          order['payment_status'] ?? '-',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ]
              ],
            ),
          ),

          const SizedBox(height: 16),

          // PRODUK CARD
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(
                    color: Colors.black12, blurRadius: 6, offset: Offset(0, 2))
              ],
            ),
            child: Column(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: const BoxDecoration(
                    color: Color(0xFF1E824C),
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(16)),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Produk",
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold)),
                      Text("Subtotal",
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                ...items.map<Widget>((item) {
                  final product = item['product'];
                  final quantity = item['quantity'] is int
                      ? item['quantity']
                      : int.tryParse(item['quantity'].toString()) ?? 0;
                  final price = item['price_at_order_time'] is num
                      ? item['price_at_order_time']
                      : double.tryParse(
                              item['price_at_order_time'].toString()) ??
                          0.0;
                  final subtotal = quantity * price;

                  return Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            "http://10.0.2.2:8000/storage/${product['image']}",
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(product['name'],
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 15)),
                              Text(
                                  "Qty: $quantity x ${SellerOrderDetailController.formatCurrency(price)}",
                                  style: TextStyle(
                                      color: Colors.grey[600], fontSize: 13)),
                            ],
                          ),
                        ),
                        Text(
                            SellerOrderDetailController.formatCurrency(
                                subtotal),
                            style:
                                const TextStyle(fontWeight: FontWeight.w500)),
                      ],
                    ),
                  );
                }).toList(),
                const Divider(),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Total Pembayaran",
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                      Text(
                          SellerOrderDetailController.formatCurrency(
                              order['total_amount']),
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                )
              ],
            ),
          ),

          const SizedBox(height: 24),

          // BUTTONS SECTION
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ElevatedButton.icon(
                onPressed: order['status'] == 'pending'
                    ? () => SellerOrderDetailController.confirmOrder(
                        context, order['id'])
                    : null,
                icon:
                    const Icon(Icons.check_circle_outline, color: Colors.white),
                label: const Text("Konfirmasi Pesanan",
                    style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A8754),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 4,
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: order['status'] == 'confirmed'
                    ? () => SellerOrderDetailController.markAsDelivering(
                        context, order['id'])
                    : null,
                icon: const Icon(Icons.delivery_dining, color: Colors.white),
                label: const Text("Mulai Antar",
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
          ),
        ],
      ),
    );
  }
}

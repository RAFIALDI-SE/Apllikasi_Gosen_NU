import 'package:flutter/material.dart';
import '../../controllers/buyer_order_history_controller.dart';
import 'buyer_order_detail_screen.dart';

class BuyerOrderHistoryScreen extends StatefulWidget {
  const BuyerOrderHistoryScreen({Key? key}) : super(key: key);

  @override
  State<BuyerOrderHistoryScreen> createState() =>
      _BuyerOrderHistoryScreenState();
}

class _BuyerOrderHistoryScreenState extends State<BuyerOrderHistoryScreen> {
  final BuyerOrderHistoryController controller = BuyerOrderHistoryController();
  final String baseImageUrl = 'http://10.0.2.2:8000/storage/';

  @override
  void initState() {
    super.initState();
    _refreshOrders();
  }

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

  Future<void> _refreshOrders() async {
    await controller.fetchOrderHistory();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Riwayat Pesanan"),
        backgroundColor: const Color(0xFF1A8754),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: controller.loading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF1A5D1A)))
          : controller.orders.isEmpty
              ? RefreshIndicator(
                  onRefresh: _refreshOrders,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: const [
                      SizedBox(height: 100),
                      Center(
                        child: Text(
                          "Belum ada pesanan",
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _refreshOrders,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: controller.orders.length,
                    itemBuilder: (context, index) {
                      final order = controller.orders[index];
                      final items = order['order_items'] as List<dynamic>?;
                      final firstItem = items != null && items.isNotEmpty
                          ? items.first
                          : null;
                      final product =
                          firstItem != null ? firstItem['product'] : null;
                      final productName = product != null
                          ? product['name'] ?? 'Produk'
                          : 'Produk';
                      final productImagePath =
                          product != null ? product['image'] ?? '' : '';
                      final imageUrl = productImagePath.isNotEmpty
                          ? baseImageUrl + productImagePath
                          : '';

                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.green.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(12),
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: imageUrl.isNotEmpty
                                ? Image.network(
                                    imageUrl,
                                    width: 60,
                                    height: 60,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        width: 60,
                                        height: 60,
                                        color: Colors.grey.shade200,
                                        child: const Icon(Icons.broken_image),
                                      );
                                    },
                                  )
                                : Container(
                                    width: 60,
                                    height: 60,
                                    color: Colors.grey.shade200,
                                    child:
                                        const Icon(Icons.image_not_supported),
                                  ),
                          ),
                          title: Text(
                            productName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Color(0xFF1A5D1A),
                            ),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: getStatusColor(order['status'])
                                            .withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        order['status']
                                            .toString()
                                            .toUpperCase(),
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color:
                                              getStatusColor(order['status']),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Total: Rp ${order['total_amount']}',
                                  style: const TextStyle(
                                    color: Colors.black87,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  'Tanggal: ${order['created_at'].toString().substring(0, 10)}',
                                  style: const TextStyle(
                                    color: Colors.black54,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          trailing: const Icon(
                            Icons.chevron_right,
                            color: Color(0xFF1A5D1A),
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    BuyerOrderDetailScreen(order: order),
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

import 'package:flutter/material.dart';
import '../../controllers/buyer_order_controller.dart';

class BuyerOrderConfirmationScreen extends StatefulWidget {
  final Map<String, dynamic> product;
  final int quantity;
  final int driverId;
  final String driverName;
  final String driverAddress;
  final int deliveryFee;

  const BuyerOrderConfirmationScreen({
    super.key,
    required this.product,
    required this.quantity,
    required this.driverId,
    required this.driverName,
    required this.driverAddress,
    required this.deliveryFee,
  });

  @override
  State<BuyerOrderConfirmationScreen> createState() =>
      _BuyerOrderConfirmationScreenState();
}

class _BuyerOrderConfirmationScreenState
    extends State<BuyerOrderConfirmationScreen> {
  final TextEditingController _noteController = TextEditingController();

  double get totalProductPrice =>
      widget.quantity *
      (double.tryParse(widget.product['price']?.toString() ?? '0') ?? 0);

  double get grandTotal => totalProductPrice + widget.deliveryFee;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  void submitOrder(BuildContext context) async {
    final success = await BuyerOrderController.placeOrder(
      productId: widget.product['id'],
      quantity: widget.quantity,
      driverId: widget.driverId,
      driverName: widget.driverName,
      address: widget.product['user']?['address'] ?? 'Alamat belum tersedia',
      lat: widget.product['user']?['latitude'] ?? 0.0,
      lng: widget.product['user']?['longitude'] ?? 0.0,
      note: _noteController.text,
    );

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Order berhasil dibuat')),
      );
      Navigator.popUntil(context, (route) => route.isFirst);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❌ Gagal membuat order')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Konfirmasi Pesanan',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF1A8754),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              elevation: 5,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("📦 Detail Produk",
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text("Nama: ${product['name'] ?? '-'}",
                        style: const TextStyle(fontSize: 16)),
                    Text("Kategori: ${product['category'] ?? '-'}"),
                    Text("Penjual: ${product['user']?['name'] ?? '-'}"),
                    Text(
                        "Alamat Penjual: ${product['user']?['address'] ?? '-'}"),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 8),
                    const Text("🚚 Driver Pengantar",
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    Text("Nama Driver: ${widget.driverName}"),
                    Text("Alamat Driver: ${widget.driverAddress}"),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 8),
                    const Text("🧾 Ringkasan Pesanan",
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text("Harga Satuan: Rp ${product['price']}"),
                    Text("Jumlah: ${widget.quantity}"),
                    Text("Subtotal: Rp $totalProductPrice"),
                    Text("Ongkos Kirim: Rp ${widget.deliveryFee}"),
                    const Divider(),
                    Text("Total: Rp $grandTotal",
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 8),
                    const Text("📝 Catatan (Opsional)",
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _noteController,
                      decoration: const InputDecoration(
                        hintText: "Tambahkan catatan untuk penjual atau driver",
                        border: OutlineInputBorder(),
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => submitOrder(context),
                icon: const Icon(
                  Icons.check_circle_outline,
                  color: Colors.white,
                ),
                label: const Text('Checkout Sekarang',
                    style: TextStyle(fontSize: 16, color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A8754),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

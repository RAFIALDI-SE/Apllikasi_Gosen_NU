import 'package:flutter/material.dart';
import '../controllers/buyer_order_controller.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import 'buyer_order_confirmation_screen.dart';

class BuyerProductOrderScreen extends StatefulWidget {
  final int productId;
  const BuyerProductOrderScreen({super.key, required this.productId});

  @override
  State<BuyerProductOrderScreen> createState() =>
      _BuyerProductOrderScreenState();
}

class _BuyerProductOrderScreenState extends State<BuyerProductOrderScreen> {
  final Color greenNU = const Color(0xFF1A8754);
  Map<String, dynamic>? _product;
  List<dynamic> _drivers = [];
  int quantity = 1;
  int? selectedDriverId;
  bool _loading = true;
  int _totalPrice = 0;
  String? selectedDriverName;
  Map<String, dynamic>? selectedDriver;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  void updateTotalPrice() {
    if (_product != null) {
      int price =
          double.parse(_product!['price'].toString()).toInt(); // Ubah di sini
      setState(() {
        _totalPrice = quantity * price;
      });
    }
  }

  Future<void> loadData() async {
    try {
      final product =
          await BuyerOrderController.fetchProductDetail(widget.productId);
      final drivers = await BuyerOrderController.fetchAvailableDrivers();

      setState(() {
        _product = product;
        _drivers = drivers;
        quantity = 1;

        // Parsing manual ke int
        _totalPrice = quantity *
            double.parse(product['price'].toString())
                .toInt(); // Ubah di sini juga

        _loading = false;
      });
    } catch (e) {
      print("❌ Error: $e");
    }
  }

  void increaseQuantity() {
    if (quantity < _product!['stock']) {
      setState(() {
        quantity++;
        updateTotalPrice();
      });
    }
  }

  void decreaseQuantity() {
    if (quantity > 1) {
      setState(() {
        quantity--;
        updateTotalPrice();
      });
    }
  }

  void submitOrder() async {
    if (selectedDriverId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih driver terlebih dahulu')),
      );
      return;
    }

    final success = await BuyerOrderController.placeOrder(
      productId: widget.productId,
      quantity: quantity,
      driverId: selectedDriverId!,
      driverName: selectedDriverName ?? '',
      address: _product?['user']['address'] ?? 'Alamat belum ada',
      lat: _product?['user']['latitude'] ?? 0.0,
      lng: _product?['user']['longitude'] ?? 0.0,
    );

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Order berhasil dibuat')),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❌ Gagal membuat order')),
      );
    }
  }

  String formatRupiah(int number) {
    final formatter =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    return formatter.format(number);
  }

  void contactSellerViaWhatsApp() async {
    final phone = _product?['user']?['phone'];
    if (phone == null || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("❌ Nomor WhatsApp penjual tidak tersedia")),
      );
      return;
    }

    final formattedPhone = phone.replaceFirst(RegExp(r'^0'), '+62');
    final productName = _product?['name'] ?? '-';
    final price = formatRupiah(
        double.tryParse(_product?['price'].toString() ?? '0')?.toInt() ?? 0);
    final description = _product?['description'] ?? '-';
    final stock = _product?['stock']?.toString() ?? '-';
    final category = _product?['category'] ?? '-';

    final message =
        Uri.encodeComponent("Halo, saya tertarik dengan produk berikut:\n\n"
            "📦 *$productName*\n"
            "💰 Harga Satuan: $price\n"
            "🛒 Jumlah: $quantity\n"
            "🧮 Total Harga: ${formatRupiah(_totalPrice)}\n"
            "📂 Kategori: $category\n"
            "📦 Stok Tersedia: $stock\n"
            "📄 Deskripsi: $description\n\n"
            "Apakah produk ini masih tersedia?");

    final url = 'https://wa.me/$formattedPhone?text=$message';

    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("❌ Gagal membuka WhatsApp")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      appBar: AppBar(
        backgroundColor: greenNU,
        title: const Text("Order Produk"),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(12)),
                          child: Image.network(
                            'http://10.0.2.2:8000/storage/${_product?['image']}',
                            height: 200,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                height: 200,
                                color: Colors.grey.shade300,
                                child: const Center(
                                  child: Icon(
                                    Icons.broken_image,
                                    color: Colors.grey,
                                    size: 60,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _product?['name'] ?? '',
                                style: const TextStyle(
                                    fontSize: 22, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                formatRupiah(
                                  double.tryParse(
                                              _product?['price'].toString() ??
                                                  '0')
                                          ?.toInt() ??
                                      0,
                                ),
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1A8754),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text('Stok tersedia: ${_product?['stock']}'),
                              const SizedBox(height: 16),
                              const Text(
                                'Jumlah yang ingin dibeli:',
                                style: TextStyle(fontWeight: FontWeight.w500),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  IconButton(
                                    onPressed:
                                        quantity > 1 ? decreaseQuantity : null,
                                    icon:
                                        const Icon(Icons.remove_circle_outline),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 8),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                          color: Colors.grey.shade400),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text('$quantity',
                                        style: const TextStyle(fontSize: 16)),
                                  ),
                                  IconButton(
                                    onPressed: quantity < _product!['stock']
                                        ? increaseQuantity
                                        : null,
                                    icon: const Icon(Icons.add_circle_outline),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Total Harga:',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                    ),
                                  ),
                                  Text(
                                    formatRupiah(_totalPrice),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                      color: Color(0xFF1A8754),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              const Text(
                                'Driver yang akan mengantar:',
                                style: TextStyle(fontWeight: FontWeight.w500),
                              ),
                              const SizedBox(height: 8),
                              InkWell(
                                onTap: () async {
                                  final result = await Navigator.pushNamed(
                                    context,
                                    '/select-driver',
                                  );

                                  if (result != null && result is Map) {
                                    final castedResult =
                                        Map<String, dynamic>.from(result);
                                    setState(() {
                                      selectedDriverId = castedResult['id'];
                                      selectedDriverName = castedResult['name'];
                                      selectedDriver = castedResult;
                                    });
                                    print('Selected driver: $selectedDriver');
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 14),
                                  decoration: BoxDecoration(
                                    border:
                                        Border.all(color: Colors.grey.shade400),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        selectedDriverId != null
                                            ? _drivers.firstWhere((d) =>
                                                d['id'] ==
                                                selectedDriverId)['name']
                                            : 'Pilih Driver',
                                        style: TextStyle(
                                          color: selectedDriverId != null
                                              ? Colors.black
                                              : Colors.grey.shade600,
                                        ),
                                      ),
                                      const Icon(Icons.chevron_right),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const FaIcon(FontAwesomeIcons.whatsapp,
                          color: Colors.white),
                      label: const Text(
                        'Hubungi Penjual via WhatsApp',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade700,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: contactSellerViaWhatsApp,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            foregroundColor: Colors.black,
                            side: BorderSide(color: Colors.grey.shade400),
                          ),
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Batal'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: greenNU,
                            foregroundColor:
                                Colors.white, // <- warna teks putih
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          onPressed: () {
                            if (selectedDriverId == null ||
                                selectedDriverName == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                      'Silakan pilih driver terlebih dahulu.'),
                                ),
                              );
                              return;
                            }

                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    BuyerOrderConfirmationScreen(
                                  product: _product!,
                                  quantity: quantity,
                                  driverId: selectedDriverId!,
                                  driverName: selectedDriverName!,
                                  driverAddress: selectedDriver!['address'] ??
                                      '-', // ← Tambahkan ini
                                  deliveryFee: 10000,
                                ),
                              ),
                            );
                          },
                          child: const Text(
                            'Checkout',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }
}

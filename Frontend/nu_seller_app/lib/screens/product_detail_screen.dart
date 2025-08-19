import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ProductDetailScreen extends StatefulWidget {
  final int productId;

  const ProductDetailScreen({super.key, required this.productId});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  Map<String, dynamic>? product;
  bool isLoading = true;
  final Color greenNU = const Color(0xFF1A8754);

  @override
  void initState() {
    super.initState();
    fetchProductDetail();
  }

  Future<void> fetchProductDetail() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final response = await http.get(
      Uri.parse('http://10.0.2.2:8000/api/seller/products/${widget.productId}'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      setState(() {
        product = json.decode(response.body);
        isLoading = false;
      });
    } else {
      print("Gagal fetch detail produk: ${response.body}");
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        title: const Text('Detail Produk'),
        backgroundColor: greenNU,
        centerTitle: true,
        elevation: 0,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : product == null
          ? const Center(child: Text("Produk tidak ditemukan"))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 3,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Gambar Produk
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: product!['image'] != null
                      ? Image.network(
                    'http://10.0.2.2:8000/storage/${product!['image']}',
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  )
                      : Container(
                    height: 200,
                    width: double.infinity,
                    color: Colors.grey[200],
                    child: const Center(
                        child: Icon(Icons.image, size: 60)),
                  ),
                ),
                const SizedBox(height: 20),

                // Nama Produk
                Text(
                  product!['name'],
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 8),

                // Harga
                Text(
                  "Rp ${product!['price']}",
                  style: TextStyle(
                    fontSize: 20,
                    color: greenNU,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 16),

                // Kategori dan Stok
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: greenNU.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.category, size: 18, color: greenNU),
                          const SizedBox(width: 6),
                          Text(
                            product!['category_name'] ?? 'Tidak diketahui',
                            style: TextStyle(color: greenNU, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.inventory, size: 18, color: Colors.black54),
                          const SizedBox(width: 6),
                          Text(
                            "Stok: ${product!['stock']}",
                            style: const TextStyle(color: Colors.black87),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Deskripsi
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Deskripsi Produk",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: greenNU,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  product!['description'],
                  style: const TextStyle(
                    fontSize: 15,
                    color: Colors.black87,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.justify,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

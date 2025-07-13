import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:nu_seller_app/screens/edit_product_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ManageProductsScreen extends StatefulWidget {
  const ManageProductsScreen({super.key});

  @override
  State<ManageProductsScreen> createState() => _ManageProductsScreenState();
}

class _ManageProductsScreenState extends State<ManageProductsScreen> {
  List<dynamic> _products = [];
  bool _isLoading = true;

  final Color greenNU = const Color(0xFF1A8754);

  @override
  void initState() {
    super.initState();
    fetchProducts();
  }

  Future<void> fetchProducts() async {
    setState(() => _isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final response = await http.get(
      Uri.parse('http://10.0.2.2:8000/api/seller/products'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      setState(() {
        _products = json.decode(response.body);
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
      print('Gagal mengambil produk: ${response.body}');
    }
  }

  Future<void> deleteProduct(int id) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final response = await http.delete(
      Uri.parse('http://10.0.2.2:8000/api/seller/products/$id'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    print('Response: ${response.statusCode}');
    print('Body: ${response.body}');

    if (response.statusCode == 200) {
      fetchProducts(); // refresh list
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal menghapus produk')),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelola Produk'),
        backgroundColor: greenNU,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _products.isEmpty
          ? const Center(child: Text('Belum ada produk.'))
          : ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _products.length,
        itemBuilder: (context, index) {
          final product = _products[index];
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: ListTile(
              leading: product['image'] != null
                  ? Image.network(
                'http://10.0.2.2:8000/storage/${product['image']}',
                width: 50,
                height: 50,
                fit: BoxFit.cover,
              )
                  : const Icon(Icons.image_not_supported),
              title: Text(product['name']),
              subtitle: Text('Rp ${product['price']} - Stok: ${product['stock']}'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue),
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => EditProductScreen(product: product),
                        ),
                      );
                      if (result == true) {
                        fetchProducts(); // refresh setelah edit
                      }
                    },

                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Konfirmasi'),
                          content: const Text('Yakin ingin menghapus produk ini?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(ctx).pop(), // Tutup dialog
                              child: const Text('Batal'),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.of(ctx).pop(); // Tutup dialog dulu
                                deleteProduct(product['id']); // Lanjut hapus
                              },
                              child: const Text('Hapus', style: TextStyle(color: Colors.red)),
                            ),
                          ],
                        ),
                      );
                    },

                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

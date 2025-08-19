import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class BuyerProductDetailScreen extends StatefulWidget {
  const BuyerProductDetailScreen({super.key});

  @override
  State<BuyerProductDetailScreen> createState() =>
      _BuyerProductDetailScreenState();
}

class _BuyerProductDetailScreenState extends State<BuyerProductDetailScreen> {
  Map<String, dynamic>? _product;
  bool _isLoading = true;

  final Color greenNU = const Color(0xFF1A8754);
  List<dynamic> _reviews = [];
  Map<String, dynamic>? _myReview;
  TextEditingController _commentController = TextEditingController();
  int _rating = 5;
  bool _isReviewSubmitting = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final modalRoute = ModalRoute.of(context);
    if (modalRoute != null && modalRoute.settings.arguments is int) {
      final productId = modalRoute.settings.arguments as int;
      fetchProductDetail(productId);
    }
  }

  Future<void> fetchProductDetail(int productId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      final response = await http.get(
        Uri.parse('http://10.0.2.2:8000/api/buyer/products/$productId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      print("Response body: ${response.body}");

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        setState(() {
          _product = {
            'id': data['id'],
            'name': data['name'],
            'price': data['price'],
            'description': data['description'],
            'stock': data['stock'],
            'image': data['image'],
            'category': data['category']?['name'] ?? 'Kategori tidak tersedia',
            'seller': data['user']?['name'] ?? 'Penjual tidak ditemukan',
            'sellerPhone': data['user']?['phone'], // no default
          };
          _isLoading = false;
        });

        await fetchReviews(productId);
        await fetchMyReview(productId);
      } else {
        throw Exception('Gagal memuat detail produk');
      }
    } catch (e) {
      print('❌ Error saat ambil detail produk: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void contactSellerViaWhatsApp() async {
    if (_product == null || _product!['sellerPhone'] == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("❌ Nomor WhatsApp penjual belum tersedia")),
      );
      return;
    }

    final phone = _product!['sellerPhone'];
    final message =
        Uri.encodeComponent("Halo, saya tertarik dengan produk berikut:\n\n"
            "📦 *${_product!['name']}*\n"
            "💰 Harga: Rp ${_product!['price']}\n"
            "📂 Kategori: ${_product!['category']}\n"
            "📄 Deskripsi: ${_product!['description']}\n\n"
            "Apakah produk ini masih tersedia?");
    final waUrl = "https://wa.me/$phone?text=$message";

    if (await canLaunchUrl(Uri.parse(waUrl))) {
      await launchUrl(Uri.parse(waUrl), mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("❌ Gagal membuka WhatsApp")),
      );
    }
  }

  Future<void> fetchReviews(int productId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      final response = await http.get(
        Uri.parse('http://10.0.2.2:8000/api/buyer/products/$productId/reviews'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          _reviews = json.decode(response.body);
        });
      }
    } catch (e) {
      print('❌ Error fetchReviews: $e');
    }
  }

  Future<void> fetchMyReview(int productId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      final response = await http.get(
        Uri.parse(
            'http://10.0.2.2:8000/api/buyer/products/$productId/my-review'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data != null && data.isNotEmpty) {
          setState(() {
            _myReview = data;
            _rating = data['rating'];
            _commentController.text = data['comment'] ?? '';
          });
        }
      }
    } catch (e) {
      print('❌ Error fetchMyReview: $e');
    }
  }

  Future<void> submitReview(int productId) async {
    setState(() => _isReviewSubmitting = true);
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final response = await http.post(
      Uri.parse('http://10.0.2.2:8000/api/buyer/products/$productId/reviews'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
      body: {
        'rating': _rating.toString(),
        'comment': _commentController.text,
      },
    );

    setState(() => _isReviewSubmitting = false);

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Review berhasil disimpan')),
      );
      await fetchReviews(productId);
      await fetchMyReview(productId);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❌ Gagal menyimpan review')),
      );
    }
  }

  Future<void> deleteReview(int productId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

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
        _myReview = null;
        _commentController.clear();
        _rating = 5;
      });
      await fetchReviews(productId);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❌ Gagal menghapus review')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: null,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _product == null
              ? const Center(child: Text('Produk tidak ditemukan'))
              : CustomScrollView(
                  slivers: [
                    SliverAppBar(
                      expandedHeight: 300,
                      floating: false,
                      pinned: true,
                      backgroundColor: greenNU,
                      leading: BackButton(color: Colors.black),
                      title: const Text('Detail Produk'),
                      flexibleSpace: FlexibleSpaceBar(
                        background: _product!['image'] != null
                            ? Image.network(
                                'http://10.0.2.2:8000/storage/${_product!['image']}',
                                fit: BoxFit.cover,
                              )
                            : Container(
                                color: Colors.grey[300],
                                child: const Icon(Icons.image, size: 80),
                              ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _product!['name'],
                              style: const TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "Rp ${_product!['price']}",
                              style: const TextStyle(
                                fontSize: 22,
                                color: Colors.green,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                Chip(
                                  avatar: const Icon(Icons.store, size: 16),
                                  label:
                                      Text("Penjual: ${_product!['seller']}"),
                                  backgroundColor: Colors.grey.shade100,
                                ),
                                Chip(
                                  avatar: const Icon(Icons.category, size: 16),
                                  label: Text(
                                      "Kategori: ${_product!['category']}"),
                                  backgroundColor: Colors.grey.shade100,
                                ),
                                Chip(
                                  avatar: const Icon(Icons.inventory, size: 16),
                                  label: Text("Stok: ${_product!['stock']}"),
                                  backgroundColor: Colors.grey.shade100,
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            const Text(
                              'Deskripsi Produk',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 18),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _product!['description'] ?? '-',
                              style: const TextStyle(fontSize: 15),
                            ),
                            const SizedBox(height: 24),

                            // Tombol WhatsApp
                            if (_product!['sellerPhone'] != null)
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  icon: const FaIcon(FontAwesomeIcons.whatsapp),
                                  label: const Text("Hubungi via WhatsApp"),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green.shade700,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 14),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  onPressed: contactSellerViaWhatsApp,
                                ),
                              ),

                            const SizedBox(height: 30),
                            const Divider(),
                            const SizedBox(height: 10),

                            const Text(
                              'Ulasan Produk',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 18),
                            ),
                            const SizedBox(height: 8),

                            // My Review
                            if (_myReview != null)
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Ulasan Anda',
                                      style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500)),
                                  TextButton.icon(
                                    onPressed: () =>
                                        deleteReview(_product!['id']),
                                    icon: const Icon(Icons.delete,
                                        color: Colors.red),
                                    label: const Text("Hapus",
                                        style: TextStyle(color: Colors.red)),
                                  )
                                ],
                              )
                            else
                              const Text('Tulis Ulasan',
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500)),

                            const SizedBox(height: 8),
                            Row(
                              children: List.generate(5, (index) {
                                return IconButton(
                                  icon: Icon(
                                    index < _rating
                                        ? Icons.star
                                        : Icons.star_border,
                                    color: Colors.amber,
                                  ),
                                  onPressed: () {
                                    setState(() => _rating = index + 1);
                                  },
                                );
                              }),
                            ),

                            TextField(
                              controller: _commentController,
                              maxLines: 3,
                              decoration: InputDecoration(
                                hintText: 'Tulis komentar kamu...',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                fillColor: Colors.grey.shade100,
                                filled: true,
                              ),
                            ),
                            const SizedBox(height: 10),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _isReviewSubmitting
                                    ? null
                                    : () => submitReview(_product!['id']),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: greenNU,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: Text(_myReview == null
                                    ? 'Kirim Ulasan'
                                    : 'Perbarui Ulasan'),
                              ),
                            ),
                            const SizedBox(height: 20),
                            if (_reviews.isEmpty)
                              const Text("Belum ada ulasan")
                            else
                              ..._reviews.map(
                                (review) => Card(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  elevation: 1,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            review['buyer']
                                                        ['profile_picture'] !=
                                                    null
                                                ? CircleAvatar(
                                                    radius: 14,
                                                    backgroundImage:
                                                        NetworkImage(
                                                      'http://10.0.2.2:8000/storage/${review['buyer']['profile_picture']}',
                                                    ),
                                                  )
                                                : const CircleAvatar(
                                                    radius: 14,
                                                    child: Icon(Icons.person,
                                                        size: 16),
                                                  ),
                                            const SizedBox(width: 8),
                                            Text(
                                              review['buyer']['name'],
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: List.generate(
                                            5,
                                            (index) => Icon(
                                              index < review['rating']
                                                  ? Icons.star
                                                  : Icons.star_border,
                                              color: Colors.amber,
                                              size: 16,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          review['comment'] ?? '',
                                          style: const TextStyle(fontSize: 14),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              )
                          ],
                        ),
                      ),
                    )
                  ],
                ),
    );
  }
}

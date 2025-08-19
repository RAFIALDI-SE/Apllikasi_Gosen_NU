import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../controllers/auth_controller.dart';
import '../controllers/profile_controller.dart';
import 'dart:async';

class SellerHomeScreen extends StatefulWidget {
  const SellerHomeScreen({super.key});

  @override
  State<SellerHomeScreen> createState() => _SellerHomeScreenState();
}

class _SellerHomeScreenState extends State<SellerHomeScreen> {
  final Color greenNU = const Color(0xFF1A8754);
  List<dynamic> _products = [];
  final ProfileController _profileController = ProfileController();
  bool _isLoading = true;
  bool _loadingProfile = true;

  int _unreadCount = 0;

  Map<String, dynamic>? _userData;

  Timer? _notifTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      fetchProducts();
      fetchProfile();
      fetchUnreadCount();

      // polling setiap 15 detik
      _notifTimer = Timer.periodic(Duration(seconds: 3), (_) {
        fetchUnreadCount();
      });
    });
  }

  @override
  void dispose() {
    _notifTimer?.cancel();
    super.dispose();
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
      print('Gagal mengambil data produk: ${response.body}');
    }
  }

  Future<void> fetchProfile() async {
    try {
      final data = await _profileController.fetchCurrentUser();
      print("✅ DATA PROFILE DIDAPAT: $data"); // Debug

      setState(() {
        _userData = data;
        _loadingProfile = false;
      });
    } catch (e) {
      print("❌ Gagal ambil profil: $e");
      setState(() => _loadingProfile = false);
    }
  }

  Future<void> fetchUnreadCount() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    try {
      final response = await http.get(
        Uri.parse('http://10.0.2.2:8000/api/seller/notifications/unread-count'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        final int count = decoded['count'] ?? 0;

        setState(() {
          _unreadCount = count;
        });

        print("Unread count: $_unreadCount");
      } else {
        print("Gagal ambil unread count: ${response.body}");
      }
    } catch (e) {
      print("Error ambil unread count: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Seller'),
        backgroundColor: greenNU,
        centerTitle: true,
      ),
      drawer: Drawer(
        child: RefreshIndicator(
          onRefresh: () async {
            await fetchProfile();
            await fetchUnreadCount();
          },
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              DrawerHeader(
                decoration: BoxDecoration(color: greenNU),
                child: _loadingProfile
                    ? const Center(
                        child: CircularProgressIndicator(color: Colors.white))
                    : Row(
                        children: [
                          if (_userData?['profile_picture'] != null &&
                              _userData!['profile_picture']
                                  .toString()
                                  .isNotEmpty)
                            CircleAvatar(
                              radius: 30,
                              backgroundColor: Colors.white,
                              child: ClipOval(
                                child: Image.network(
                                  _userData!['profile_picture'],
                                  width: 60,
                                  height: 60,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return const Icon(Icons.person,
                                        size: 30, color: Colors.grey);
                                  },
                                ),
                              ),
                            )
                          else
                            const CircleAvatar(
                              radius: 30,
                              backgroundColor: Colors.white,
                              child: Icon(Icons.person,
                                  size: 30, color: Colors.grey),
                            ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Halo, ${_userData?['name'] ?? 'Penjual'}!',
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 18),
                            ),
                          ),
                        ],
                      ),
              ),
              ListTile(
                leading: const Icon(Icons.person),
                title: const Text('Profil Saya'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/profile');
                },
              ),
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Edit Profil'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/edit-profile');
                },
              ),
              ListTile(
                leading: const Icon(Icons.inventory),
                title: const Text('Kelola Produk'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/manage-products');
                },
              ),
              ListTile(
                leading: const Icon(Icons.shopping_bag),
                title: const Text('Pesanan Masuk'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/seller-orders');
                },
              ),
              ListTile(
                leading: Stack(
                  children: [
                    const Icon(Icons.notifications),
                    if (_unreadCount > 0)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 18,
                            minHeight: 18,
                          ),
                          child: Text(
                            '$_unreadCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
                title: const Text('Notifikasi'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/notifications').then((_) {
                    fetchUnreadCount();
                  });
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.logout),
                title: const Text('Logout'),
                onTap: () async {
                  Navigator.pop(context);
                  await AuthController.logout(context);
                },
              ),
            ],
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _products.isEmpty
              ? const Center(child: Text('Belum ada produk.'))
              : RefreshIndicator(
                  onRefresh: fetchProducts,
                  child: GridView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _products.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.7,
                    ),
                    itemBuilder: (context, index) {
                      final product = _products[index];
                      return GestureDetector(
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            '/product-detail',
                            arguments: product['id'],
                          );
                        },
                        child: Card(
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(12)),
                                  child: product['image'] != null
                                      ? Image.network(
                                          'http://10.0.2.2:8000/storage/${product['image']}',
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, stackTrace) {
                                            return Container(
                                              color: Colors.grey[200],
                                              child: const Center(
                                                child: Icon(Icons.broken_image,
                                                    size: 40,
                                                    color: Colors.grey),
                                              ),
                                            );
                                          },
                                        )
                                      : Container(
                                          color: Colors.grey[200],
                                          child: const Center(
                                            child: Icon(
                                                Icons.image_not_supported,
                                                size: 40),
                                          ),
                                        ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      product['name'],
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16),
                                    ),
                                    const SizedBox(height: 4),
                                    Text('Rp ${product['price']}',
                                        style: const TextStyle(fontSize: 14)),
                                    Text('Stok: ${product['stock']}',
                                        style: const TextStyle(fontSize: 13)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.pushNamed(context, '/add-product');
          if (result == true) {
            fetchProducts(); // refresh data jika tambah produk berhasil
          }
        },
        backgroundColor: greenNU,
        icon: const Icon(Icons.add),
        label: const Text('Tambah Produk'),
      ),
    );
  }
}

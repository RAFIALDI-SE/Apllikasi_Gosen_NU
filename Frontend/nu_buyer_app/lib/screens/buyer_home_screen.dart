import 'dart:convert';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../controllers/buyer_auth_controller.dart';
import '../controllers/buyer_favorite_controller.dart';
import '../controllers/buyer_profile_controller.dart';
import 'package:share_plus/share_plus.dart';

class BuyerHomeScreen extends StatefulWidget {
  const BuyerHomeScreen({super.key});

  @override
  State<BuyerHomeScreen> createState() => _BuyerHomeScreenState();
}

class _BuyerHomeScreenState extends State<BuyerHomeScreen> {
  final Color greenNU = const Color(0xFF1A8754);
  final auth = BuyerAuthController();

  List<dynamic> _products = [];
  List<dynamic> _events = [];
  final TextEditingController _searchController = TextEditingController();
  final ProfileController _profileController = ProfileController();

  bool _isLoading = true;
  bool _loadingProfile = true;

  String searchQuery = '';
  Map<String, dynamic>? _userData;

  List<int> favoriteProductIds = [];
  String token = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await fetchProfile(); // token diset di sini
      await fetchFavorites(); // baru fetch favorites dengan token valid
      await fetchData(); // ambil produk dan event
    });
  }

  Future<void> fetchData() async {
    await Future.wait([
      fetchProducts(),
      fetchEvents(),
    ]);
  }

  Future<void> fetchProducts() async {
    try {
      setState(() => _isLoading = true);
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) throw Exception("Token tidak ditemukan");

      final queryParams = {
        if (searchQuery.isNotEmpty) 'search': searchQuery,
      };

      final uri = Uri.http('10.0.2.2:8000', '/api/buyer/products', queryParams);
      final response = await http.get(uri, headers: {
        'Authorization': 'Bearer $token',
      });

      if (response.statusCode == 200) {
        setState(() {
          _products = json.decode(response.body);
          _isLoading = false;
        });
      } else {
        throw Exception("Gagal ambil produk");
      }
    } catch (e) {
      print("❌ Error fetchProducts: $e");
      setState(() => _isLoading = false);
    }
  }

  Future<void> fetchEvents() async {
    try {
      final response =
          await http.get(Uri.parse('http://10.0.2.2:8000/api/events'));
      if (response.statusCode == 200) {
        setState(() {
          _events = json.decode(response.body);
        });
      }
    } catch (e) {
      print("❌ Error fetchEvents: $e");
    }
  }

  Future<void> fetchProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      token = prefs.getString('token') ?? '';
      final data = await _profileController.fetchCurrentUser();
      print("✅ DATA PROFILE DIDAPAT: $data");

      setState(() {
        _userData = data;
        _loadingProfile = false;
      });
    } catch (e) {
      print("❌ Gagal ambil profil: $e");
      setState(() => _loadingProfile = false);
    }
  }

  Future<void> fetchFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      final response = await http.get(
        Uri.parse('http://10.0.2.2:8000/api/buyer/favorites'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        final List data = decoded['favorites'];

        setState(() {
          favoriteProductIds =
              data.map<int>((item) => item['id'] as int).toList();
        });
      } else {
        print(
            "❌ fetchFavorites failed: ${response.statusCode} ${response.body}");
      }
    } catch (e) {
      print("❌ Exception fetchFavorites: $e");
    }
  }

  Future<bool> removeFromFavorites(int productId) async {
    final response = await http.delete(
      Uri.parse('http://10.0.2.2:8000/api/buyer/favorites/$productId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    return response.statusCode == 200;
  }

  Future<void> _shareProductLink(int productId) async {
    final String productUrl =
        'http://10.0.2.2:8000/api/buyer/products/$productId';

    await Share.share(
      'Cek produk ini bro: $productUrl',
      subject: 'Produk Keren di WarNu!',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9F7),
      appBar: AppBar(
        backgroundColor: greenNU,
        title: Center(
          child: const Text(
            'WarNu',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle),
            onPressed: () {
              Navigator.pushNamed(context, '/buyer-profile'); // buka drawer
            },
          ),
        ],
      ),
      drawer: buildDrawer(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: fetchProducts,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    buildCarousel(),
                    const SizedBox(height: 16),
                    buildSearchBar(),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'Produk Terbaru',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    buildProductGrid(),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
    );
  }

  Drawer buildDrawer() {
    return Drawer(
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
                          _userData!['profile_picture'].toString().isNotEmpty)
                        CircleAvatar(
                          radius: 30,
                          backgroundImage:
                              NetworkImage(_userData!['profile_picture']),
                        )
                      else
                        const CircleAvatar(
                          radius: 30,
                          backgroundColor: Colors.white,
                          child:
                              Icon(Icons.person, size: 30, color: Colors.grey),
                        ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Halo, ${_userData?['name'] ?? 'Pembeli'}!',
                          style: const TextStyle(
                              color: Colors.white, fontSize: 18),
                        ),
                      ),
                    ],
                  ),
          ),
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text('Beranda'),
            onTap: () {
              Navigator.pushNamed(context, '/buyer-profile');
            },
          ),
          ListTile(
            leading: const Icon(Icons.person_pin),
            title: const Text('Edit Profil'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/buyer-edit-profile');
            },
          ),
          ListTile(
            leading: const Icon(Icons.history),
            title: const Text('Riwayat Pembelian'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/buyer-order-history');
            },
          ),
          ListTile(
            leading: const Icon(Icons.bookmark),
            title: const Text('Favorit'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/buyer-favorites').then((_) async {
                await fetchFavorites();
                await fetchProducts();
              });
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Logout'),
            onTap: () {
              Navigator.pop(context);
              auth.logout(context);
            },
          ),
        ],
      ),
    );
  }

  Widget buildCarousel() {
    return CarouselSlider(
      options: CarouselOptions(
        height: 160,
        autoPlay: true,
        enlargeCenterPage: true,
        viewportFraction: 0.9,
      ),
      items: _events.map((event) {
        return GestureDetector(
          onTap: () {
            Navigator.pushNamed(context, '/event-detail',
                arguments: event['id']);
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.network(
                  'http://10.0.2.2:8000/storage/${event['image']}',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[300],
                      alignment: Alignment.center,
                      child: const Icon(Icons.broken_image,
                          size: 50, color: Colors.grey),
                    );
                  },
                ),
                Container(
                  color: Colors.black.withOpacity(0.3),
                  alignment: Alignment.center,
                  child: Text(
                    event['title'] ?? '',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                )
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: TextField(
        controller: _searchController,
        onChanged: (value) {
          searchQuery = value;
          fetchProducts();
        },
        decoration: InputDecoration(
          hintText: 'Cari produk...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      searchQuery = '';
                    });
                    fetchProducts();
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
        ),
      ),
    );
  }

  Widget buildProductGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _products.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.72,
        ),
        itemBuilder: (context, index) {
          final product = _products[index];
          final bool isFavorited = favoriteProductIds.contains(product['id']);
          return GestureDetector(
            onTap: () {
              Navigator.pushNamed(
                context,
                '/buyer-product-detail',
                arguments: product['id'],
              );
            },
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(12)),
                          child: Image.network(
                            'http://10.0.2.2:8000/storage/${product['image']}',
                            fit: BoxFit.cover,
                            width: double.infinity,
                            errorBuilder: (context, error, stackTrace) {
                              return const Center(
                                child: Icon(Icons.broken_image,
                                    size: 50, color: Colors.grey),
                              );
                            },
                          ),
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Row(
                            children: [
                              // Tombol Share
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.8),
                                  shape: BoxShape.circle,
                                ),
                                child: IconButton(
                                  icon: const Icon(Icons.share,
                                      color: Colors.grey),
                                  onPressed: () {
                                    // Panggil fungsi share dengan product ID
                                    _shareProductLink(product['id']);
                                  },
                                ),
                              ),
                              const SizedBox(
                                  width: 4), // Jarak antara dua tombol
                              // Tombol Favorit
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.8),
                                  shape: BoxShape.circle,
                                ),
                                child: IconButton(
                                  icon: Icon(
                                    isFavorited
                                        ? Icons.bookmark
                                        : Icons.bookmark_border,
                                    color: isFavorited
                                        ? Colors.black
                                        : Colors.grey,
                                  ),
                                  onPressed: () async {
                                    bool success;

                                    if (isFavorited) {
                                      success = await removeFromFavorites(
                                          product['id']);
                                      if (success) {
                                        setState(() {
                                          favoriteProductIds
                                              .remove(product['id']);
                                        });
                                      }
                                    } else {
                                      success = await FavoriteController
                                          .addToFavorites(
                                        product['id'],
                                        token,
                                      );
                                      if (success) {
                                        setState(() {
                                          favoriteProductIds.add(product['id']);
                                        });
                                      }
                                    }

                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(success
                                            ? 'Favorit ${isFavorited ? 'dihapus' : 'ditambahkan'}'
                                            : 'Gagal mengubah favorit'),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product['name'],
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Rp ${product['price']}",
                          style: const TextStyle(
                              color: Colors.green, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          product['user']['name'] ?? '',
                          style:
                              const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: greenNU,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(double.infinity, 36),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: () {
                            Navigator.pushNamed(
                              context,
                              '/buyer-order-product',
                              arguments: product['id'],
                            );
                          },
                          child: const Text('Order Sekarang'),
                        ),
                      ],
                    ),
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

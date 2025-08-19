import 'package:flutter/material.dart';
import '../controllers/driver_auth_controller.dart';
import '../controllers/driver_profile_controller.dart';
import '../controllers/driver_status_controller.dart';
import 'driver_profile_screen.dart';
import 'driver_today_orders_screen.dart'; // ⬅️ Tambahkan ini (pastikan path sesuai)
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'dart:async'; // ✅ untuk Timer

class DriverHomeScreen extends StatefulWidget {
  const DriverHomeScreen({super.key});

  @override
  State<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends State<DriverHomeScreen> {
  int _selectedIndex = 0;
  bool _isActive = false;
  bool _isLoadingStatus = true;

  final Color primaryColor = const Color(0xFF0066CC);

  Map<String, dynamic>? _driverData;
  bool _loadingDriver = true;

  LatLng? _driverLocation; // ✅ untuk menyimpan lokasi driver

  @override
  void initState() {
    super.initState();
    _loadDriverStatus();
    fetchDriverProfile();
    _fetchDriverLocationPeriodically();
  }

  Timer? _locationTimer;

  @override
  void dispose() {
    _locationTimer?.cancel();
    super.dispose();
  }

  Future<void> fetchDriverProfile() async {
    try {
      final profile = await ProfileController().fetchCurrentUser();
      setState(() {
        _driverData = profile;
        _loadingDriver = false;
      });
    } catch (e) {
      print("❌ Gagal ambil data driver: $e");
      setState(() => _loadingDriver = false);
    }
  }

  Future<void> _loadDriverStatus() async {
    try {
      bool status = await DriverStatusController().getStatus();
      setState(() {
        _isActive = status;
        _isLoadingStatus = false;
      });
    } catch (e) {
      setState(() => _isLoadingStatus = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal mengambil status driver')),
      );
    }
  }

  Future<void> _toggleDriverStatus(bool newStatus) async {
    setState(() => _isLoadingStatus = true);
    try {
      bool updatedStatus =
          await DriverStatusController().toggleStatus(newStatus);
      setState(() {
        _isActive = updatedStatus;
        _isLoadingStatus = false;
      });
    } catch (e) {
      setState(() => _isLoadingStatus = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal mengubah status')),
      );
    }
  }

  void _fetchDriverLocationPeriodically() {
    _locationTimer = Timer.periodic(const Duration(seconds: 10), (timer) async {
      LatLng? location = await DriverStatusController().fetchDriverLocation();
      if (mounted && location != null) {
        setState(() {
          _driverLocation = location;
        });
      }
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        return _buildHomeContent();
      case 1:
        return const DriverTodayOrdersScreen(); // Bisa diganti screen nanti
      case 2:
        return const DriverProfileScreen(); // ✅ Ganti jadi screen driver profil
      default:
        return const Center(child: Text('Halaman tidak ditemukan'));
    }
  }

  Widget _buildHomeContent() {
    return Stack(
      children: [
        // === BACKGROUND MAP ===
        Positioned.fill(
          child: _driverLocation != null
              ? FlutterMap(
                  options: MapOptions(
                    initialCenter: _driverLocation!,
                    initialZoom: 15.0,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.nu_driver_app',
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          width: 60.0,
                          height: 60.0,
                          point: _driverLocation!,
                          child: const Icon(Icons.my_location,
                              color: Colors.red, size: 40),
                        ),
                      ],
                    ),
                  ],
                )
              : const Center(child: CircularProgressIndicator()),
        ),

        // === OVERLAY UI ===
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Card(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  elevation: 8,
                  color: Colors.white.withOpacity(0.95),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _loadingDriver
                            ? const CircularProgressIndicator()
                            : Row(
                                children: [
                                  CircleAvatar(
                                    radius: 24,
                                    backgroundColor: Colors.grey[200],
                                    backgroundImage:
                                        _driverData?['profile_picture'] != null
                                            ? NetworkImage(
                                                _driverData!['profile_picture'])
                                            : null,
                                    child:
                                        _driverData?['profile_picture'] == null
                                            ? const Icon(Icons.person,
                                                color: Colors.grey)
                                            : null,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Halo, ${_driverData?['name'] ?? 'Driver'}',
                                          style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          _isActive
                                              ? 'Status: Aktif'
                                              : 'Status: Tidak Aktif',
                                          style: TextStyle(
                                              fontSize: 14,
                                              color: _isActive
                                                  ? Colors.green
                                                  : Colors.grey),
                                        ),
                                      ],
                                    ),
                                  ),
                                  _isLoadingStatus
                                      ? const CircularProgressIndicator()
                                      : Switch(
                                          value: _isActive,
                                          onChanged: (val) =>
                                              _toggleDriverStatus(val),
                                          activeColor: Colors.green,
                                        ),
                                ],
                              ),
                        const Divider(height: 24),
                        const Text(
                          'Siap menerima pesanan hari ini?',
                          style: TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Driver Home'),
        backgroundColor: primaryColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await DriverAuthController().logout(context);
              Navigator.pushReplacementNamed(context, '/driver/login');
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: primaryColor),
              child: _loadingDriver
                  ? const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    )
                  : Row(
                      children: [
                        if (_driverData?['profile_picture'] != null &&
                            _driverData!['profile_picture']
                                .toString()
                                .isNotEmpty)
                          CircleAvatar(
                            radius: 30,
                            backgroundImage:
                                NetworkImage(_driverData!['profile_picture']),
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
                            'Halo, ${_driverData?['name'] ?? 'Driver'}!',
                            style: const TextStyle(
                                color: Colors.white, fontSize: 18),
                          ),
                        ),
                      ],
                    ),
            ),
            _isLoadingStatus
                ? const Center(child: CircularProgressIndicator())
                : SwitchListTile(
                    title: const Text('Status Aktif'),
                    value: _isActive,
                    onChanged: (val) => _toggleDriverStatus(val),
                    secondary: Icon(
                      _isActive ? Icons.toggle_on : Icons.toggle_off,
                      color: _isActive ? Colors.green : Colors.grey,
                      size: 30,
                    ),
                  ),
            ListTile(
              leading: const Icon(Icons.person_pin),
              title: const Text('Edit Profil'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/driver-edit-profile');
              },
            ),
            ListTile(
              leading: const Icon(Icons.history),
              title: const Text('Riwayat Pengantaran'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/driver-history');
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Pengaturan'),
              onTap: () {},
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: () async {
                await DriverAuthController().logout(context);
                Navigator.pushReplacementNamed(context, '/driver/login');
              },
            ),
          ],
        ),
      ),
      body: _buildBody(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: primaryColor,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Beranda'),
          BottomNavigationBarItem(
              icon: Icon(Icons.assignment), label: 'Pesanan'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
        ],
      ),
    );
  }
}

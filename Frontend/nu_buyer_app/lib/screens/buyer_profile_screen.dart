import 'package:flutter/material.dart';
import '../controllers/buyer_profile_controller.dart';

class BuyerProfileScreen extends StatefulWidget {
  const BuyerProfileScreen({super.key});

  @override
  State<BuyerProfileScreen> createState() => _BuyerProfileScreenState();
}

class _BuyerProfileScreenState extends State<BuyerProfileScreen> {
  final ProfileController _profileController = ProfileController();
  Map<String, dynamic>? _userData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    loadProfile();
  }

  Future<void> loadProfile() async {
    final data = await _profileController.fetchCurrentUser();
    setState(() {
      _userData = data;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final Color greenNU = const Color(0xFF1A8754);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil Saya'),
        backgroundColor: greenNU,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _userData == null
              ? const Center(child: Text("Gagal memuat data profil"))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.grey[300],
                        backgroundImage: _userData!['profile_picture'] != null
                            ? NetworkImage(
                                _userData!['profile_picture']) // langsung pakai
                            : null,
                        child: _userData!['profile_picture'] == null
                            ? const Icon(Icons.person,
                                size: 50, color: Colors.white)
                            : null,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _userData!['name'] ?? '-',
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _userData!['email'] ?? '-',
                        style: const TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 20),
                      Card(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 4,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildInfoTile('Role', _userData!['role']),
                              _buildInfoTile('Telepon', _userData!['phone']),
                              _buildInfoTile('Alamat', _userData!['address']),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: greenNU,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                        ),
                        icon: const Icon(Icons.edit),
                        label: const Text("Edit Profil"),
                        onPressed: () {
                          Navigator.pushNamed(context, '/buyer-edit-profile');
                        },
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildInfoTile(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
              child: Text(label,
                  style: const TextStyle(fontWeight: FontWeight.w600))),
          Expanded(child: Text(value ?? '-', textAlign: TextAlign.right)),
        ],
      ),
    );
  }
}

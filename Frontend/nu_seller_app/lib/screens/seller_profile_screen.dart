import 'package:flutter/material.dart';
import 'package:nu_seller_app/controllers/profile_controller.dart';

class SellerProfileScreen extends StatefulWidget {
  const SellerProfileScreen({super.key});

  @override
  State<SellerProfileScreen> createState() => _SellerProfileScreenState();
}

class _SellerProfileScreenState extends State<SellerProfileScreen> {
  Map<String, dynamic>? user;

  final Color greenNU = const Color(0xFF1A8754);

  @override
  void initState() {
    super.initState();
    loadUserProfile();
  }

  Future<void> loadUserProfile() async {
    final profile = await ProfileController().fetchCurrentUser();
    if (profile != null) {
      setState(() => user = profile);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Profil Saya"),
        backgroundColor: greenNU,
        centerTitle: true,
      ),
      body: user == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Foto profil
            Center(
              child: CircleAvatar(
                radius: 50,
                backgroundImage: user!['profile_picture'] != null
                    ? NetworkImage(user!['profile_picture'])
                    : const AssetImage('assets/default_avatar.png') as ImageProvider,
              ),
            ),
            const SizedBox(height: 20),

            // Card Informasi
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    profileRow(Icons.person, 'Nama', user!['name']),
                    profileRow(Icons.email, 'Email', user!['email']),
                    profileRow(Icons.phone, 'Telepon', user!['phone'] ?? '-'),
                    profileRow(Icons.location_on, 'Alamat', user!['address'] ?? '-'),
                    profileRow(Icons.person_pin, 'Role', user!['role']),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget profileRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: greenNU),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 13, color: Colors.black54, fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(value,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

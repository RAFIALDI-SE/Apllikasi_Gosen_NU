import 'package:flutter/material.dart';
import '../controllers/driver_profile_controller.dart';

class DriverProfileScreen extends StatefulWidget {
  const DriverProfileScreen({super.key});

  @override
  State<DriverProfileScreen> createState() => _DriverProfileScreenState();
}

class _DriverProfileScreenState extends State<DriverProfileScreen> {
  Map<String, dynamic>? user;
  final Color primaryColor = const Color(0xFF0066CC); // Warna biru utama

  @override
  void initState() {
    super.initState();
    loadUserProfile();
  }

  Future<void> loadUserProfile() async {
    final profile = await ProfileController().fetchCurrentUser();
    if (mounted && profile != null) {
      setState(() => user = profile);
    }
  }

  Future<void> refreshUserProfile() async {
    await loadUserProfile();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: user == null
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: RefreshIndicator(
                onRefresh: refreshUserProfile,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      // Foto Profil
                      Center(
                        child: CircleAvatar(
                          radius: 50,
                          backgroundColor: user!['profile_picture'] != null
                              ? Colors.transparent
                              : primaryColor,
                          backgroundImage: user!['profile_picture'] != null
                              ? NetworkImage(user!['profile_picture'])
                              : null,
                          child: user!['profile_picture'] == null
                              ? const Icon(
                                  Icons.person,
                                  size: 50,
                                  color: Colors.white,
                                )
                              : null,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Nama dan Role
                      Text(
                        user!['name'] ?? '',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                      Text(
                        "Driver",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Kartu Informasi
                      Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            children: [
                              profileItem(Icons.email, "Email", user!['email']),
                              const Divider(),
                              profileItem(Icons.phone, "Telepon",
                                  user!['phone'] ?? '-'),
                              const Divider(),
                              profileItem(Icons.location_on, "Alamat",
                                  user!['address'] ?? '-'),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Tombol Edit Profil
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pushNamed(context, '/driver-edit-profile')
                                .then((_) =>
                                    loadUserProfile()); // Refresh setelah kembali
                          },
                          icon: const Icon(Icons.edit, color: Colors.white),
                          label: const Text(
                            "Edit Profil",
                            style: TextStyle(color: Colors.white),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget profileItem(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: primaryColor, size: 20),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      fontSize: 13,
                      color: Colors.black54,
                      fontWeight: FontWeight.w500)),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SellerEditProfileScreen extends StatefulWidget {
  const SellerEditProfileScreen({super.key});

  @override
  State<SellerEditProfileScreen> createState() =>
      _SellerEditProfileScreenState();
}

class _SellerEditProfileScreenState extends State<SellerEditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final Color greenNU = const Color(0xFF1A8754);

  // Controller input
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();

  File? _profileImage, _ktpImage, _bannerImage;

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchProfileData();
  }

  Future<void> _fetchProfileData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      final response = await http.get(
        Uri.parse('http://10.0.2.2:8000/api/seller/me'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body)['user'];
        setState(() {
          _nameController.text = data['name'] ?? '';
          _phoneController.text = data['phone'] ?? '';
          _addressController.text = data['address'] ?? '';
          _latitudeController.text = data['latitude']?.toString() ?? '';
          _longitudeController.text = data['longitude']?.toString() ?? '';
          _isLoading = false;
        });
      } else {
        throw Exception("Gagal memuat data profil");
      }
    } catch (e) {
      debugPrint("Error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal memuat profil')),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final uri = Uri.parse('http://10.0.2.2:8000/api/seller/me/update');
    final request = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] = 'Bearer $token'
      ..fields['name'] = _nameController.text
      ..fields['phone'] = _phoneController.text
      ..fields['address'] = _addressController.text
      ..fields['latitude'] = _latitudeController.text
      ..fields['longitude'] = _longitudeController.text;

    if (_profileImage != null) {
      request.files.add(await http.MultipartFile.fromPath(
        'profile_picture',
        _profileImage!.path,
      ));
    }
    if (_ktpImage != null) {
      request.files
          .add(await http.MultipartFile.fromPath('ktp_photo', _ktpImage!.path));
    }
    if (_bannerImage != null) {
      request.files.add(await http.MultipartFile.fromPath(
          'store_banner', _bannerImage!.path));
    }

    final response = await request.send();
    if (response.statusCode == 200) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profil berhasil diperbarui')),
        );
        Navigator.pop(context);
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal memperbarui profil')),
        );
      }
    }
  }

  Future<void> _pickImage(ImageSource source, Function(File) onSelected) async {
    final picked = await ImagePicker().pickImage(source: source);
    if (picked != null) onSelected(File(picked.path));
  }

  Widget _buildTextField(String label, TextEditingController controller,
      {TextInputType keyboardType = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Colors.white,
        ),
        validator: (val) =>
            val == null || val.isEmpty ? '$label wajib diisi' : null,
      ),
    );
  }

  Widget _buildImageInput(String label, File? image, Function(File) onPick) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Row(
          children: [
            if (image != null)
              Image.file(image, width: 80, height: 80, fit: BoxFit.cover)
            else
              Container(
                width: 80,
                height: 80,
                color: Colors.grey[300],
                child: const Icon(Icons.image, size: 40),
              ),
            const SizedBox(width: 12),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: greenNU),
              onPressed: () => _pickImage(ImageSource.gallery, onPick),
              child: const Text("Pilih Gambar"),
            ),
          ],
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profil'),
        backgroundColor: greenNU,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    _buildImageInput("Foto Profil", _profileImage,
                        (f) => setState(() => _profileImage = f)),
                    _buildImageInput("Foto KTP", _ktpImage,
                        (f) => setState(() => _ktpImage = f)),
                    _buildImageInput("Banner Toko", _bannerImage,
                        (f) => setState(() => _bannerImage = f)),
                    _buildTextField("Nama Lengkap", _nameController),
                    _buildTextField("No. Telepon", _phoneController),
                    _buildTextField("Alamat", _addressController),
                    _buildTextField("Latitude", _latitudeController,
                        keyboardType: TextInputType.number),
                    _buildTextField("Longitude", _longitudeController,
                        keyboardType: TextInputType.number),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: greenNU,
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _updateProfile,
                      icon: const Icon(Icons.save),
                      label: const Text("Simpan Perubahan"),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

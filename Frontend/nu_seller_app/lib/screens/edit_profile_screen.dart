import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

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

  bool _isGettingLocation = false;

  List<dynamic> _districts = [];
  List<dynamic> _villages = [];

  String? _selectedDistrictId;
  String? _selectedVillageId;

  @override
  void initState() {
    super.initState();
    _loadDistricts().then((_) {
      _fetchProfileData();
    });
  }

  Future<void> _fetchProfileData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    final response = await http.get(
      Uri.parse('http://10.0.2.2:8000/api/seller/me'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      String? districtId = data['user']['district_id']?.toString();
      String? villageId = data['user']['village_id']?.toString();

      if (districtId != null) {
        await _loadVillages(districtId);
      }

      setState(() {
        _nameController.text = data['user']['name'] ?? '';
        _phoneController.text = data['user']['phone'] ?? '';
        _addressController.text = data['user']['address'] ?? '';
        _latitudeController.text = data['user']['latitude']?.toString() ?? '';
        _longitudeController.text = data['user']['longitude']?.toString() ?? '';

        _selectedDistrictId = districtId;
        _selectedVillageId = villageId;

        _isLoading = false;
      });
    } else {
      print('Failed to fetch profile data: ${response.body}');
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
      ..fields['district_id'] = _selectedDistrictId ?? ''
      ..fields['village_id'] = _selectedVillageId ?? ''
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

    if (_selectedDistrictId != null) {
      request.fields['district_id'] = _selectedDistrictId!;
    }
    if (_selectedVillageId != null) {
      request.fields['village_id'] = _selectedVillageId!;
    }

    final response = await request.send();
    final responseBody = await response.stream.bytesToString();
    print("STATUS: ${response.statusCode}");
    print("BODY: $responseBody");
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

  Future<void> _ambilAlamatOtomatis() async {
    setState(() => _isGettingLocation = true);

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception("Layanan lokasi belum aktif");
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception("Izin lokasi ditolak");
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception("Izin lokasi ditolak permanen");
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      final placemark = placemarks.first;

      setState(() {
        _latitudeController.text = position.latitude.toString();
        _longitudeController.text = position.longitude.toString();
        _addressController.text =
            '${placemark.street}, ${placemark.subLocality}, ${placemark.locality}, ${placemark.administrativeArea}';
      });
    } catch (e) {
      debugPrint("❌ Error ambil lokasi: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal ambil lokasi: $e')),
        );
      }
    } finally {
      setState(() => _isGettingLocation = false);
    }
  }

  Future<void> _loadDistricts() async {
    final response =
        await http.get(Uri.parse('http://10.0.2.2:8000/api/districts'));
    if (response.statusCode == 200) {
      setState(() {
        _districts = json.decode(response.body);
      });
    }
  }

  Future<void> _loadVillages(String districtId) async {
    final response = await http.get(
        Uri.parse('http://10.0.2.2:8000/api/districts/$districtId/villages'));
    if (response.statusCode == 200) {
      setState(() {
        _villages = json.decode(response.body);
      });
    }
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

  Widget _buildTextFieldWithIcon(
      String label, IconData icon, TextEditingController controller,
      {TextInputType keyboardType = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          prefixIcon: Icon(icon),
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
        Text(label,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
        const SizedBox(height: 8),
        InkWell(
          onTap: () => _pickImage(ImageSource.gallery, onPick),
          child: Container(
            width: double.infinity,
            height: 160,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.grey[200],
              image: image != null
                  ? DecorationImage(
                      image: FileImage(image),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: image == null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.image, size: 48, color: Colors.grey),
                        SizedBox(height: 8),
                        Text("Klik untuk memilih gambar",
                            style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  )
                : Align(
                    alignment: Alignment.bottomRight,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.black45,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.edit,
                            size: 20, color: Colors.white),
                      ),
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9F9),
      appBar: AppBar(
        title: const Text('Edit Profil',
            style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: greenNU,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Column(
                            children: [
                              Stack(
                                alignment: Alignment.bottomRight,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(60),
                                    child: _profileImage != null
                                        ? Image.file(
                                            _profileImage!,
                                            width: 120,
                                            height: 120,
                                            fit: BoxFit.cover,
                                          )
                                        : Container(
                                            width: 120,
                                            height: 120,
                                            decoration: BoxDecoration(
                                              color: Colors.grey[300],
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(Icons.person,
                                                size: 60, color: Colors.white),
                                          ),
                                  ),
                                  Positioned(
                                    child: InkWell(
                                      onTap: () => _pickImage(
                                          ImageSource.gallery,
                                          (f) => setState(
                                              () => _profileImage = f)),
                                      child: Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: greenNU,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.edit,
                                            size: 18, color: Colors.white),
                                      ),
                                    ),
                                  )
                                ],
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                "Foto Profil",
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        _buildImageInput("Foto KTP", _ktpImage,
                            (f) => setState(() => _ktpImage = f)),
                        _buildImageInput("Banner Toko", _bannerImage,
                            (f) => setState(() => _bannerImage = f)),
                        _buildTextFieldWithIcon(
                            "Nama Lengkap", Icons.person, _nameController),
                        _buildTextFieldWithIcon(
                            "No. Telepon", Icons.phone, _phoneController,
                            keyboardType: TextInputType.phone),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            icon: _isGettingLocation
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.my_location),
                            label: Text(
                              _isGettingLocation
                                  ? "Mengambil lokasi..."
                                  : "Gunakan Lokasi Saat Ini",
                              style:
                                  const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            onPressed: _isGettingLocation
                                ? null
                                : _ambilAlamatOtomatis,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: greenNU,
                              side: BorderSide(color: greenNU),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          "Alamat, latitude dan longitude akan terisi otomatis.",
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                        _buildTextFieldWithIcon(
                            "Alamat", Icons.home, _addressController),
                        DropdownButtonFormField<String>(
                          value: _selectedDistrictId,
                          decoration: InputDecoration(
                            labelText: "Kecamatan",
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          items: _districts
                              .map<DropdownMenuItem<String>>((district) {
                            return DropdownMenuItem<String>(
                              value: district['id'].toString(),
                              child: Text(district['name']),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedDistrictId = value;
                              _selectedVillageId = null;
                              _villages = [];
                            });
                            if (value != null) _loadVillages(value);
                          },
                          validator: (value) =>
                              value == null ? 'Kecamatan wajib dipilih' : null,
                        ),
                        DropdownButtonFormField<String>(
                          value: _selectedVillageId,
                          decoration: InputDecoration(
                            labelText: "Desa / Kelurahan",
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          items: _villages
                              .map<DropdownMenuItem<String>>((village) {
                            return DropdownMenuItem<String>(
                              value: village['id'].toString(),
                              child: Text(village['name']),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedVillageId = value;
                            });
                          },
                          validator: (value) => value == null
                              ? 'Desa / Kelurahan wajib dipilih'
                              : null,
                        ),
                        _buildTextFieldWithIcon(
                            "Latitude", Icons.location_on, _latitudeController,
                            keyboardType: TextInputType.number),
                        _buildTextFieldWithIcon("Longitude",
                            Icons.location_on_outlined, _longitudeController,
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
              ),
            ),
    );
  }
}

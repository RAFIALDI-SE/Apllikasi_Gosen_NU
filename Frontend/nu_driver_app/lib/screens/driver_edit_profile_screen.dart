import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

class DriverEditProfileScreen extends StatefulWidget {
  const DriverEditProfileScreen({super.key});

  @override
  State<DriverEditProfileScreen> createState() =>
      _DriverEditProfileScreenState();
}

class _DriverEditProfileScreenState extends State<DriverEditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final Color primaryColor = const Color(0xFF0066CC);

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();

  File? _profileImage, _ktpImage, _bannerImage;
  bool _isLoading = true;
  bool _isGettingLocation = false;

  String? _selectedDistrictId;
  String? _selectedVillageId;

  List<Map<String, dynamic>> _districts = [];
  List<Map<String, dynamic>> _villages = [];

  @override
  void initState() {
    super.initState();
    _loadDistricts().then((_) {
      _fetchProfileData();
    });
  }

  Future<void> _fetchProfileData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      final response = await http.get(
        Uri.parse('http://10.0.2.2:8000/api/driver/me'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body)['user'];

        _selectedDistrictId = data['district_id']?.toString();
        _selectedVillageId = data['village_id']?.toString();

        if (_selectedDistrictId != null) {
          await _loadVillages(_selectedDistrictId!);
        }

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

    final uri = Uri.parse('http://10.0.2.2:8000/api/driver/me/update');
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

  Future<void> _ambilAlamatOtomatis() async {
    setState(() => _isGettingLocation = true);

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) throw Exception("Layanan lokasi belum aktif");

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
          desiredAccuracy: LocationAccuracy.high);

      final placemarks =
          await placemarkFromCoordinates(position.latitude, position.longitude);
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
    try {
      final res =
          await http.get(Uri.parse('http://10.0.2.2:8000/api/districts'));
      if (res.statusCode == 200) {
        final List data = json.decode(res.body);
        setState(() {
          _districts = data
              .map<Map<String, dynamic>>((e) => e as Map<String, dynamic>)
              .toList();
        });
      }
    } catch (e) {
      debugPrint("Gagal load districts: $e");
    }
  }

  Future<void> _loadVillages(String districtId) async {
    try {
      final res = await http.get(
          Uri.parse('http://10.0.2.2:8000/api/districts/$districtId/villages'));
      if (res.statusCode == 200) {
        final List data = json.decode(res.body);
        setState(() {
          _villages = data
              .map<Map<String, dynamic>>((e) => e as Map<String, dynamic>)
              .toList();
        });
      }
    } catch (e) {
      debugPrint("Gagal load villages: $e");
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
                  ? DecorationImage(image: FileImage(image), fit: BoxFit.cover)
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
                        decoration: const BoxDecoration(
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
        backgroundColor: primaryColor,
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
                                          color: primaryColor,
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
                              const Text("Foto Profil",
                                  style:
                                      TextStyle(fontWeight: FontWeight.w600)),
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
                                        color: Colors.white, strokeWidth: 2),
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
                              foregroundColor: primaryColor,
                              side: BorderSide(color: primaryColor),
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
                          decoration: InputDecoration(
                            labelText: 'Kecamatan',
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12)),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                          value: _selectedDistrictId,
                          items: _districts.map((district) {
                            return DropdownMenuItem<String>(
                              value: district['id'].toString(),
                              child: Text(district['name']),
                            );
                          }).toList(),
                          onChanged: (val) {
                            setState(() {
                              _selectedDistrictId = val;
                              _selectedVillageId = null;
                              _villages = [];
                            });
                            _loadVillages(val!);
                          },
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          decoration: InputDecoration(
                            labelText: 'Desa',
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12)),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                          value: _selectedVillageId,
                          items: _villages.map((village) {
                            return DropdownMenuItem<String>(
                              value: village['id'].toString(),
                              child: Text(village['name']),
                            );
                          }).toList(),
                          onChanged: (val) {
                            setState(() {
                              _selectedVillageId = val;
                            });
                          },
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
                            backgroundColor: primaryColor,
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

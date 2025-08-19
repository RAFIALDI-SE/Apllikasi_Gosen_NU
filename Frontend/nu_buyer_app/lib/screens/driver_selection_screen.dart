import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../controllers/buyer_order_controller.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class DriverSelectionScreen extends StatefulWidget {
  const DriverSelectionScreen({super.key});

  @override
  State<DriverSelectionScreen> createState() => _DriverSelectionScreenState();
}

class _DriverSelectionScreenState extends State<DriverSelectionScreen> {
  final Color greenNU = const Color(0xFF1A8754);

  List<dynamic> _drivers = [];
  List<dynamic> _districts = [];
  List<dynamic> _villages = [];
  int? _selectedDistrictId;
  int? _selectedVillageId;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    fetchDistricts();
    fetchDrivers();
  }

  Future<void> fetchDistricts() async {
    final response =
        await http.get(Uri.parse('http://10.0.2.2:8000/api/districts'));
    if (response.statusCode == 200) {
      setState(() {
        _districts = json.decode(response.body);
      });
    }
  }

  Future<void> fetchVillages(int districtId) async {
    final response = await http.get(
        Uri.parse('http://10.0.2.2:8000/api/districts/$districtId/villages'));
    if (response.statusCode == 200) {
      setState(() {
        _villages = json.decode(response.body);
      });
    }
  }

  Future<void> fetchDrivers() async {
    setState(() => _loading = true);
    try {
      final drivers = await BuyerOrderController.fetchAvailableDrivers(
        districtId: _selectedDistrictId,
        villageId: _selectedVillageId,
      );
      setState(() {
        _drivers = drivers;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      print('❌ Error: $e');
    }
  }

  void selectDriver(Map<String, dynamic> driver) {
    Navigator.pop(context, {
      'id': driver['id'],
      'name': driver['name'],
      'address': driver['address'],
    });
  }

  void openWhatsApp(String phoneNumber) async {
    final url = Uri.parse("https://wa.me/$phoneNumber");
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tidak dapat membuka WhatsApp')),
      );
    }
  }

  Widget buildDriverCard(Map<String, dynamic> driver) {
    final isActive = driver['is_active'].toString() == '1';
    final statusText = isActive ? 'Tersedia' : 'Tidak Aktif';
    final statusColor = isActive ? Colors.green : Colors.red;

    return GestureDetector(
      onTap: () {
        if (isActive) selectDriver(driver);
      },
      child: Card(
        elevation: 3,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundImage: driver['profile_picture'] != null
                    ? NetworkImage(driver['profile_picture'])
                    : null,
                child: driver['profile_picture'] == null
                    ? const Icon(Icons.person, size: 30)
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      driver['name'],
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      driver['address'] ?? '-',
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.circle, size: 12, color: statusColor),
                        const SizedBox(width: 6),
                        Text(
                          statusText,
                          style: TextStyle(color: statusColor),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const FaIcon(
                  FontAwesomeIcons.whatsapp,
                  color: Colors.green,
                ),
                onPressed: () => openWhatsApp(driver['phone'].toString()),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget buildDropdownFilters() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DropdownButtonFormField<int>(
            isDense: true,
            decoration: InputDecoration(
              labelText: 'Kecamatan',
              labelStyle: const TextStyle(fontSize: 13),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              filled: true,
              fillColor: Colors.grey[100],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
            ),
            value: _selectedDistrictId,
            items: _districts.map<DropdownMenuItem<int>>((district) {
              return DropdownMenuItem<int>(
                value: district['id'],
                child: Text(
                  district['name'],
                  style: const TextStyle(fontSize: 13),
                ),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedDistrictId = value;
                _selectedVillageId = null;
                _villages = [];
              });
              if (value != null) {
                fetchVillages(value);
                fetchDrivers();
              }
            },
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<int>(
            isDense: true,
            decoration: InputDecoration(
              labelText: 'Desa',
              labelStyle: const TextStyle(fontSize: 13),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              filled: true,
              fillColor: Colors.grey[100],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
            ),
            value: _selectedVillageId,
            items: _villages.map<DropdownMenuItem<int>>((village) {
              return DropdownMenuItem<int>(
                value: village['id'],
                child: Text(
                  village['name'],
                  style: const TextStyle(fontSize: 13),
                ),
              );
            }).toList(),
            onChanged: (value) {
              setState(() => _selectedVillageId = value);
              fetchDrivers();
            },
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              style: TextButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              onPressed: () {
                setState(() {
                  _selectedDistrictId = null;
                  _selectedVillageId = null;
                  _villages = [];
                });
                fetchDrivers();
              },
              icon: const Icon(Icons.refresh, size: 16, color: Colors.black54),
              label: const Text(
                'Reset Filter',
                style: TextStyle(fontSize: 13, color: Colors.black54),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: greenNU,
        title: const Text("Pilih Driver"),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: fetchDrivers,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  buildDropdownFilters(),
                  if (_drivers.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Center(
                        child: Text(
                          'Belum ada driver yang tersedia.',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      ),
                    )
                  else
                    ..._drivers
                        .map((driver) => buildDriverCard(driver))
                        .toList(),
                ],
              ),
            ),
    );
  }
}

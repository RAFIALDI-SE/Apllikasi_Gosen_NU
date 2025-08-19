import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class EventDetailScreen extends StatefulWidget {
  const EventDetailScreen({super.key});

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  Map<String, dynamic>? event;
  bool _isLoading = true;

  Future<void> fetchEvent(int id) async {
    final response = await http.get(
      Uri.parse('http://10.0.2.2:8000/api/events/$id'),
    );

    if (response.statusCode == 200) {
      setState(() {
        event = json.decode(response.body);
        _isLoading = false;
      });
    } else {
      print("Gagal memuat detail event");
      setState(() => _isLoading = false);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final eventId = ModalRoute.of(context)!.settings.arguments as int;
    fetchEvent(eventId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Event'),
        backgroundColor: const Color(0xFF1A8754),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : event == null
              ? const Center(child: Text('Event tidak ditemukan'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (event!['image'] != null)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            'http://10.0.2.2:8000/storage/${event!['image']}',
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                      const SizedBox(height: 16),
                      Text(
                        event!['title'] ?? '',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        event!['description'] ?? 'Tidak ada deskripsi',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),
    );
  }
}

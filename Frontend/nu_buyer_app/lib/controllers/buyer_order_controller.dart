import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class BuyerOrderController {
  static Future<Map<String, dynamic>> fetchProductDetail(int id) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final response = await http.get(
      Uri.parse('http://10.0.2.2:8000/api/buyer/products/$id'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Gagal mengambil detail produk');
    }
  }

  static Future<List<dynamic>> fetchAvailableDrivers({
    int? districtId,
    int? villageId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final uri = Uri.http(
      '10.0.2.2:8000',
      '/api/buyer/drivers',
      {
        if (districtId != null) 'district_id': districtId.toString(),
        if (villageId != null) 'village_id': villageId.toString(),
      },
    );

    final response = await http.get(
      uri,
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Gagal mengambil driver');
    }
  }

  static Future<bool> placeOrder({
    required int productId,
    required int quantity,
    required int driverId,
    required String driverName,
    required String address,
    required double lat,
    required double lng,
    String? note,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final response = await http.post(
      Uri.parse('http://10.0.2.2:8000/api/buyer/orders'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'product_id': productId.toString(),
        'quantity': quantity.toString(),
        'driver_id': driverId.toString(),
        'delivery_address': address,
        'delivery_latitude': lat.toString(),
        'delivery_longitude': lng.toString(),
        'note': note?.isEmpty == true ? null : note,
      }),
    );

    return response.statusCode == 201;
  }
}

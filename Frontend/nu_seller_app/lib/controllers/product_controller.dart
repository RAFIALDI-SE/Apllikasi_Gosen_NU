import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ProductController {
  final String baseUrl = 'http://10.0.2.2:8000/api/seller/products';

  Future<bool> addProduct({
    required String name,
    required String description,
    required String price,
    required String stock,
    required String categoryId,
    File? image,
    required BuildContext context,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    var request = http.MultipartRequest('POST', Uri.parse(baseUrl));
    request.headers['Authorization'] = 'Bearer $token';

    request.fields['name'] = name;
    request.fields['description'] = description;
    request.fields['price'] = price;
    request.fields['stock'] = stock;
    request.fields['category_id'] = categoryId;

    if (image != null) {
      request.files.add(await http.MultipartFile.fromPath('image', image.path));
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Produk berhasil ditambahkan')),
      );
      return true;
    } else {
      print(response.body);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal menambahkan produk')),
      );
      return false;
    }
  }

  Future<bool> updateProduct({
    required int id,
    required String name,
    required String description,
    required String price,
    required String stock,
    required String categoryId,
    File? image,
    required BuildContext context,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    var request = http.MultipartRequest(
      'POST',
      Uri.parse('http://10.0.2.2:8000/api/seller/products/$id'),
    );
    request.headers['Authorization'] = 'Bearer $token';
    request.fields['_method'] = 'PUT'; // penting untuk override method PUT

    request.fields['name'] = name;
    request.fields['description'] = description;
    request.fields['price'] = price;
    request.fields['stock'] = stock;
    request.fields['category_id'] = categoryId;

    if (image != null) {
      request.files.add(await http.MultipartFile.fromPath('image', image.path));
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Produk berhasil diperbarui')),
      );
      return true;
    } else {
      print(response.body);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal memperbarui produk')),
      );
      return false;
    }
  }


}

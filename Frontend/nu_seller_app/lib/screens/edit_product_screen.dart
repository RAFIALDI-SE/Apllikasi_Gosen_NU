import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../controllers/product_controller.dart';

class EditProductScreen extends StatefulWidget {
  final Map<String, dynamic> product;

  const EditProductScreen({super.key, required this.product});

  @override
  State<EditProductScreen> createState() => _EditProductScreenState();
}

class _EditProductScreenState extends State<EditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final ProductController productController = ProductController();

  late TextEditingController nameController;
  late TextEditingController descController;
  late TextEditingController priceController;
  late TextEditingController stockController;

  File? _image;
  List<dynamic> _categories = [];
  String? _selectedCategoryId;

  final Color greenNU = const Color(0xFF1A8754);

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.product['name']);
    descController = TextEditingController(text: widget.product['description']);
    priceController = TextEditingController(text: widget.product['price'].toString());
    stockController = TextEditingController(text: widget.product['stock'].toString());
    _selectedCategoryId = widget.product['category_id']?.toString();
    fetchCategories();
  }

  Future<void> fetchCategories() async {
    final response = await http.get(Uri.parse('http://10.0.2.2:8000/api/categories'));

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      setState(() {
        _categories = data;
      });
    } else {
      print('Gagal ambil kategori: ${response.body}');
    }
  }

  Future<void> pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _image = File(picked.path);
      });
    }
  }

  Future<void> updateProduct() async {
    final success = await productController.updateProduct(
      id: widget.product['id'],
      name: nameController.text,
      description: descController.text,
      price: priceController.text,
      stock: stockController.text,
      categoryId: _selectedCategoryId ?? '',
      image: _image,
      context: context,
    );

    if (success) {
      Navigator.pop(context, true); // kembali dan refresh
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Produk'),
        backgroundColor: greenNU,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Nama Produk'),
                validator: (val) => val!.isEmpty ? 'Wajib diisi' : null,
              ),
              TextFormField(
                controller: descController,
                decoration: const InputDecoration(labelText: 'Deskripsi'),
                validator: (val) => val!.isEmpty ? 'Wajib diisi' : null,
              ),
              TextFormField(
                controller: priceController,
                decoration: const InputDecoration(labelText: 'Harga'),
                keyboardType: TextInputType.number,
              ),
              TextFormField(
                controller: stockController,
                decoration: const InputDecoration(labelText: 'Stok'),
                keyboardType: TextInputType.number,
              ),

              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedCategoryId,
                decoration: const InputDecoration(labelText: 'Kategori'),
                items: _categories.map<DropdownMenuItem<String>>((category) {
                  return DropdownMenuItem<String>(
                    value: category['id'].toString(),
                    child: Text(category['name']),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCategoryId = value;
                  });
                },
              ),

              const SizedBox(height: 12),
              _image != null
                  ? Image.file(_image!, height: 100)
                  : widget.product['image'] != null
                  ? Image.network(
                'http://10.0.2.2:8000/storage/${widget.product['image']}',
                height: 100,
              )
                  : const Text('Belum ada gambar'),
              ElevatedButton(
                onPressed: pickImage,
                child: const Text('Pilih Gambar Baru'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    updateProduct();
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: greenNU),
                child: const Text('Update Produk'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

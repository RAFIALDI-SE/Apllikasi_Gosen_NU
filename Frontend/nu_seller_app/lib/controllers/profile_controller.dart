// lib/controllers/profile_controller.dart

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
// import 'package:geocoding/geocoding.dart';
// import 'package:geolocator/geolocator.dart';

class ProfileController {
  final String baseUrl = 'http://10.0.2.2:8000/api';

  Future<Map<String, dynamic>?> fetchCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final response = await http.get(
      Uri.parse('$baseUrl/me'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      return json.decode(response.body)['user'];
    }
    return null;
  }

  // Future<bool> updateProfile({
  //   required String name,
  //   required String phone,
  //   required String address,
  //   required String latitude,
  //   required String longitude,
  //   File? profilePicture,
  //   File? ktpPhoto,
  //   File? storeBanner,
  // }) async {
  //   final prefs = await SharedPreferences.getInstance();
  //   final token = prefs.getString('token');

  //   var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/me/update'));
  //   request.headers['Authorization'] = 'Bearer $token';
  //   request.fields['name'] = name;
  //   request.fields['phone'] = phone;
  //   request.fields['address'] = address;
  //   request.fields['latitude'] = latitude;
  //   request.fields['longitude'] = longitude;

  //   if (profilePicture != null) {
  //     request.files.add(await http.MultipartFile.fromPath('profile_picture', profilePicture.path));
  //   }
  //   if (ktpPhoto != null) {
  //     request.files.add(await http.MultipartFile.fromPath('ktp_photo', ktpPhoto.path));
  //   }
  //   if (storeBanner != null) {
  //     request.files.add(await http.MultipartFile.fromPath('store_banner', storeBanner.path));
  //   }

  //   var response = await request.send();
  //   return response.statusCode == 200;
  // }

//   Future<Map<String, dynamic>> getCurrentLocationWithAddress() async {
//     var permission = await Geolocator.checkPermission();
//     if (permission == LocationPermission.denied) {
//       permission = await Geolocator.requestPermission();
//     }

//     final position = await Geolocator.getCurrentPosition();
//     final placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
//     final placemark = placemarks.first;
//     final address = "${placemark.street}, ${placemark.locality}, ${placemark.administrativeArea}";

//     return {
//       'latitude': position.latitude,
//       'longitude': position.longitude,
//       'address': address,
//     };
//   }
}

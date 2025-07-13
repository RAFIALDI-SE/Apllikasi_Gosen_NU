import 'package:flutter/material.dart';
import 'package:nu_seller_app/screens/add_product_screen.dart';
import 'package:nu_seller_app/screens/manage_product_screen.dart';
import 'package:nu_seller_app/screens/product_detail_screen.dart';
// import 'package:seller_nu/screens/edit_profile_screen.dart';
import 'package:nu_seller_app/screens/seller_home_screen.dart';
import 'package:nu_seller_app/screens/seller_profile_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Seller Auth',
      theme: ThemeData(primarySwatch: Colors.teal),
      home: const LoginScreen(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/seller-home': (context) => const SellerHomeScreen(),
        '/profile': (context) => const SellerProfileScreen(),
        // '/edit-profile': (context) => const EditProfileScreen(),
        '/add-product': (context) => const AddProductScreen(),
        '/manage-products': (context) => const ManageProductsScreen(),
        '/product-detail': (context) {
          final productId = ModalRoute.of(context)!.settings.arguments as int;
          return ProductDetailScreen(productId: productId);
        },
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:nu_buyer_app/screens/buyer_product_order_screen.dart';
import 'screens/buyer_favorite_screen.dart';
import 'screens/buyer_edit_profile_screen.dart';
import 'screens/buyer_event_detail_screen.dart';
import 'screens/buyer_login_screen.dart';
import 'screens/buyer_order_history_screen.dart';
import 'screens/buyer_product_detail_screen.dart';
import 'screens/buyer_profile_screen.dart';
import 'screens/buyer_register_screen.dart';
import 'screens/buyer_home_screen.dart';
import 'screens/driver_selection_screen.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Buyer App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.teal),
      initialRoute: '/login',
      routes: {
        '/login': (context) => const BuyerLoginScreen(),
        '/register': (context) => const BuyerRegisterScreen(),
        '/home': (context) => const BuyerHomeScreen(),
        '/buyer-product-detail': (context) => const BuyerProductDetailScreen(),
        '/event-detail': (context) => const EventDetailScreen(),
        '/buyer-profile': (context) => const BuyerProfileScreen(),
        '/buyer-edit-profile': (context) => const BuyerEditProfileScreen(),
        '/buyer-favorites': (context) => const BuyerFavoriteScreen(),
        '/buyer-order-product': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as int;
          return BuyerProductOrderScreen(productId: args);
        },
        '/select-driver': (context) => DriverSelectionScreen(),
        '/buyer-order-history': (context) => const BuyerOrderHistoryScreen(),
      },
    );
  }
}

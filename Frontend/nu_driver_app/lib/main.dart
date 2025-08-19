import 'package:flutter/material.dart';
import 'package:nu_driver_app/screens/driver_edit_profile_screen.dart';
import 'screens/driver_delivery_history_screen.dart';
import 'screens/driver_home_screen.dart';
import 'screens/driver_login_screen.dart';
import 'screens/driver_profile_screen.dart';
import 'screens/driver_register_screen.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Buyer App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.teal),
      initialRoute: '/driver/login',
      routes: {
        '/driver/login': (context) => const DriverLoginScreen(),
        '/driver/register': (context) => const DriverRegisterScreen(),
        '/driver/home': (context) => const DriverHomeScreen(),
        '/driver-profile': (context) => const DriverProfileScreen(),
        '/driver-edit-profile': (context) => const DriverEditProfileScreen(),
        '/driver-history': (context) => const DriverDeliveryHistoryScreen(),
      },
    );
  }
}

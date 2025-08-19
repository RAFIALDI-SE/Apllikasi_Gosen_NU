import 'package:flutter/material.dart';
import '../controllers/buyer_auth_controller.dart';

class BuyerLoginScreen extends StatefulWidget {
  const BuyerLoginScreen({super.key});

  @override
  State<BuyerLoginScreen> createState() => _BuyerLoginScreenState();
}

class _BuyerLoginScreenState extends State<BuyerLoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final auth = BuyerAuthController();

  // Variabel untuk mengontrol visibilitas password
  bool _isPasswordVisible = false;

  final Color greenNU = const Color(0xFF1A8754); // Hijau NU
  final Color textColor = const Color(0xFF333333); // Abu gelap lembut

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2FDF6), // Latar hijau muda lembut
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Icon(Icons.shopping_basket_rounded, size: 64, color: greenNU),
              const SizedBox(height: 12),
              Text(
                'Selamat Datang Buyer NU',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Silakan login untuk melanjutkan',
                style: TextStyle(fontSize: 16, color: Colors.grey[700]),
              ),
              const SizedBox(height: 24),

              // Card Form
              Card(
                elevation: 3,
                shadowColor: greenNU.withOpacity(0.2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      TextField(
                        controller: emailController,
                        decoration: InputDecoration(
                          labelText: 'Email',
                          labelStyle: TextStyle(color: textColor),
                          prefixIcon: Icon(Icons.email, color: greenNU),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: greenNU),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: passwordController,
                        // Menggunakan _isPasswordVisible untuk mengontrol visibilitas
                        obscureText: !_isPasswordVisible,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          labelStyle: TextStyle(color: textColor),
                          prefixIcon: Icon(Icons.lock, color: greenNU),
                          // Menambahkan tombol mata di sini
                          suffixIcon: IconButton(
                            icon: Icon(
                              // Mengganti icon sesuai dengan status visibilitas
                              _isPasswordVisible
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                              color: greenNU,
                            ),
                            onPressed: () {
                              // Mengubah state saat tombol diklik
                              setState(() {
                                _isPasswordVisible = !_isPasswordVisible;
                              });
                            },
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: greenNU),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () async {
                            final success = await auth.login(
                              email: emailController.text,
                              password: passwordController.text,
                              context: context,
                            );
                            if (success) {
                              Navigator.pushReplacementNamed(context, '/home');
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: greenNU,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Login',
                              style: TextStyle(fontSize: 16)),
                        ),
                      ),
                      TextButton(
                        onPressed: () =>
                            Navigator.pushNamed(context, '/register'),
                        child: Text(
                          "Belum punya akun? Daftar di sini",
                          style: TextStyle(color: greenNU),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

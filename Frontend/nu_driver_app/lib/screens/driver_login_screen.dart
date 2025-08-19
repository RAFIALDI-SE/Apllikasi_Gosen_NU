import 'package:flutter/material.dart';
import '../controllers/driver_auth_controller.dart';

class DriverLoginScreen extends StatefulWidget {
  const DriverLoginScreen({super.key});

  @override
  State<DriverLoginScreen> createState() => _DriverLoginScreenState();
}

class _DriverLoginScreenState extends State<DriverLoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final auth = DriverAuthController();

  // Variabel untuk mengontrol visibilitas password
  bool _isPasswordVisible = false;

  final Color driverBlue = const Color(0xFF0D47A1); // Biru tua
  final Color textColor = const Color(0xFF2C2C2C);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE3F2FD), // Biru muda lembut
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Icon(Icons.motorcycle, size: 64, color: driverBlue),
              const SizedBox(height: 12),
              Text(
                'Selamat Datang Driver NU',
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
                shadowColor: driverBlue.withOpacity(0.2),
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
                          prefixIcon: Icon(Icons.email, color: driverBlue),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: driverBlue),
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
                          prefixIcon: Icon(Icons.lock, color: driverBlue),
                          // Menambahkan tombol mata di sini
                          suffixIcon: IconButton(
                            icon: Icon(
                              // Mengganti icon sesuai dengan status visibilitas
                              _isPasswordVisible
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                              color: driverBlue,
                            ),
                            onPressed: () {
                              // Mengubah state saat tombol diklik
                              setState(() {
                                _isPasswordVisible = !_isPasswordVisible;
                              });
                            },
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: driverBlue),
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
                              Navigator.pushReplacementNamed(
                                  context, '/driver/home');
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: driverBlue,
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
                            Navigator.pushNamed(context, '/driver/register'),
                        child: Text(
                          "Belum punya akun? Daftar di sini",
                          style: TextStyle(color: driverBlue),
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

// In frontend/lib/features/auth/screens/login_screen.dart

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../core/api_client.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _apiService = ApiService();
  bool _isLoading = false;
  String? _jwtToken; // store token in memory
  final storage = const FlutterSecureStorage();

  final String baseUrl = "${ApiClient.baseUrl}/api/auth"; // Backend base URL

  /// Login function
  void _login() async {
    final phone = _phoneController.text.trim();
    final password = _passwordController.text.trim();

    if (phone.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Email and password are required")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final token = await _apiService.login(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      // --- SUCCESS ---
      print("Login successful! Token: $token");
      // TODO: Securely store the token and navigate to the home screen.
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Login Successful!'),
          backgroundColor: Colors.green,
        ),
      );

      final data = jsonDecode(response.body);

      if (!mounted) return; // ensure widget is alive after await

      if (response.statusCode == 200) {
        _jwtToken = data['token']; // store token in memory
        if (_jwtToken != null) {
          await storage.write(key: 'jwt_token', value: _jwtToken);
        }

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Login successful")),
        );

        // Navigate to Home screen
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['error'] ?? "Login failed")),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Server error: $e")),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _navigateToRegister() {
    // TODO: Implement navigation to your RegisterScreen
    // Navigator.pushNamed(context, '/register');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Navigate to Register Screen")),
    );
  }

  void _handleForgotPassword() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Forgot password feature coming soon")),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FBFA),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo + Title
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.sports_cricket,
                    size: 48,
                    color: Color(0xFF36E27B),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "CricLeague",
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade900,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),

              // Email
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: _inputDecoration("Email", Icons.email),
              ),
              const SizedBox(height: 16),

              // Password
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: _inputDecoration("Password", Icons.lock),
              ),

              // Forgot password
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _handleForgotPassword,
                  child: const Text(
                    "Forgot Password?",
                    style: TextStyle(color: Color(0xFF50956C)),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Login Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF36E27B),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          "Login",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 12),

              // Register Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton(
                  onPressed: _navigateToRegister,
                  style: OutlinedButton.styleFrom(
                    backgroundColor: const Color(0xFFE8F3EC),
                    foregroundColor: Colors.white,
                    side: BorderSide.none,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    "Register",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Reusable input decoration
  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: Colors.grey),
      filled: true,
      fillColor: const Color(0xFFE8F3EC),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    );
  }
}
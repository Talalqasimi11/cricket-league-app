// lib/features/auth/screens/register_screen.dart

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final TextEditingController _captainNameController = TextEditingController();
  final TextEditingController _teamNameController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();

  bool _isOtpSent = false;
  bool _isLoading = false;

  final String baseUrl = "http://localhost:5000/api/auth"; // Backend base URL

  /// Send OTP to the phone number
  void _sendOtp() async {
    if (_phoneController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Enter phone number first")));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse("$baseUrl/send-otp"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"phone_number": _phoneController.text}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        setState(() => _isOtpSent = true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? "OTP sent successfully")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['error'] ?? "Failed to send OTP")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Server error: $e")));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// Register user after verifying OTP
  void _register() async {
    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Passwords do not match")));
      return;
    }

    if (_otpController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Enter OTP to continue")));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse("$baseUrl/register"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "phone_number": _phoneController.text,
          "password": _passwordController.text,
          "otp": _otpController.text,
          "captain_name": _captainNameController.text,
          "team_name": _teamNameController.text,
          "team_location": _locationController.text,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? "Registration successful")),
        );
        Navigator.pushReplacementNamed(context, "/login");
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['error'] ?? "Registration failed")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Server error: $e")));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FBFA),
      appBar: AppBar(
        title: const Text("Register"),
        backgroundColor: const Color(0xFF36E27B),
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Phone number
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: _inputDecoration("Phone Number", Icons.phone),
            ),
            const SizedBox(height: 16),

            // Password
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: _inputDecoration("Password", Icons.lock),
            ),
            const SizedBox(height: 16),

            // Confirm Password
            TextField(
              controller: _confirmPasswordController,
              obscureText: true,
              decoration: _inputDecoration(
                "Confirm Password",
                Icons.lock_outline,
              ),
            ),
            const SizedBox(height: 16),

            // Captain Name
            TextField(
              controller: _captainNameController,
              decoration: _inputDecoration("Captain Name", Icons.person),
            ),
            const SizedBox(height: 16),

            // Team Name
            TextField(
              controller: _teamNameController,
              decoration: _inputDecoration("Team Name", Icons.sports_cricket),
            ),
            const SizedBox(height: 16),

            // Location
            TextField(
              controller: _locationController,
              decoration: _inputDecoration("Location", Icons.location_on),
            ),
            const SizedBox(height: 20),

            // OTP Section
            if (_isOtpSent) ...[
              TextField(
                controller: _otpController,
                keyboardType: TextInputType.number,
                decoration: _inputDecoration("Enter OTP", Icons.verified),
              ),
              const SizedBox(height: 16),
            ],

            // Send OTP Button
            if (!_isOtpSent)
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton(
                  onPressed: _isLoading ? null : _sendOtp,
                  style: OutlinedButton.styleFrom(
                    backgroundColor: const Color(0xFFE8F3EC),
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator()
                      : const Text("Send OTP"),
                ),
              ),

            const SizedBox(height: 20),

            // Register Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _register,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF36E27B),
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        "Register",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Reusable input decoration
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

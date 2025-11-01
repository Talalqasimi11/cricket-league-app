import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/api_client.dart';
import '../../../core/error_handler.dart';
import '../../../core/auth_provider.dart';
import '../../../core/secure_storage.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _rememberMe = false;
  String? _errorMessage;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _loadSavedPhone();
  }

  /// Format phone number to E.164 format
  String _formatPhoneNumber(String phone) {
    // Remove all non-digit characters
    final digits = phone.replaceAll(RegExp(r'\D'), '');

    // Pakistan phone number handling
    if (digits.startsWith('92')) {
      return digits; // Already in E.164 format
    } else if (digits.startsWith('0')) {
      return '92${digits.substring(1)}'; // Remove leading 0 and add 92
    } else if (digits.length == 10) {
      return '92$digits'; // Assume Pakistan and add country code
    }
    return digits;
  }

  /// Validate Pakistan phone number
  String? _validatePhoneNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone number is required';
    }
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 10) {
      return 'Please enter a valid phone number';
    }
    return null;
  }

  /// Validate password
  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }
    return null;
  }

  /// Load saved phone number if "Remember me" was checked
  Future<void> _loadSavedPhone() async {
    try {
      final saved = await SecureStorage.getString('remembered_phone');
      if (saved != null && mounted) {
        setState(() {
          _phoneController.text = saved;
          _rememberMe = true;
        });
      }
    } catch (e) {
      debugPrint('Error loading saved phone: $e');
    }
  }

  /// Login function
  void _login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final phone = _formatPhoneNumber(_phoneController.text.trim());
    final password = _passwordController.text.trim();

    // Save phone if remember me is checked
    if (_rememberMe) {
      try {
        await SecureStorage.saveString(
          'remembered_phone',
          _phoneController.text,
        );
      } catch (e) {
        debugPrint('Error saving phone: $e');
      }
    } else {
      try {
        await SecureStorage.deleteString('remembered_phone');
      } catch (e) {
        debugPrint('Error clearing saved phone: $e');
      }
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final data =
          await ApiClient.instance.postJson(
                '/api/auth/login',
                body: {'phone_number': phone, 'password': password},
              )
              as Map<String, dynamic>;
      final token = data['token']?.toString();
      final refresh = data['refresh_token']?.toString();
      if (token == null || token.isEmpty) {
        throw Exception('Invalid response: missing token');
      }
      await ApiClient.instance.setToken(token);
      if (refresh != null && refresh.isNotEmpty) {
        await ApiClient.instance.setRefreshToken(refresh);
      }

      if (!mounted) return;

      // Update auth provider
      final authProvider = context.read<AuthProvider>();
      await authProvider.initializeAuth();

      ErrorHandler.showSuccessSnackBar(context, 'Login successful');
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/home');
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = e.toString());
      ErrorHandler.showErrorSnackBar(context, e);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _navigateToRegister() {
    Navigator.pushNamed(context, '/register');
  }

  void _handleForgotPassword() {
    Navigator.pushNamed(context, '/forgot-password');
  }

  @override
  void dispose() {
    _phoneController.dispose();
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
          child: Form(
            key: _formKey,
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

                // Error message
                if (_errorMessage != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade100,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade300),
                    ),
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(
                        color: Colors.red.shade900,
                        fontSize: 14,
                      ),
                    ),
                  ),

                // Phone
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  validator: _validatePhoneNumber,
                  decoration: _inputDecoration(
                    "Phone number (e.g., 03XX-XXXXXXX)",
                    Icons.phone,
                  ),
                ),
                const SizedBox(height: 16),

                // Password
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  validator: _validatePassword,
                  decoration: _inputDecoration(
                    "Password (min 8 characters)",
                    Icons.lock,
                  ),
                ),
                const SizedBox(height: 12),

                // Remember Me
                Row(
                  children: [
                    Checkbox(
                      value: _rememberMe,
                      onChanged: (value) {
                        setState(() => _rememberMe = value ?? false);
                      },
                    ),
                    const Text('Remember my phone number'),
                  ],
                ),
                const SizedBox(height: 12),

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
                    onPressed: _isLoading ? null : _login,
                    style: ElevatedButton.styleFrom(),
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
                    style: OutlinedButton.styleFrom(),
                    child: const Text(
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

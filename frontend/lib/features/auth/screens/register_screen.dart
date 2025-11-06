import 'package:flutter/material.dart';
import '../../../core/api_client.dart';
import '../../../core/error_handler.dart';
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
  final TextEditingController _teamNameController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();

  bool _isOtpSent = false;
  bool _isLoading = false;
  String? _errorMessage;
  final _formKey = GlobalKey<FormState>();

  /// Format phone number to E.164 format
  String _formatPhoneNumber(String phone) {
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('92')) {
      return digits;
    } else if (digits.startsWith('0')) {
      return '92${digits.substring(1)}';
    } else if (digits.length == 10) {
      return '92$digits';
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
    // Validate Pakistan numbers
    if (!digits.startsWith('92') &&
        !digits.startsWith('0') &&
        digits.length != 10) {
      return 'Please enter a valid Pakistan phone number';
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
    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return 'Password must contain uppercase letter';
    }
    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return 'Password must contain a number';
    }
    return null;
  }

  /// Validate passwords match
  String? _validatePasswordMatch(String? value) {
    if (value != _passwordController.text) {
      return 'Passwords do not match';
    }
    return null;
  }

  /// Validate team name
  String? _validateTeamName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Team name is required';
    }
    if (value.length < 3) {
      return 'Team name must be at least 3 characters';
    }
    return null;
  }

  /// Send OTP to phone number
  Future<void> _sendOtp() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final phone = _formatPhoneNumber(_phoneController.text.trim());
      final response = await ApiClient.instance.post(
        '/api/auth/send-otp',
        body: {'phone_number': phone},
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        setState(() => _isOtpSent = true);
        ErrorHandler.showSuccessSnackBar(context, 'OTP sent to your phone');
      } else {
        throw Exception('Failed to send OTP');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = e.toString());
      ErrorHandler.showErrorSnackBar(context, e);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Register user after verifying OTP
  void _register() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_otpController.text.isEmpty) {
      setState(() => _errorMessage = 'Please enter OTP');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final phone = _formatPhoneNumber(_phoneController.text.trim());
      final response = await ApiClient.instance.post(
        '/api/auth/register',
        body: {
          'phone_number': phone,
          'password': _passwordController.text,
          'otp': _otpController.text,
          'team_name': _teamNameController.text,
          'location': _locationController.text,
        },
      );

      final data = jsonDecode(response.body);

      if (!mounted) return;

      if (response.statusCode == 201 || response.statusCode == 200) {
        ErrorHandler.showSuccessSnackBar(
          context,
          data['message'] ?? 'Registration successful',
        );
        // Navigate to login and update auth provider
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/login');
      } else {
        throw response;
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = e.toString());
      ErrorHandler.showErrorSnackBar(context, e);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _teamNameController.dispose();
    _locationController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FBFA),
      appBar: AppBar(
        title: const Text('Register'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 1,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
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
                    style: TextStyle(color: Colors.red.shade900, fontSize: 14),
                  ),
                ),

              // Phone number
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                validator: _validatePhoneNumber,
                enabled: !_isOtpSent,
                decoration: _inputDecoration(
                  'Phone Number (03XX-XXXXXXX)',
                  Icons.phone,
                ),
              ),
              const SizedBox(height: 16),

              // Password with requirements
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                validator: _validatePassword,
                enabled: !_isOtpSent,
                decoration: _inputDecoration(
                  'Password (min 8 chars, 1 uppercase, 1 number)',
                  Icons.lock,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Password must contain: at least 8 characters, one uppercase letter, and one number',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
              ),
              const SizedBox(height: 16),

              // Confirm Password
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: true,
                validator: _validatePasswordMatch,
                enabled: !_isOtpSent,
                decoration: _inputDecoration(
                  'Confirm Password',
                  Icons.lock_outline,
                ),
              ),
              const SizedBox(height: 16),

              // Team Name
              TextFormField(
                controller: _teamNameController,
                validator: _validateTeamName,
                decoration: _inputDecoration('Team Name', Icons.sports_cricket),
              ),
              const SizedBox(height: 16),

              // Location
              TextFormField(
                controller: _locationController,
                decoration: _inputDecoration('Location', Icons.location_on),
              ),
              const SizedBox(height: 20),

              // Send OTP or OTP verification
              if (!_isOtpSent)
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _sendOtp,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF15803D),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            'Send OTP',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                )
              else ...[
                // OTP verification
                TextFormField(
                  controller: _otpController,
                  keyboardType: TextInputType.number,
                  decoration: _inputDecoration(
                    'Enter OTP sent to your phone',
                    Icons.verified,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _register,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF15803D),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            'Complete Registration',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () => setState(() => _isOtpSent = false),
                  child: const Text('Change Phone Number'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Reusable input decoration
  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.grey),
      prefixIcon: Icon(icon, color: Colors.grey.shade600),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.green.shade600, width: 2),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'dart:convert';
import '../../../core/api_client.dart';
import '../../../core/error_handler.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  bool _otpSent = false;
  bool _passwordChanged = false;
  String? _errorMessage;
  String _resetToken = '';

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
    return null;
  }

  /// Validate OTP
  String? _validateOtp(String? value) {
    if (value == null || value.isEmpty) {
      return 'OTP is required';
    }
    if (value.length != 6) {
      return 'OTP must be 6 digits';
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

  /// Validate password match
  String? _validatePasswordMatch(String? value) {
    if (value != _newPasswordController.text) {
      return 'Passwords do not match';
    }
    return null;
  }

  /// Request password reset
  Future<void> _requestReset() async {
    if (_phoneController.text.isEmpty) {
      setState(() => _errorMessage = 'Phone number is required');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final phone = _formatPhoneNumber(_phoneController.text.trim());
      final response = await ApiClient.instance.post(
        '/api/auth/forgot-password',
        body: {'phone_number': phone},
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        _resetToken = data['token']?.toString() ?? '';

        setState(() => _otpSent = true);
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

  /// Verify OTP and reset password
  Future<void> _resetPassword() async {
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
        '/api/auth/reset-password',
        body: {
          'phone_number': phone,
          'otp': _otpController.text,
          'new_password': _newPasswordController.text,
          'token': _resetToken,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (!mounted) return;
        setState(() => _passwordChanged = true);
        ErrorHandler.showSuccessSnackBar(
          context,
          'Password reset successful. Please login with your new password.',
        );

        // Show success message for 2 seconds then navigate
        await Future.delayed(const Duration(seconds: 2));
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/login');
      } else {
        throw Exception('Failed to reset password');
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
    _otpController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FBFA),
      appBar: AppBar(
        title: const Text('Reset Password'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 1,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
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

              // Success message
              if (_passwordChanged)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.shade300),
                  ),
                  child: Text(
                    'Password reset successful! Redirecting to login...',
                    style: TextStyle(
                      color: Colors.green.shade900,
                      fontSize: 14,
                    ),
                  ),
                ),

              // Step 1: Request Reset
              Text(
                'Step 1: Enter Your Phone Number',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                validator: _validatePhoneNumber,
                enabled: !_otpSent,
                decoration: _inputDecoration(
                  'Phone Number (03XX-XXXXXXX)',
                  Icons.phone,
                ),
              ),
              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: (!_otpSent && !_isLoading) ? _requestReset : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF15803D),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(_otpSent ? 'OTP Sent' : 'Send OTP'),
                ),
              ),

              if (_otpSent) ...[
                const SizedBox(height: 32),
                const Divider(),
                const SizedBox(height: 32),

                // Step 2: Verify OTP and set new password
                Text(
                  'Step 2: Verify OTP and Set New Password',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _otpController,
                  keyboardType: TextInputType.number,
                  validator: _validateOtp,
                  decoration: _inputDecoration(
                    'Enter 6-digit OTP',
                    Icons.verified,
                  ),
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _newPasswordController,
                  obscureText: true,
                  validator: _validatePassword,
                  decoration: _inputDecoration(
                    'New Password (min 8 characters)',
                    Icons.lock,
                  ),
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: true,
                  validator: _validatePasswordMatch,
                  decoration: _inputDecoration(
                    'Confirm Password',
                    Icons.lock_outline,
                  ),
                ),
                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: !_isLoading ? _resetPassword : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF15803D),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Reset Password'),
                  ),
                ),
                const SizedBox(height: 12),

                OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _otpSent = false;
                      _otpController.clear();
                      _newPasswordController.clear();
                      _confirmPasswordController.clear();
                    });
                  },
                  child: const Text('Back to Phone Entry'),
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

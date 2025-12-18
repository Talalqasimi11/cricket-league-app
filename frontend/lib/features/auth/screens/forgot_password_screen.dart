// lib/features/auth/screens/forgot_password_screen.dart

import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io'; 
import '../../../core/api_client.dart';
import '../../../core/error_dialog.dart';
// [Added] Import shared helpers
import '../../../core/utils/app_validators.dart';
import '../../../core/theme/app_input_styles.dart';

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
  String _resetToken = '';

  /// Request password reset
  Future<void> _requestReset() async {
    // Simple check before API call, detailed validation happens in Form
    if (_phoneController.text.isEmpty) {
      ErrorDialog.show(context, 'Phone number is required');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // [Fixed] Use shared formatter
      final phone = AppValidators.formatPhoneNumber(_phoneController.text.trim());
      final response = await ApiClient.instance.post(
        '/api/auth/forgot-password',
        body: {'phone_number': phone},
      );

      if (!mounted) return;

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        _resetToken = data['token']?.toString() ?? '';
        setState(() => _otpSent = true);
        
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('OTP sent successfully to your phone.'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        String message;
        try {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          message = data['error'] ?? 'Failed to send OTP. Please check the phone number and try again.';
        } catch (_) {
          message = 'Failed to send OTP (Error ${response.statusCode}). Please try again.';
        }
        
        if (!mounted) return;
        ErrorDialog.show(context, message);
      }
    } on SocketException catch (_) {
      if (!mounted) return;
      ErrorDialog.show(
        context,
        'No internet connection. Please check your network.',
      );
    } catch (e) {
      if (!mounted) return;
      ErrorDialog.show(
        context,
        'An unexpected error occurred while sending OTP.',
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Verify OTP and reset password
  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // [Fixed] Use shared formatter
      final phone = AppValidators.formatPhoneNumber(_phoneController.text.trim());
      final response = await ApiClient.instance.post(
        '/api/auth/reset-password',
        body: {
          'phone_number': phone,
          'otp': _otpController.text,
          'new_password': _newPasswordController.text,
          'token': _resetToken,
        },
      );

      if (!mounted) return;

      if (response.statusCode == 200 || response.statusCode == 201) {
        setState(() => _passwordChanged = true);
        
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password reset successful. Please login with your new password.'),
            backgroundColor: Colors.green,
          ),
        );

        await Future.delayed(const Duration(seconds: 2));
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/login');
      } else {
        String message;
        try {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          message = data['error'] ?? 'Failed to reset password. Please check your details and try again.';
        } catch (_) {
          message = 'Failed to reset password (Error ${response.statusCode}). Please try again.';
        }
        
        if (response.statusCode == 400) {
          message = 'Invalid OTP or password. Please try again.';
        }
        
        if (!mounted) return;
        ErrorDialog.show(context, message);
      }
    } on SocketException catch (_) {
      if (!mounted) return;
      ErrorDialog.show(
        context,
        'No internet connection. Please check your network.',
      );
    } catch (e) {
      if (!mounted) return;
      ErrorDialog.show(
        context,
        'An unexpected error occurred while resetting your password.',
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
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
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green.shade700),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Password reset successful! Redirecting to login...',
                          style: TextStyle(
                            color: Colors.green.shade900,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
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
                // [Fixed] Use shared validator
                validator: AppValidators.validatePhoneNumber,
                enabled: !_otpSent,
                // [Fixed] Use shared style
                decoration: AppInputStyles.textFieldDecoration(
                  context: context,
                  hintText: 'Phone Number (03XX-XXXXXXX)',
                  prefixIcon: Icons.phone,
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
                    disabledBackgroundColor: Colors.grey.shade400,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading && !_otpSent
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(_otpSent ? 'OTP Sent ✓' : 'Send OTP'),
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
                  // [Fixed] Use shared validator
                  validator: AppValidators.validateOtp,
                  maxLength: 6,
                  decoration: AppInputStyles.textFieldDecoration(
                    context: context,
                    hintText: 'Enter 6-digit OTP',
                    prefixIcon: Icons.verified,
                  ),
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _newPasswordController,
                  obscureText: true,
                  // [Fixed] Use shared validator
                  validator: AppValidators.validatePassword,
                  decoration: AppInputStyles.textFieldDecoration(
                    context: context,
                    hintText: 'New Password (min 8 characters)',
                    prefixIcon: Icons.lock,
                  ),
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: true,
                  // [Fixed] Use shared confirm validator
                  validator: (value) => AppValidators.validateConfirmPassword(
                    value,
                    _newPasswordController.text,
                  ),
                  decoration: AppInputStyles.textFieldDecoration(
                    context: context,
                    hintText: 'Confirm Password',
                    prefixIcon: Icons.lock_outline,
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
                      disabledBackgroundColor: Colors.grey.shade400,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text('Reset Password'),
                  ),
                ),
                const SizedBox(height: 12),

                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: _isLoading
                        ? null
                        : () {
                            setState(() {
                              _otpSent = false;
                              _otpController.clear();
                              _newPasswordController.clear();
                              _confirmPasswordController.clear();
                            });
                          },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Back to Phone Entry'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
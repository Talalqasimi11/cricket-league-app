// lib/features/auth/screens/forgot_password_screen.dart

import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';
import '../../../core/api_client.dart';
import '../../../core/error_dialog.dart';
import '../../../core/utils/app_validators.dart';
import '../../../core/theme/app_input_styles.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _phoneController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  bool _passwordChanged = false;

  /// Reset password directly (No OTP)
  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final phone = AppValidators.formatPhoneNumber(
        _phoneController.text.trim(),
      );
      // Calling the modified API which now accepts just phone and new_password
      final response = await ApiClient.instance.post(
        '/api/auth/reset-password',
        body: {
          'phone_number': phone,
          'new_password': _newPasswordController.text,
          // 'token' is no longer needed
        },
      );

      if (!mounted) return;

      if (response.statusCode == 200 || response.statusCode == 201) {
        setState(() => _passwordChanged = true);

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Password reset successful. Please login with your new password.',
            ),
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
          message =
              data['error'] ??
              'Failed to reset password. Please check your details.';
        } catch (_) {
          message = 'Failed to reset password (Error ${response.statusCode}).';
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

              Text(
                'Enter your details to reset password',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                validator: AppValidators.validatePhoneNumber,
                decoration: AppInputStyles.textFieldDecoration(
                  context: context,
                  hintText: 'Phone Number (03XX-XXXXXXX)',
                  prefixIcon: Icons.phone,
                ),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _newPasswordController,
                obscureText: true,
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
              const SizedBox(height: 24),

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
            ],
          ),
        ),
      ),
    );
  }
}

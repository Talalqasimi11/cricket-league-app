import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import '../../../core/api_client.dart';
import '../../../core/theme/theme_config.dart';

import '../../../widgets/custom_button.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;
  final _formKey = GlobalKey<FormState>();
  bool _useEmail = false; // Toggle between phone and email

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
  
    return null;
  }

  /// Validate passwords match
  String? _validatePasswordMatch(String? value) {
    if (value != _passwordController.text) {
      return 'Passwords do not match';
    }
    return null;
  }

  /// Validate email
  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  /// Register user
  void _register() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final body = {
        'password': _passwordController.text,
      };

      if (_useEmail) {
        body['email'] = _emailController.text.trim();
      } else {
        body['phone_number'] = _formatPhoneNumber(_phoneController.text.trim());
      }

      final response = await ApiClient.instance.post(
        '/api/auth/register',
        body: body,
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('✅ ${data['message'] ?? 'Registration successful'}')),
          );
          Navigator.pushReplacementNamed(context, '/login');
        }
      } else if (response.statusCode == 400) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final errorMsg = data['error'] ?? 'Invalid registration data';
        if (mounted) {
          setState(() => _errorMessage = errorMsg);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errorMsg)),
          );
        }
      } else if (response.statusCode == 409) {
        final identifierType = _useEmail ? 'Email' : 'Phone number';
        if (mounted) {
          setState(() => _errorMessage = '$identifierType already registered');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$identifierType already registered')),
          );
        }
      } else if (response.statusCode == 422) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final errorMsg = data['error'] ?? 'Validation failed';
        if (mounted) {
          setState(() => _errorMessage = errorMsg);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errorMsg)),
          );
        }
      } else if (response.statusCode >= 500) {
        if (mounted) {
          setState(() => _errorMessage = 'Server error. Please try again later.');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Server error. Please try again later.')),
          );
        }
      } else {
        if (mounted) {
          setState(() => _errorMessage = 'Registration failed. Please try again.');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Registration failed (${response.statusCode})')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        final errorMessage = e is SocketException
            ? 'No internet connection. Please check your network and try again.'
            : 'Registration failed. Please try again.';
        setState(() => _errorMessage = errorMessage);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: Text(
          'Register',
          style: AppTypographyExtended.headlineSmall.copyWith(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: theme.colorScheme.onSurface,
        elevation: 0,
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
                    color: theme.colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: theme.colorScheme.error),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: AppTypographyExtended.bodyMedium.copyWith(
                      color: theme.colorScheme.onErrorContainer,
                    ),
                  ),
                ),

              // Registration method toggle
              Row(
                children: [
                  Expanded(
                    child: RadioListTile<bool>(
                      title: const Text('Phone'),
                      value: false,
                      groupValue: _useEmail,
                      onChanged: (value) {
                        setState(() {
                          _useEmail = value!;
                        });
                      },
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<bool>(
                      title: const Text('Email'),
                      value: true,
                      groupValue: _useEmail,
                      onChanged: (value) {
                        setState(() {
                          _useEmail = value!;
                        });
                      },
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Phone or Email field
              if (_useEmail)
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  validator: _validateEmail,
                  decoration: _inputDecoration(
                    'Email Address',
                    Icons.email,
                  ),
                )
              else
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  validator: _validatePhoneNumber,
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
                decoration: _inputDecoration(
                  'Password (min 8 characters)',
                  Icons.lock,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Password must be at least 8 characters long',
                style: AppTypographyExtended.bodySmall.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 16),

              // Confirm Password
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: true,
                validator: _validatePasswordMatch,
                decoration: _inputDecoration(
                  'Confirm Password',
                  Icons.lock_outline,
                ),
              ),
              const SizedBox(height: 24),

              PrimaryButton(
                text: "Register",
                onPressed: _register,
                isLoading: _isLoading,
                fullWidth: true,
                size: ButtonSize.large,
              ),

              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  Navigator.pushReplacementNamed(context, '/login');
                },
                child: Text(
                  'Already have an account? Login',
                  style: TextStyle(color: theme.colorScheme.primary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Reusable input decoration
  InputDecoration _inputDecoration(String hint, IconData icon) {
    final theme = Theme.of(context);
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
      ),
      prefixIcon: Icon(
        icon,
        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
      ),
      filled: true,
      fillColor: theme.colorScheme.surfaceContainerHighest,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: theme.colorScheme.outline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: theme.colorScheme.outline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
      ),
    );
  }
}

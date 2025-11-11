import 'package:flutter/material.dart';
import '../../../core/api_client.dart';
import '../../../core/error_dialog.dart';
import '../../../core/theme/theme_config.dart';

import '../../../widgets/custom_button.dart';
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

  /// Register user after verifying OTP
  void _register() async {
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
        '/api/auth/register',
        body: {
          'phone_number': phone,
          'password': _passwordController.text,
          'team_name': _teamNameController.text,
          'location': _locationController.text,
        },
      );

      final data = jsonDecode(response.body);

      if (!mounted) return;

      if (response.statusCode == 201 || response.statusCode == 200) {
        ErrorDialog.showSuccessSnackBar(
          context,
          message: data['message'] ?? 'Registration successful',
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
      ErrorDialog.showErrorSnackBar(context, message: e.toString());
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

              // Phone number
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
                  'Password (min 8 chars, 1 uppercase, 1 number)',
                  Icons.lock,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Password must contain: at least 8 characters',
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

              PrimaryButton(
                text: "Register",
                onPressed: _register,
                isLoading: _isLoading,
                fullWidth: true,
                size: ButtonSize.large,
              )
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

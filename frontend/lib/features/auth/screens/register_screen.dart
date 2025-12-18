import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import '../../../core/api_client.dart';
import '../../../core/error_dialog.dart';
import '../../../core/theme/theme_config.dart';
import '../../../widgets/custom_button.dart';
// [Added] Import new helpers
import '../../../core/utils/app_validators.dart';
import '../../../core/theme/app_input_styles.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  final _formKey = GlobalKey<FormState>();

  // Toggle between phone and email
  bool _useEmail = false;

  /// Register user
  void _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final body = <String, String>{
        'password': _passwordController.text,
      };

      if (_useEmail) {
        body['email'] = _emailController.text.trim();
      } else {
        // [Fixed] Use shared formatter
        body['phone_number'] = AppValidators.formatPhoneNumber(_phoneController.text.trim());
      }

      final response = await ApiClient.instance.post('/api/auth/register', body: body);

      if (!mounted) return;

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ ${data['message'] ?? 'Registration successful. Please login.'}'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pushReplacementNamed(context, '/login');
      } else {
        String message;
        try {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          message = data['error'] ?? 'Registration failed. Please check your details.';
        } catch (_) {
          message = 'Registration failed (Error ${response.statusCode}). Please try again.';
        }

        if (response.statusCode == 409) {
          final identifierType = _useEmail ? 'Email' : 'Phone number';
          message = '$identifierType is already registered.';
        } else if (response.statusCode >= 500) {
          message = 'Server error. Please try again later.';
        }

        ErrorDialog.show(context, message);
      }
    } catch (e) {
      if (!mounted) return;
      final errorMessage = e is SocketException
          ? 'No internet connection. Please check your network.'
          : 'An unexpected error occurred during registration.';
      ErrorDialog.show(context, errorMessage);
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
              // Registration method toggle
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Register with',
                  style: AppTypographyExtended.bodyMedium.copyWith(
                    color: theme.colorScheme.onSurface.withAlpha(179),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SegmentedButton<bool>(
                segments: const <ButtonSegment<bool>>[
                  ButtonSegment<bool>(
                    value: false,
                    icon: Icon(Icons.phone),
                    label: Text('Phone'),
                  ),
                  ButtonSegment<bool>(
                    value: true,
                    icon: Icon(Icons.email),
                    label: Text('Email'),
                  ),
                ],
                selected: <bool>{_useEmail},
                onSelectionChanged: (Set<bool> newSelection) {
                  setState(() {
                    _useEmail = newSelection.first;
                    // Clear inputs when switching methods to avoid confusion
                    _emailController.clear();
                    _phoneController.clear();
                  });
                },
              ),
              const SizedBox(height: 16),

              // Phone or Email field
              if (_useEmail)
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  // [Fixed] Use shared validator
                  validator: AppValidators.validateEmail,
                  // [Fixed] Use shared decoration
                  decoration: AppInputStyles.textFieldDecoration(
                    context: context,
                    hintText: 'Email Address',
                    prefixIcon: Icons.email,
                  ),
                )
              else
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  // [Fixed] Use shared validator
                  validator: AppValidators.validatePhoneNumber,
                  // [Fixed] Use shared decoration
                  decoration: AppInputStyles.textFieldDecoration(
                    context: context,
                    hintText: 'Phone Number (03XX-XXXXXXX)',
                    prefixIcon: Icons.phone,
                  ),
                ),
              const SizedBox(height: 16),

              // Password with requirements
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                // [Fixed] Use shared validator
                validator: AppValidators.validatePassword,
                decoration: AppInputStyles.textFieldDecoration(
                  context: context,
                  hintText: 'Password (min 8 characters)',
                  prefixIcon: Icons.lock,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Password must be at least 8 characters long',
                style: AppTypographyExtended.bodySmall.copyWith(
                  color: theme.colorScheme.onSurface.withAlpha(153),
                ),
              ),
              const SizedBox(height: 16),

              // Confirm Password
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: true,
                // [Fixed] Use shared validator with confirm logic
                validator: (value) => AppValidators.validateConfirmPassword(
                  value,
                  _passwordController.text,
                ),
                decoration: AppInputStyles.textFieldDecoration(
                  context: context,
                  hintText: 'Confirm Password',
                  prefixIcon: Icons.lock_outline,
                ),
              ),
              const SizedBox(height: 24),

              PrimaryButton(
                text: "Register",
                onPressed: _isLoading ? null : _register,
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
}
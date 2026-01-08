import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/api_client.dart';
import '../../../core/auth_provider.dart';
import '../../../core/error_dialog.dart';
import '../../../core/secure_storage.dart';
import '../../../core/icons.dart';
import '../../../widgets/custom_button.dart';
import '../../../core/error_handler.dart';
// [Added] Import new helpers
import '../../../core/utils/app_validators.dart';
import '../../../core/theme/app_input_styles.dart';

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
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _loadSavedPhone();
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
    if (_isLoading) return; // Prevent multiple submissions
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // [Fixed] Use shared validator helper
    final phone = AppValidators.formatPhoneNumber(_phoneController.text.trim());
    final password = _passwordController.text.trim();

    if (_rememberMe) {
      await SecureStorage.saveString('remembered_phone', _phoneController.text);
    } else {
      await SecureStorage.deleteString('remembered_phone');
    }

    setState(() => _isLoading = true);

    try {
      final response = await ApiClient.instance.post(
        '/api/auth/login',
        body: {'phone_number': phone, 'password': password},
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final token = data['token']?.toString();
        final refresh = data['refresh_token']?.toString();

        if (token == null || token.isEmpty) {
          throw Exception('Invalid response from server: token is missing.');
        }

        await ApiClient.instance.setToken(token);
        if (refresh != null && refresh.isNotEmpty) {
          await ApiClient.instance.setRefreshToken(refresh);
        }

        if (!mounted) return;

        await context.read<AuthProvider>().initializeAuth();

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Login successful'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        String message;
        try {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          message =
              data['error'] ?? 'Login failed. Please check your credentials.';
        } catch (_) {
          message =
              'Login failed (Error ${response.statusCode}). Please try again.';
        }

        if (response.statusCode == 401) {
          message = 'Invalid phone number or password.';
        } else if (response.statusCode >= 500) {
          message = 'Server error. Please try again later.';
        }

        ErrorDialog.show(context, message);
      }
    } on ApiHttpException catch (e) {
      if (!mounted) return;
      String message = e.message;
      if (e.statusCode == 429) {
        message = 'Too many login attempts. Please try again later.';
      }
      ErrorDialog.show(context, message);
    } catch (e) {
      if (!mounted) return;
      final errorMessage = e is SocketException
          ? 'No internet connection. Please check your network.'
          : 'An unexpected error occurred during login.';
      ErrorDialog.show(context, errorMessage);
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
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.colorScheme.onSurface),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              Navigator.of(context).pushReplacementNamed('/home');
            }
          },
        ),
      ),
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
                    AppIcons.cricketIcon(
                      size: AppIcons.xxl,
                      color: const Color(0xFF36E27B),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "CricLeague",
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 40),

                // Phone
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  // [Fixed] Use shared validator
                  validator: AppValidators.validatePhoneNumber,
                  // [Fixed] Use shared input decoration
                  decoration: AppInputStyles.textFieldDecoration(
                    context: context,
                    hintText: "Phone number (e.g., 03XX-XXXXXXX)",
                    prefixIcon: Icons.phone,
                  ),
                ),
                const SizedBox(height: 16),

                // Password
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  // [Fixed] Use shared validator
                  validator: AppValidators.validatePassword,
                  // [Fixed] Use shared input decoration
                  decoration: AppInputStyles.textFieldDecoration(
                    context: context,
                    hintText: "Password (min 8 characters)",
                    prefixIcon: Icons.lock,
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
                    Text(
                      'Remember my phone number',
                      style: TextStyle(color: theme.colorScheme.onSurface),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Forgot password
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _handleForgotPassword,
                    child: Text(
                      "Forgot Password?",
                      style: TextStyle(color: theme.colorScheme.primary),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Login Button
                PrimaryButton(
                  text: "Login",
                  onPressed: _isLoading ? null : _login,
                  isLoading: _isLoading,
                  fullWidth: true,
                  size: ButtonSize.large,
                ),
                const SizedBox(height: 12),

                // Register Button
                SecondaryButton(
                  text: "Register",
                  onPressed: _isLoading ? null : _navigateToRegister,
                  fullWidth: true,
                  size: ButtonSize.large,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

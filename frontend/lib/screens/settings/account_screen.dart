import 'dart:io';
import 'package:flutter/material.dart';
import '../../core/api_client.dart';
// Use core input styles
import '../../core/theme/app_input_styles.dart'; 

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final _pwdFormKey = GlobalKey<FormState>();
  final _phoneFormKey = GlobalKey<FormState>();

  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();
  final _phoneController = TextEditingController();

  bool _loadingPwd = false;
  bool _loadingPhone = false;

  // Password visibility toggles
  bool _showCurrent = false;
  bool _showNew = false;
  bool _showConfirm = false;

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  // Format phone number to E.164 for Pakistan (92XXXXXXXXXX)
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

  // Basic validation for Pakistan phone numbers
  bool _isValidPkPhone(String phone) {
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('92') && digits.length == 12) return true;
    if (digits.startsWith('0') && digits.length == 11) return true;
    if (!digits.startsWith('0') && !digits.startsWith('92') && digits.length == 10) {
      return true;
    }
    return false;
  }

  Future<void> _changePassword() async {
    if (!_pwdFormKey.currentState!.validate()) return;

    setState(() => _loadingPwd = true);
    try {
      final response = await ApiClient.instance.put(
        '/api/auth/change-password',
        body: {
          'current_password': _currentController.text.trim(),
          'new_password': _newController.text.trim()
        },
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Password changed successfully. Please re-login on other devices.'),
            backgroundColor: Colors.green,
          ),
        );
        _currentController.clear();
        _newController.clear();
        _confirmController.clear();
      } else if (response.statusCode == 400) {
        _showError('Current password is incorrect');
      } else if (response.statusCode == 401) {
        _showError('Authentication failed. Please log in again.');
      } else {
        _showError('Failed to change password (${response.statusCode})');
      }
    } catch (e) {
      if (mounted) {
        final msg = e is SocketException ? 'No internet connection' : 'An error occurred';
        _showError(msg);
      }
    } finally {
      if (mounted) setState(() => _loadingPwd = false);
    }
  }

  Future<void> _changePhone() async {
    if (!_phoneFormKey.currentState!.validate()) return;

    final phone = _formatPhoneNumber(_phoneController.text.trim());

    setState(() => _loadingPhone = true);
    try {
      final response = await ApiClient.instance.put(
        '/api/auth/change-phone',
        body: {'new_phone_number': phone},
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Phone number updated successfully'), backgroundColor: Colors.green),
        );
        _phoneController.clear();
      } else if (response.statusCode == 400) {
        _showError('Invalid phone number format');
      } else if (response.statusCode == 409) {
        _showError('Phone number already in use');
      } else {
        _showError('Failed to update phone number (${response.statusCode})');
      }
    } catch (e) {
      if (mounted) {
        final msg = e is SocketException ? 'No internet connection' : 'An error occurred';
        _showError(msg);
      }
    } finally {
      if (mounted) setState(() => _loadingPhone = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Theme.of(context).colorScheme.error),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('Account Settings'),
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: theme.colorScheme.onSurface,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Change Password Section
            _buildSectionHeader(theme, 'Security', Icons.lock_outline),
            const SizedBox(height: 16),
            Form(
              key: _pwdFormKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _currentController,
                    obscureText: !_showCurrent,
                    decoration: AppInputStyles.textFieldDecoration(
                      context: context,
                      hintText: 'Current Password',
                      prefixIcon: Icons.key,
                    ).copyWith(
                      suffixIcon: IconButton(
                        icon: Icon(_showCurrent ? Icons.visibility_off : Icons.visibility),
                        onPressed: () => setState(() => _showCurrent = !_showCurrent),
                      ),
                    ),
                    validator: (val) => val!.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _newController,
                    obscureText: !_showNew,
                    decoration: AppInputStyles.textFieldDecoration(
                      context: context,
                      hintText: 'New Password',
                      prefixIcon: Icons.lock_reset,
                    ).copyWith(
                      suffixIcon: IconButton(
                        icon: Icon(_showNew ? Icons.visibility_off : Icons.visibility),
                        onPressed: () => setState(() => _showNew = !_showNew),
                      ),
                    ),
                    validator: (val) {
                      if (val == null || val.isEmpty) return 'Required';
                      if (val.length < 8) return 'Min 8 characters';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _confirmController,
                    obscureText: !_showConfirm,
                    decoration: AppInputStyles.textFieldDecoration(
                      context: context,
                      hintText: 'Confirm Password',
                      prefixIcon: Icons.lock_outline,
                    ).copyWith(
                      suffixIcon: IconButton(
                        icon: Icon(_showConfirm ? Icons.visibility_off : Icons.visibility),
                        onPressed: () => setState(() => _showConfirm = !_showConfirm),
                      ),
                    ),
                    validator: (val) {
                      if (val != _newController.text) return 'Passwords do not match';
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _loadingPwd ? null : _changePassword,
                      child: _loadingPwd
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('Update Password'),
                    ),
                  ),
                ],
              ),
            ),

            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Divider(),
            ),

            // Change Phone Section
            _buildSectionHeader(theme, 'Contact Info', Icons.phone_iphone),
            const SizedBox(height: 16),
            Form(
              key: _phoneFormKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: AppInputStyles.textFieldDecoration(
                      context: context,
                      hintText: 'New Phone Number (03XX...)',
                      prefixIcon: Icons.phone,
                    ),
                    validator: (val) {
                      if (val == null || val.isEmpty) return 'Required';
                      if (!_isValidPkPhone(val)) return 'Invalid format';
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.tonal(
                      onPressed: _loadingPhone ? null : _changePhone,
                      child: _loadingPhone
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Text('Update Phone Number'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(ThemeData theme, String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: theme.colorScheme.primary, size: 24),
        const SizedBox(width: 12),
        Text(
          title,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}
import 'dart:io';
import 'package:flutter/material.dart';
import '../../core/api_client.dart';
import 'developer_settings_screen.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();

  final _phoneController = TextEditingController();

  bool _loadingPwd = false;
  bool _loadingPhone = false;

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    final current = _currentController.text.trim();
    final next = _newController.text.trim();
    final confirm = _confirmController.text.trim();
    if (current.isEmpty || next.isEmpty || confirm.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Fill all fields')));
      return;
    }
    if (next != confirm) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Passwords do not match')));
      return;
    }
    setState(() => _loadingPwd = true);
    try {
      final response = await ApiClient.instance.put(
        '/api/auth/change-password',
        body: {'current_password': current, 'new_password': next},
      );

      if (response.statusCode == 200) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Password changed successfully. Please re-login on other devices.')),
        );
        // Clear form
        _currentController.clear();
        _newController.clear();
        _confirmController.clear();
      } else if (response.statusCode == 400) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Current password is incorrect')),
          );
        }
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Authentication failed. Please log in again.')),
          );
        }
      } else if (response.statusCode >= 500) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Server error. Please try again later.')),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to change password (${response.statusCode})')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        final errorMessage = e is SocketException
            ? 'No internet connection. Please check your network and try again.'
            : 'Failed to change password. Please try again.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      }
    } finally {
      if (mounted) setState(() => _loadingPwd = false);
    }
  }

  Future<void> _changePhone() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Enter phone number')));
      return;
    }
    setState(() => _loadingPhone = true);
    try {
      final response = await ApiClient.instance.put(
        '/api/auth/change-phone',
        body: {'new_phone_number': phone},
      );

      if (response.statusCode == 200) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Phone number updated successfully')),
        );
        // Clear form
        _phoneController.clear();
      } else if (response.statusCode == 400) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Invalid phone number format')),
          );
        }
      } else if (response.statusCode == 409) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Phone number already in use')),
          );
        }
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Authentication failed. Please log in again.')),
          );
        }
      } else if (response.statusCode >= 500) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Server error. Please try again later.')),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to update phone number (${response.statusCode})')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        final errorMessage = e is SocketException
            ? 'No internet connection. Please check your network and try again.'
            : 'Failed to update phone number. Please try again.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      }
    } finally {
      if (mounted) setState(() => _loadingPhone = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Account')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Change Password',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _currentController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Current Password'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _newController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'New Password'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _confirmController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Confirm Password'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _loadingPwd ? null : _changePassword,
              child: _loadingPwd
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save Password'),
            ),
            const Divider(height: 32),
            const Text(
              'Change Phone Number',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'New Phone Number'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _loadingPhone ? null : _changePhone,
              child: _loadingPhone
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save Phone'),
            ),
            const Divider(height: 32),

            // API Configuration Section
            const Text(
              'Developer Settings',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Card(
              child: ListTile(
                leading: const Icon(Icons.settings_ethernet),
                title: const Text('API Configuration'),
                subtitle: FutureBuilder<String>(
                  future: ApiClient.instance.getConfiguredBaseUrl(),
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      final url = snapshot.data!;
                      final displayUrl = url.length > 40
                          ? '${url.substring(0, 37)}...'
                          : url;
                      return Text(displayUrl);
                    }
                    return const Text('Loading...');
                  },
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const DeveloperSettingsScreen(),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

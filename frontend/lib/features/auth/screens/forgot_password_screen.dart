import 'package:flutter/material.dart';
import '../../../core/api_client.dart';
import '../../../core/error_handler.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _phoneController = TextEditingController();
  final _tokenController = TextEditingController();
  final _newPassController = TextEditingController();
  bool _isRequesting = false;
  bool _isConfirming = false;
  bool _requested = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _tokenController.dispose();
    _newPassController.dispose();
    super.dispose();
  }

  Future<void> _request() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      ErrorHandler.showErrorSnackBar(context, 'Enter phone number');
      return;
    }
    setState(() => _isRequesting = true);
    try {
      final resp = await ApiClient.instance.postJson(
        '/api/auth/forgot-password',
        body: {'phone_number': phone},
      );
      setState(() => _requested = true);
      ErrorHandler.showSuccessSnackBar(
        context, 
        'If account exists, reset started.'
      );
      // For dev, if token returned, show it
      final token = (resp as Map<String, dynamic>)['token']?.toString();
      if (token != null && token.isNotEmpty && mounted) {
        _tokenController.text = token;
      }
    } catch (e) {
      ErrorHandler.showErrorSnackBar(context, e);
    } finally {
      if (mounted) setState(() => _isRequesting = false);
    }
  }

  Future<void> _confirm() async {
    final phone = _phoneController.text.trim();
    final token = _tokenController.text.trim();
    final newPass = _newPassController.text.trim();
    if (phone.isEmpty || token.isEmpty || newPass.isEmpty) {
      ErrorHandler.showErrorSnackBar(context, 'Fill all fields');
      return;
    }
    setState(() => _isConfirming = true);
    try {
      await ApiClient.instance.postJson(
        '/api/auth/reset-password',
        body: {'phone_number': phone, 'token': token, 'new_password': newPass},
      );
      if (!mounted) return;
      ErrorHandler.showSuccessSnackBar(
        context,
        'Password reset successful. Please login.',
      );
      Navigator.pop(context);
    } catch (e) {
      ErrorHandler.showErrorSnackBar(context, e);
    } finally {
      if (mounted) setState(() => _isConfirming = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Forgot Password')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Phone number'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isRequesting ? null : _request,
              child: _isRequesting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Request Reset'),
            ),
            const Divider(height: 32),
            if (_requested) ...[
              TextField(
                controller: _tokenController,
                decoration: const InputDecoration(labelText: 'OTP / Token'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _newPassController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'New Password'),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _isConfirming ? null : _confirm,
                child: _isConfirming
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Confirm Reset'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

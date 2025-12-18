import 'dart:io';
import 'package:flutter/material.dart';
import '../../core/api_client.dart';
// Use your core input styles if available, otherwise fall back to theme
import '../../core/theme/app_input_styles.dart'; 

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final _formKey = GlobalKey<FormState>();
  final _messageController = TextEditingController();
  final _contactController = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _messageController.dispose();
    _contactController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final message = _messageController.text.trim();
    final contact = _contactController.text.trim();

    FocusScope.of(context).unfocus();

    setState(() => _loading = true);
    try {
      final Map<String, dynamic> body = {'message': message};
      if (contact.isNotEmpty) {
        body['contact'] = contact;
      }

      final response = await ApiClient.instance.post('/api/feedback', body: body);

      if (response.statusCode == 201 || response.statusCode == 200) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Thanks for your feedback!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        _messageController.clear();
        _contactController.clear();
        Navigator.pop(context);
      } else {
        if (!mounted) return;
        _showError('Failed to submit feedback (${response.statusCode})');
      }
    } catch (e) {
      if (!mounted) return;
      final errorMessage = e is SocketException
          ? 'No internet connection.'
          : 'An unexpected error occurred.';
      _showError(errorMessage);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('Feedback'),
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: theme.colorScheme.onSurface,
        elevation: 0,
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header Icon
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.chat_bubble_outline,
                      size: 48,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                
                Text(
                  'We value your input!',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Share your thoughts, report bugs, or suggest features to help us improve.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                // Message Input
                TextFormField(
                  controller: _messageController,
                  maxLines: 5,
                  maxLength: 1000,
                  validator: (val) {
                    if ((val?.trim() ?? '').length < 5) {
                      return 'Please enter at least 5 characters';
                    }
                    return null;
                  },
                  decoration: AppInputStyles.textFieldDecoration(
                    context: context,
                    hintText: 'Your message...',
                    prefixIcon: Icons.edit,
                  ).copyWith(
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 16),

                // Contact Input
                TextFormField(
                  controller: _contactController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: AppInputStyles.textFieldDecoration(
                    context: context,
                    hintText: 'Email or phone (optional)',
                    prefixIcon: Icons.contact_mail,
                  ),
                ),
                const SizedBox(height: 32),

                // Buttons
                FilledButton.icon(
                  onPressed: _loading ? null : _submit,
                  icon: _loading 
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.send),
                  label: Text(_loading ? 'Sending...' : 'Submit Feedback'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: _loading ? null : () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
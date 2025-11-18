import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../core/api_client.dart';

class DeveloperSettingsScreen extends StatefulWidget {
  const DeveloperSettingsScreen({super.key});

  @override
  State<DeveloperSettingsScreen> createState() =>
      _DeveloperSettingsScreenState();
}

class _DeveloperSettingsScreenState extends State<DeveloperSettingsScreen> {
  final _urlController = TextEditingController();
  bool _loading = false;
  String _currentUrl = '';
  String _platformDefaultUrl = '';

  @override
  void initState() {
    super.initState();
    _loadCurrentConfiguration();
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentConfiguration() async {
    final currentUrl = await ApiClient.instance.getConfiguredBaseUrl();
    final platformDefault = ApiClient.instance.getPlatformDefaultUrl();

    setState(() {
      _currentUrl = currentUrl;
      _platformDefaultUrl = platformDefault;
      _urlController.text = currentUrl;
    });
  }

  bool _isValidUrl(String url) {
    if (url.isEmpty) return false;
    try {
      final uri = Uri.parse(url);
      return uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https');
    } catch (e) {
      return false;
    }
  }

  Future<void> _testConnection() async {
    final url = _urlController.text.trim();
    if (!_isValidUrl(url)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid URL (http:// or https://)'),
        ),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      // Test the connection by calling the health endpoint
      final response = await http
          .get(
            Uri.parse('$url/health'),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        // Connection successful - normalize URL before saving
        final normalizedUrl = url.replaceAll(RegExp(r'/+$'), '');
        await ApiClient.instance.setCustomBaseUrl(normalizedUrl);

        // Reload current configuration to get resolved URL
        await _loadCurrentConfiguration();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Connection successful! URL saved.'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        throw Exception('Server returned status ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        String errorMessage;
        if (e is SocketException) {
          errorMessage = 'No internet connection. Please check your network and try again.';
        } else if (e.toString().contains('Connection refused')) {
          errorMessage = 'Connection refused. Make sure the backend server is running on port 5000.';
        } else if (e.toString().contains('Network is unreachable')) {
          errorMessage = 'Network unreachable. Check if your device and computer are on the same network.';
        } else if (e.toString().contains('CORS')) {
          errorMessage = 'CORS error. Add this origin to backend CORS_ORIGINS in .env file.';
        } else if (e.toString().contains('TimeoutException')) {
          errorMessage = 'Connection timed out. The server may be slow or unreachable.';
        } else {
          errorMessage = 'Connection failed. Please check the URL and try again.';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resetToDefault() async {
    await ApiClient.instance.clearCustomBaseUrl();
    await _loadCurrentConfiguration();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Reset to platform default'),
          backgroundColor: Colors.blue,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('API Configuration'),
        backgroundColor: theme.colorScheme.surfaceContainerHighest,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Current API URL Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Current API URL',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _currentUrl,
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Platform Default Info
            Card(
              color: theme.colorScheme.surfaceContainerHighest,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Platform Default',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _platformDefaultUrl,
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontFamily: 'monospace',
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'This is the default URL for your current platform.',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Custom URL Configuration
            const Text(
              'Custom API URL',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _urlController,
              decoration: const InputDecoration(
                labelText: 'Enter API Base URL',
                hintText: 'http://192.168.1.100:5000',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.link),
              ),
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 16),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _loading ? null : _testConnection,
                    icon: _loading
                        ? const SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.wifi_find),
                    label: Text(_loading ? 'Testing...' : 'Test Connection'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _loading ? null : _resetToDefault,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Reset to Default'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Help Section
            ExpansionTile(
              title: const Text(
                'Help & Troubleshooting',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHelpItem(
                        'Physical Android Device',
                        'Use your computer\'s IP address (e.g., http://192.168.1.100:5000)',
                        Icons.phone_android,
                      ),
                      const SizedBox(height: 12),
                      _buildHelpItem(
                        'iOS Simulator',
                        'Use http://localhost:5000 or leave default',
                        Icons.phone_iphone,
                      ),
                      const SizedBox(height: 12),
                      _buildHelpItem(
                        'Web Browser',
                        'Use http://localhost:5000 or leave default',
                        Icons.web,
                      ),
                      const SizedBox(height: 12),
                      _buildHelpItem(
                        'Desktop App',
                        'Use http://localhost:5000 or leave default',
                        Icons.desktop_windows,
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.secondaryContainer,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: theme.colorScheme.secondary),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.info,
                                  color: theme.colorScheme.secondary,
                                  size: 16,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Finding Your Computer\'s IP Address',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.onSecondaryContainer,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Windows: Open Command Prompt, run "ipconfig"\n'
                              'macOS: Open Terminal, run "ifconfig | grep inet"\n'
                              'Linux: Open Terminal, run "ip addr show"',
                              style: TextStyle(
                                fontSize: 12,
                                color: theme.colorScheme.onSecondaryContainer,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHelpItem(String title, String description, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.blue.shade600),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 2),
              Text(
                description,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

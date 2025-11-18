import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/api_client.dart';
import '../../../core/offline/offline_manager.dart';
import '../../../models/pending_operation.dart';
import '../../../core/theme/theme_config.dart';
import '../../../widgets/custom_button.dart';

class CreateTeamScreen extends StatefulWidget {
  const CreateTeamScreen({super.key});

  @override
  State<CreateTeamScreen> createState() => _CreateTeamScreenState();
}

class _CreateTeamScreenState extends State<CreateTeamScreen> {
  final TextEditingController _teamNameController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _logoUrlController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  bool _isDisposed = false;
  String? _errorMessage;

  // Safe helpers
  dynamic _safeJsonDecode(String body) {
    try {
      if (body.isEmpty) {
        throw const FormatException('Empty response body');
      }
      return jsonDecode(body);
    } on FormatException catch (e) {
      debugPrint('JSON decode error: $e');
      debugPrint('Response body: $body');
      throw FormatException('Invalid JSON response: ${e.message}');
    } catch (e) {
      debugPrint('Unexpected decode error: $e');
      rethrow;
    }
  }

  void _safeSetState(VoidCallback fn) {
    if (!_isDisposed && mounted) {
      setState(fn);
    }
  }

  String _getErrorMessage(dynamic error) {
    if (error == null) return 'Unknown error';
    final message = error.toString();
    return message.replaceAll('Exception:', '').trim();
  }

  /// Validate team name
  String? _validateTeamName(String? value) {
    try {
      if (value == null || value.trim().isEmpty) {
        return 'Team name is required';
      }
      
      final trimmed = value.trim();
      
      if (trimmed.length < 3) {
        return 'Team name must be at least 3 characters';
      }
      
      if (trimmed.length > 50) {
        return 'Team name must not exceed 50 characters';
      }

      // Check for special characters (allow letters, numbers, spaces, hyphens)
      if (!RegExp(r'^[a-zA-Z0-9\s\-]+$').hasMatch(trimmed)) {
        return 'Team name can only contain letters, numbers, spaces, and hyphens';
      }
      
      return null;
    } catch (e) {
      debugPrint('Error validating team name: $e');
      return 'Invalid team name';
    }
  }

  /// Validate location
  String? _validateLocation(String? value) {
    try {
      if (value == null || value.trim().isEmpty) {
        return 'Location is required';
      }
      
      final trimmed = value.trim();
      
      if (trimmed.length < 2) {
        return 'Location must be at least 2 characters';
      }
      
      if (trimmed.length > 100) {
        return 'Location must not exceed 100 characters';
      }
      
      return null;
    } catch (e) {
      debugPrint('Error validating location: $e');
      return 'Invalid location';
    }
  }

  /// Validate logo URL
  String? _validateLogoUrl(String? value) {
    try {
      if (value == null || value.trim().isEmpty) {
        return null; // Optional field
      }

      final trimmed = value.trim();

      // Basic URL validation
      final urlPattern = RegExp(
        r'^https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)$',
      );

      if (!urlPattern.hasMatch(trimmed)) {
        return 'Please enter a valid URL (starting with http:// or https://)';
      }

      // Check if URL ends with image extension
      final imageExtensions = ['.jpg', '.jpeg', '.png', '.gif', '.webp', '.svg'];
      final hasImageExtension = imageExtensions.any(
        (ext) => trimmed.toLowerCase().endsWith(ext),
      );

      if (!hasImageExtension) {
        return 'URL should point to an image file (.jpg, .png, etc.)';
      }

      return null;
    } catch (e) {
      debugPrint('Error validating logo URL: $e');
      return 'Invalid URL format';
    }
  }

  /// Create team
  Future<void> _createTeam() async {
    if (_isLoading || _isDisposed) return;

    // Validate form
    final formState = _formKey.currentState;
    if (formState == null || !formState.validate()) {
      return;
    }

    _safeSetState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final teamName = _teamNameController.text.trim();
      final location = _locationController.text.trim();
      final logoUrl = _logoUrlController.text.trim();

      // Validate inputs again (defensive programming)
      if (teamName.isEmpty) {
        throw Exception('Team name is required');
      }

      if (location.isEmpty) {
        throw Exception('Location is required');
      }

      final body = {
        'team_name': teamName,
        'team_location': location,
      };

      // Add logo URL if provided and valid
      if (logoUrl.isNotEmpty) {
        final logoValidation = _validateLogoUrl(logoUrl);
        if (logoValidation != null) {
          throw Exception(logoValidation);
        }
        body['team_logo_url'] = logoUrl;
      }

      // Get offline manager safely
      OfflineManager? offlineManager;
      try {
        offlineManager = Provider.of<OfflineManager>(context, listen: false);
      } catch (e) {
        debugPrint('Error getting offline manager: $e');
      }

      // Check if offline
      if (offlineManager != null && !offlineManager.isOnline) {
        await _handleOfflineCreation(offlineManager, body);
        return;
      }

      // Online flow
      await _handleOnlineCreation(body);
    } catch (e, stackTrace) {
      debugPrint('Error creating team: $e');
      debugPrint('Stack trace: $stackTrace');
      
      if (!_isDisposed && mounted) {
        final errorMessage = e is SocketException
            ? 'No internet connection. Please check your network and try again.'
            : 'Team creation failed: ${_getErrorMessage(e)}';
        
        _safeSetState(() => _errorMessage = errorMessage);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (!_isDisposed) {
        _safeSetState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleOfflineCreation(
    OfflineManager offlineManager,
    Map<String, dynamic> body,
  ) async {
    try {
      await offlineManager.queueOperation(
        operationType: OperationType.create,
        entityType: 'team',
        entityId: 0,
        data: body,
      );

      if (!_isDisposed && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Team creation queued for sync when online'),
          ),
        );

        await Future.delayed(const Duration(milliseconds: 300));

        if (!_isDisposed && mounted) {
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      debugPrint('Error queuing offline operation: $e');
      throw Exception('Failed to queue team creation');
    }
  }

  Future<void> _handleOnlineCreation(Map<String, dynamic> body) async {
    try {
      final response = await ApiClient.instance.post(
        '/api/teams/my-team',
        body: body,
      );

      if (_isDisposed) return;

      if (response.statusCode == 201 || response.statusCode == 200) {
        await _handleSuccessResponse(response);
      } else {
        await _handleErrorResponse(response);
      }
    } catch (e) {
      debugPrint('Error in online creation: $e');
      rethrow;
    }
  }

  Future<void> _handleSuccessResponse(dynamic response) async {
    try {
      String message = 'Team created successfully';

      try {
        final data = _safeJsonDecode(response.body);
        if (data is Map<String, dynamic>) {
          message = data['message']?.toString() ?? message;
        }
      } catch (e) {
        debugPrint('Error parsing success response: $e');
        // Continue with default message
      }

      if (!_isDisposed && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('✅ $message')),
        );

        await Future.delayed(const Duration(milliseconds: 300));

        if (!_isDisposed && mounted) {
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      debugPrint('Error handling success response: $e');
    }
  }

  Future<void> _handleErrorResponse(dynamic response) async {
    try {
      String errorMsg = 'Team creation failed';

      if (response.statusCode == 400) {
        try {
          final data = _safeJsonDecode(response.body);
          errorMsg = data is Map<String, dynamic>
              ? (data['error']?.toString() ?? 'Invalid team data')
              : 'Invalid team data';
        } catch (e) {
          debugPrint('Error parsing 400 response: $e');
          errorMsg = 'Invalid team data';
        }
      } else if (response.statusCode == 409) {
        errorMsg = 'You already have a team';
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        errorMsg = 'Authentication failed. Please log in again.';
      } else if (response.statusCode >= 500) {
        errorMsg = 'Server error. Please try again later.';
      } else {
        errorMsg = 'Team creation failed (${response.statusCode})';
      }

      if (!_isDisposed && mounted) {
        _safeSetState(() => _errorMessage = errorMsg);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error handling error response: $e');
    }
  }

  void _handleCancel() {
    if (_isLoading) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please wait for the current operation to complete'),
        ),
      );
      return;
    }

    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _teamNameController.dispose();
    _locationController.dispose();
    _logoUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return WillPopScope(
      onWillPop: () async {
        if (_isLoading) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please wait for the current operation to complete'),
            ),
          );
          return false;
        }
        return true;
      },
      child: Scaffold(
        backgroundColor: theme.colorScheme.surface,
        appBar: AppBar(
          title: Text(
            'Create Team',
            style: AppTypographyExtended.headlineSmall.copyWith(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
          backgroundColor: theme.colorScheme.surface,
          foregroundColor: theme.colorScheme.onSurface,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _isLoading ? null : _handleCancel,
          ),
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
                    child: Row(
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: theme.colorScheme.onErrorContainer,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: AppTypographyExtended.bodyMedium.copyWith(
                              color: theme.colorScheme.onErrorContainer,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 20),
                          color: theme.colorScheme.onErrorContainer,
                          onPressed: () {
                            _safeSetState(() => _errorMessage = null);
                          },
                        ),
                      ],
                    ),
                  ),

                // Info text
                Container(
                  margin: const EdgeInsets.only(bottom: 24),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Create your cricket team to start participating in tournaments and managing players.',
                          style: AppTypographyExtended.bodyMedium.copyWith(
                            color: theme.colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Team Name
                TextFormField(
                  controller: _teamNameController,
                  enabled: !_isLoading,
                  validator: _validateTeamName,
                  textCapitalization: TextCapitalization.words,
                  decoration: _inputDecoration(
                    'Team Name',
                    Icons.sports_cricket,
                  ),
                  maxLength: 50,
                ),
                const SizedBox(height: 16),

                // Location
                TextFormField(
                  controller: _locationController,
                  enabled: !_isLoading,
                  validator: _validateLocation,
                  textCapitalization: TextCapitalization.words,
                  decoration: _inputDecoration(
                    'Location (City/Region)',
                    Icons.location_on,
                  ),
                  maxLength: 100,
                ),
                const SizedBox(height: 16),

                // Team Logo URL (Optional)
                TextFormField(
                  controller: _logoUrlController,
                  enabled: !_isLoading,
                  validator: _validateLogoUrl,
                  keyboardType: TextInputType.url,
                  decoration: _inputDecoration(
                    'Team Logo URL (Optional)',
                    Icons.image,
                  ).copyWith(
                    helperText: 'Leave empty to use default logo. Must be a valid image URL.',
                    helperMaxLines: 2,
                    helperStyle: AppTypographyExtended.bodySmall.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                PrimaryButton(
                  text: "Create Team",
                  onPressed: _isLoading ? null : _createTeam,
                  isLoading: _isLoading,
                  fullWidth: true,
                  size: ButtonSize.large,
                ),

                const SizedBox(height: 16),
                TextButton(
                  onPressed: _isLoading ? null : _handleCancel,
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      color: _isLoading
                          ? theme.colorScheme.onSurface.withOpacity(0.4)
                          : theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ),
              ],
            ),
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
        color: theme.colorScheme.onSurface.withOpacity(0.6),
      ),
      prefixIcon: Icon(
        icon,
        color: _isLoading
            ? theme.colorScheme.onSurface.withOpacity(0.4)
            : theme.colorScheme.onSurface.withOpacity(0.6),
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
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: theme.colorScheme.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: theme.colorScheme.error, width: 2),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: theme.colorScheme.outline.withOpacity(0.5),
        ),
      ),
    );
  }
}
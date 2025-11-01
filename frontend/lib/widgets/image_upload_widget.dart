import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/api_client.dart';
import '../../core/error_handler.dart';

typedef OnImageUploadSuccess = Function(String imageUrl);

class ImageUploadWidget extends StatefulWidget {
  final String title;
  final String? initialImageUrl;
  final String uploadType; // 'player' or 'team'
  final int entityId; // player ID or team ID
  final OnImageUploadSuccess? onSuccess;
  final VoidCallback? onDelete;

  const ImageUploadWidget({
    super.key,
    required this.title,
    required this.uploadType,
    required this.entityId,
    this.initialImageUrl,
    this.onSuccess,
    this.onDelete,
  });

  @override
  State<ImageUploadWidget> createState() => _ImageUploadWidgetState();
}

class _ImageUploadWidgetState extends State<ImageUploadWidget> {
  bool _isLoading = false;
  String? _currentImageUrl;
  File? _selectedImage;

  @override
  void initState() {
    super.initState();
    _currentImageUrl = widget.initialImageUrl;
  }

  /// Upload image to backend using multipart form data
  Future<void> _uploadImage(File imageFile) async {
    setState(() => _isLoading = true);

    try {
      final baseUrl = await ApiClient.instance.getConfiguredBaseUrl();
      final token = await ApiClient.instance.token;

      if (token == null || token.isEmpty) {
        throw Exception('Authentication required');
      }

      // Create multipart request
      final uri = Uri.parse(
        '$baseUrl/api/uploads/${widget.uploadType}/${widget.entityId}',
      );

      final request = http.MultipartRequest('POST', uri);
      request.headers['Authorization'] = 'Bearer $token';

      // Add image file
      final fieldName = widget.uploadType == 'player' ? 'photo' : 'logo';
      request.files.add(
        await http.MultipartFile.fromPath(fieldName, imageFile.path),
      );

      // Send request
      final streamResponse = await request.send();
      final response = await http.Response.fromStream(streamResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final imageUrl = data['imageUrl']?.toString();

        if (imageUrl != null) {
          setState(() => _currentImageUrl = imageUrl);
          if (!mounted) return;
          ErrorHandler.showSuccessSnackBar(
            context,
            'Image uploaded successfully',
          );
          widget.onSuccess?.call(imageUrl);
        }
      } else {
        throw Exception('Upload failed: ${response.statusCode}');
      }
    } catch (e) {
      if (!mounted) return;
      ErrorHandler.showErrorSnackBar(context, 'Upload failed: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Delete current image
  Future<void> _deleteImage() async {
    if (_currentImageUrl == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Image'),
        content: const Text('Are you sure you want to delete this image?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _performDelete();
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _performDelete() async {
    setState(() => _isLoading = true);

    try {
      final response = await ApiClient.instance.delete(
        '/api/uploads/${widget.uploadType}/${widget.entityId}',
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        setState(() {
          _currentImageUrl = null;
          _selectedImage = null;
        });
        if (!mounted) return;
        ErrorHandler.showSuccessSnackBar(context, 'Image deleted successfully');
        widget.onDelete?.call();
      } else {
        throw Exception('Delete failed: ${response.statusCode}');
      }
    } catch (e) {
      if (!mounted) return;
      ErrorHandler.showErrorSnackBar(context, 'Delete failed: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(widget.title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 16),

        // Image display area
        Container(
          width: 200,
          height: 200,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(12),
            color: Colors.grey.shade100,
          ),
          child: _buildImageDisplay(),
        ),
        const SizedBox(height: 16),

        // Action buttons
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              onPressed: _isLoading
                  ? null
                  : () {
                      // Note: Requires image_picker package
                      // This is a placeholder for the actual implementation
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Image picker requires image_picker package',
                          ),
                        ),
                      );
                    },
              icon: const Icon(Icons.image),
              label: const Text('Upload Image'),
            ),
            const SizedBox(width: 12),
            if (_currentImageUrl != null)
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _deleteImage,
                icon: const Icon(Icons.delete),
                label: const Text('Delete'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              ),
          ],
        ),
      ],
    );
  }

  /// Build image display widget
  Widget _buildImageDisplay() {
    if (_isLoading && _currentImageUrl == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 12),
            Text('Uploading...'),
          ],
        ),
      );
    }

    if (_currentImageUrl != null) {
      return Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              _currentImageUrl!,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return const Center(child: Icon(Icons.error_outline));
              },
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Center(
                  child: CircularProgressIndicator(
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                        : null,
                  ),
                );
              },
            ),
          ),
        ],
      );
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.add_photo_alternate,
            size: 48,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 8),
          Text(
            'No image selected',
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}

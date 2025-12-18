import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../core/offline/offline_manager.dart';

class ImageUploadWidget extends StatefulWidget {
  final String label;
  final String? currentImageUrl;
  // ✅ ADDED: Callback to handle the actual API upload
  final Future<String?> Function(File)? onUpload; 
  final Function(String?)? onImageUploaded;
  final Function()? onImageRemoved;
  final double size;
  final bool showRemoveButton;

  const ImageUploadWidget({
    super.key,
    required this.label,
    this.currentImageUrl,
    this.onUpload,
    this.onImageUploaded,
    this.onImageRemoved,
    this.size = 120,
    this.showRemoveButton = true,
  });

  @override
  State<ImageUploadWidget> createState() => _ImageUploadWidgetState();
}

class _ImageUploadWidgetState extends State<ImageUploadWidget> {
  bool _isUploading = false;
  String? _uploadedImageUrl;

  @override
  void initState() {
    super.initState();
    _uploadedImageUrl = widget.currentImageUrl;
  }

  @override
  void didUpdateWidget(ImageUploadWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentImageUrl != oldWidget.currentImageUrl) {
      _uploadedImageUrl = widget.currentImageUrl;
    }
  }

  Future<void> _pickAndUploadImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        await _uploadImage(File(pickedFile.path));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick image: $e')),
        );
      }
    }
  }

  Future<void> _uploadImage(File imageFile) async {
    if (!mounted) return;

    final offlineManager = Provider.of<OfflineManager>(context, listen: false);

    // Check if offline
    if (!offlineManager.isOnline) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot upload images while offline')),
      );
      return;
    }

    setState(() => _isUploading = true);

    try {
      // ✅ FIXED: Use the onUpload callback if provided
      String? uploadedUrl;
      
      if (widget.onUpload != null) {
        uploadedUrl = await widget.onUpload!(imageFile);
      } else {
        // Fallback simulation
        await Future.delayed(const Duration(seconds: 2));
        uploadedUrl = 'uploaded_image_${DateTime.now().millisecondsSinceEpoch}.jpg';
      }

      if (uploadedUrl != null) {
        setState(() => _uploadedImageUrl = uploadedUrl);
        widget.onImageUploaded?.call(uploadedUrl);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('✅ Image uploaded successfully')),
          );
        }
      } else {
        throw Exception('Upload returned null');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload image: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  void _removeImage() {
    setState(() => _uploadedImageUrl = null);
    widget.onImageRemoved?.call();
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.pop(context);
                _pickAndUploadImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickAndUploadImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.cancel, color: Colors.red),
              title: const Text('Cancel', style: TextStyle(color: Colors.red)),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _isUploading ? null : _showImageSourceDialog,
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.colorScheme.outline.withValues(alpha: 0.3),
                width: 2,
              ),
            ),
            child: _isUploading
                ? const Center(
                    child: CircularProgressIndicator(),
                  )
                : _uploadedImageUrl != null
                    ? Stack(
                        fit: StackFit.expand,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: _uploadedImageUrl!.startsWith('http')
                                ? Image.network(
                                    _uploadedImageUrl!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return _buildPlaceholder();
                                    },
                                  )
                                : Container(
                                    color: theme.colorScheme.primaryContainer,
                                    child: Icon(
                                      Icons.image,
                                      size: widget.size * 0.4,
                                      color: theme.colorScheme.primary,
                                    ),
                                  ),
                          ),
                          if (widget.showRemoveButton)
                            Positioned(
                              top: 4,
                              right: 4,
                              child: GestureDetector(
                                onTap: _removeImage,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.6),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.close,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      )
                    : _buildPlaceholder(),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Tap to upload ${widget.label.toLowerCase()}',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }

  Widget _buildPlaceholder() {
    final theme = Theme.of(context);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.add_photo_alternate_outlined,
          size: widget.size * 0.3,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
        ),
        const SizedBox(height: 4),
        Text(
          'Upload',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
          ),
        ),
      ],
    );
  }
}
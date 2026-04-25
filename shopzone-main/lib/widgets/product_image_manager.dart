import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/image_upload_service.dart';
import '../utils/constants.dart';

class ProductImageManager extends StatefulWidget {
  final String productId;
  final List<Map<String, dynamic>> existingImages;
  final String serverBaseUrl;

  const ProductImageManager({
    super.key,
    required this.productId,
    this.existingImages = const [],
    this.serverBaseUrl = 'http://192.168.18.10:3000',
  });

  @override
  State<ProductImageManager> createState() => _ProductImageManagerState();
}

class _ProductImageManagerState extends State<ProductImageManager> {
  final _picker = ImagePicker();
  List<Map<String, dynamic>> _images = [];
  bool _uploading = false;

  @override
  void initState() {
    super.initState();
    _images = List.from(widget.existingImages);
  }

  Future<void> _pickAndUpload({bool fromCamera = false}) async {
    try {
      if (fromCamera) {
        final photo = await _picker.pickImage(source: ImageSource.camera, imageQuality: 80);
        if (photo == null) return;
        await _upload([File(photo.path)]);
      } else {
        final photos = await _picker.pickMultiImage(imageQuality: 80);
        if (photos.isEmpty) return;
        await _upload(photos.map((p) => File(p.path)).toList());
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: ${e.toString().replaceFirst("Exception: ", "")}')),
        );
      }
    }
  }

  Future<void> _upload(List<File> files) async {
    setState(() => _uploading = true);
    try {
      if (files.length == 1) {
        final result = await ImageUploadService.uploadProductImage(
          widget.productId, files.first,
          isPrimary: _images.isEmpty,
        );
        setState(() => _images.add(result));
      } else {
        final results = await ImageUploadService.uploadProductImages(widget.productId, files);
        setState(() => _images.addAll(results.cast<Map<String, dynamic>>()));
      }
    } catch (e) {
      rethrow;
    } finally {
      setState(() => _uploading = false);
    }
  }

  String _fullUrl(String imageUrl) {
    if (imageUrl.startsWith('http')) return imageUrl;
    return '${widget.serverBaseUrl}$imageUrl';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Product Images',
                style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary(context),
                )),
            const Spacer(),
            Text('${_images.length} images',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary(context))),
          ],
        ),
        const SizedBox(height: 12),

        SizedBox(
          height: 120,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              GestureDetector(
                onTap: () => _showPickerOptions(context),
                child: Container(
                  width: 100,
                  height: 120,
                  margin: const EdgeInsets.only(right: 10),
                  decoration: BoxDecoration(
                    color: AppColors.surface(context),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border(context), width: 2, style: BorderStyle.solid),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_photo_alternate_outlined,
                          size: 32, color: AppColors.textSecondary(context)),
                      const SizedBox(height: 4),
                      Text('Add', style: TextStyle(fontSize: 12, color: AppColors.textSecondary(context))),
                    ],
                  ),
                ),
              ),

              if (_uploading)
                Container(
                  width: 100,
                  height: 120,
                  margin: const EdgeInsets.only(right: 10),
                  decoration: BoxDecoration(
                    color: AppColors.surface(context),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                ),

              ..._images.asMap().entries.map((entry) {
                final i = entry.key;
                final img = entry.value;
                final isPrimary = img['is_primary'] == true;

                return Container(
                  width: 100,
                  height: 120,
                  margin: const EdgeInsets.only(right: 10),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: CachedNetworkImage(
                          imageUrl: _fullUrl(img['image_url'] ?? img['full_url'] ?? ''),
                          width: 100,
                          height: 120,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Container(
                            color: AppColors.surface(context),
                            child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                          ),
                          errorWidget: (_, __, ___) => Container(
                            color: AppColors.surface(context),
                            child: const Icon(Icons.broken_image, color: Colors.grey),
                          ),
                        ),
                      ),
                      if (isPrimary)
                        Positioned(
                          top: 4,
                          left: 4,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.accent,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text('Main',
                                style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700)),
                          ),
                        ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () {
                            setState(() => _images.removeAt(i));
                          },
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close, size: 14, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  void _showPickerOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library_outlined, color: AppColors.accent),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickAndUpload();
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined, color: AppColors.accent),
                title: const Text('Take a Photo'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickAndUpload(fromCamera: true);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
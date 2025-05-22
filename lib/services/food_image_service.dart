import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';

class FoodImageService {
  static const String _bucketName = 'food_images';
  final _supabase = Supabase.instance.client;

  Future<String> uploadFoodImage(
    String restaurantId,
    String menuId,
    File image,
  ) async {
    try {
      final String filePath =
          '$restaurantId/$menuId/${DateTime.now().millisecondsSinceEpoch}';

      await _supabase.storage.from(_bucketName).upload(
            filePath,
            image,
            fileOptions: FileOptions(cacheControl: '3600', upsert: true),
          );

      return filePath; // Return full path for signed URL generation
    } catch (e) {
      if (kDebugMode) print('Error uploading food image: $e');
      rethrow;
    }
  }

  Future<String> createSignedUrl(String filePath, int expiresInSeconds) async {
    try {
      final signedUrl = await _supabase.storage
          .from(_bucketName)
          .createSignedUrl(filePath, expiresInSeconds);

      return signedUrl;
    } catch (e) {
      if (kDebugMode) print('Error creating signed URL: $e');
      rethrow;
    }
  }

  String getPublicUrl(String restaurantId, String menuId) {
    return _supabase.storage
        .from(_bucketName)
        .getPublicUrl('$restaurantId/$menuId');
  }

  Future<void> removeFoodImage(String restaurantId, String menuId) async {
    try {
      await _supabase.storage
          .from(_bucketName)
          .remove(['$restaurantId/$menuId']);
    } catch (e) {
      if (kDebugMode) print('Error removing food image: $e');
    }
  }

  Future<File?> pickImage() async {
    try {
      final pickedFile = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1080,
        maxHeight: 1080,
        imageQuality: 70,
      );
      return pickedFile != null ? File(pickedFile.path) : null;
    } catch (e) {
      if (kDebugMode) print('Error picking image: $e');
      return null;
    }
  }
}

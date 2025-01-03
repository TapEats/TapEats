import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';

class ProfileImageService {
  final _supabase = Supabase.instance.client;

  Future<String?> getProfileImageUrl(String userId) async {
    try {
      final String path = 'profile_photo/$userId/profile_image';
      
      try {
        // First check if the file exists
        final list = await _supabase.storage
            .from('users')
            .list(path: 'profile_photo/$userId');

        // If no files found, return null
        if (list.isEmpty) return null;

        // Get the signed URL which is valid for access
        final signedUrl = await _supabase.storage
            .from('users')
            .createSignedUrl(path, 60 * 60); // Valid for 1 hour

        return signedUrl;
      } catch (e) {
        if (kDebugMode) {
          print('Error checking image existence: $e');
        }
        return null;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error getting profile image: $e');
      }
      return null;
    }
  }

  Future<File?> pickImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1080,
        maxHeight: 1080,
        imageQuality: 70,
      );

      if (pickedFile == null) return null;
      return File(pickedFile.path);
    } catch (e) {
      if (kDebugMode) {
        print('Error picking image: $e');
      }
      rethrow;
    }
  }

  Future<void> uploadProfileImage(String userId, File imageFile) async {
    try {
      final String path = 'profile_photo/$userId/profile_image';
      
      // Delete existing image if it exists
      try {
        await _supabase.storage.from('users').remove([path]);
      } catch (e) {
        // Ignore if file doesn't exist
      }

      // Upload new image
      await _supabase.storage.from('users').upload(
        path,
        imageFile,
        fileOptions: const FileOptions(
          cacheControl: '3600',
          upsert: true
        ),
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error uploading profile image: $e');
      }
      rethrow;
    }
  }

  Future<void> removeProfileImage(String userId) async {
    try {
      final String path = 'profile_photo/$userId/profile_image';
      
      try {
        await _supabase.storage.from('users').remove([path]);
      } catch (e) {
        // Ignore if file doesn't exist
        if (kDebugMode) {
          print('Remove profile image (might not exist): $e');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error in removeProfileImage: $e');
      }
      rethrow;
    }
  }
}
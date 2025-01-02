import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
import 'package:path/path.dart' as path;

class ProfileImageService {
  final _supabase = Supabase.instance.client;

Future<String?> pickAndUploadProfileImage() async {
  try {
    final PermissionStatus photoPermission;
    if (Platform.isAndroid && int.parse(defaultTargetPlatform.toString().split('.')[1]) >= 33) {
      photoPermission = await Permission.photos.request();
    } else {
      photoPermission = await Permission.storage.request();
    }

    if (photoPermission.isDenied) {
      throw Exception('Storage permission is required');
    }

    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1080,
      maxHeight: 1080,
      imageQuality: 70,
    );

    if (pickedFile == null) {
      if (kDebugMode) {
        print('No image selected');
      }
      return null;
    }

    // Print file details for debugging
    final File imageFile = File(pickedFile.path);
    if (kDebugMode) {
      print('File size: ${imageFile.lengthSync()} bytes');
      print('File path: ${imageFile.path}');
    }

    final croppedFile = await ImageCropper().cropImage(
      sourcePath: pickedFile.path,
      aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
      compressQuality: 70,
      maxWidth: 1080,
      maxHeight: 1080,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Crop Profile Picture',
          toolbarColor: const Color(0xFF1A1A1A),
          toolbarWidgetColor: const Color(0xFFEEEFED),
          backgroundColor: const Color(0xFF1A1A1A),
          activeControlsWidgetColor: const Color(0xFFD0F0C0),
          initAspectRatio: CropAspectRatioPreset.square,
          lockAspectRatio: true,
        ),
        IOSUiSettings(
          title: 'Crop Profile Picture',
          aspectRatioPickerButtonHidden: true,
          doneButtonTitle: 'Done',
          cancelButtonTitle: 'Cancel',
        ),
      ],
    );

    if (croppedFile == null) {
      if (kDebugMode) {
        print('Cropping cancelled');
      }
      return null;
    }

    // Get current user ID
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    // Upload image with detailed error logging
    try {
      final uploadResult = await uploadProfileImage(
        userId: userId,
        imageFile: File(croppedFile.path),
      );
      
      if (kDebugMode) {
        print('Upload successful. URL: $uploadResult');
      }
      
      return uploadResult;
    } catch (e) {
      if (kDebugMode) {
        print('Upload failed with error: $e');
      }
      rethrow;
    }

  } catch (e) {
    if (kDebugMode) {
      print('Error in pickAndUploadProfileImage: $e');
    }
    rethrow;
  }
}

Future<String?> uploadProfileImage({
  required String userId,
  required File imageFile,
}) async {
  try {
    if (!imageFile.existsSync()) {
      throw Exception('Image file does not exist');
    }

    if (imageFile.lengthSync() > 5 * 1024 * 1024) {
      throw Exception('Image size exceeds 5MB');
    }

    final fileExtension = path.extension(imageFile.path);
    final uploadPath = 'profile_photo/$userId/profile$fileExtension';

    if (kDebugMode) {
      print('Attempting to upload to path: $uploadPath');
    }

    // Try to create folder first
    try {
      await _supabase.storage.from('users').uploadBinary(
        '$userId/test.txt',
        Uint8List(0),
      );
    } catch (e) {
      if (kDebugMode) {
        print('Folder creation error (can be ignored if folder exists): $e');
      }
    }

    // Upload the actual file
    await _supabase.storage
        .from('users')
        .upload(
          uploadPath,
          imageFile,
          fileOptions: const FileOptions(
            cacheControl: '3600',
            upsert: true,
          ),
        );

    if (kDebugMode) {
      print('File uploaded successfully');
    }

    final publicUrl = _supabase.storage
        .from('users')
        .getPublicUrl(uploadPath);

    if (kDebugMode) {
      print('Generated public URL: $publicUrl');
    }

    // Update user profile
    await _supabase
        .from('users')
        .update({'profile_image_url': publicUrl})
        .eq('user_id', userId);

    if (kDebugMode) {
      print('Profile updated with new image URL');
    }

    return publicUrl;
  } catch (e, stackTrace) {
    if (kDebugMode) {
      print('Error uploading profile image: $e');
      print('Stack trace: $stackTrace');
    }
    rethrow;
  }
}
  // Method to fetch current profile image URL
  Future<String?> fetchCurrentProfileImageUrl() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return null;

      final response = await _supabase
          .from('users')
          .select('profile_image_url')
          .eq('user_id', userId)
          .single();

      return response['profile_image_url'];
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching profile image URL: $e');
      }
      return null;
    }
  }
}
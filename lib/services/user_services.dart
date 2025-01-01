import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tapeats/data/models/user.dart';

class UserService {
  final SupabaseClient _supabase;
  
  UserService._() : _supabase = Supabase.instance.client;
  
  static final UserService _instance = UserService._();
  static UserService get instance => _instance;

  // Cache mechanism for user data
  UserProfile? _cachedUser;
  DateTime? _lastFetch;
  static const _cacheValidDuration = Duration(minutes: 5);

  bool _isCacheValid() {
    return _cachedUser != null && 
           _lastFetch != null && 
           DateTime.now().difference(_lastFetch!) < _cacheValidDuration;
  }

  // Authentication check
  bool _isAuthenticated() {
    final user = _supabase.auth.currentUser;
    return user != null;
  }

  // Validation methods
  void _validatePhoneNumber(String? phoneNumber) {
    if (phoneNumber == null || phoneNumber.isEmpty) return;
    
    // Remove country code if present
    String cleanedNumber = phoneNumber;
    if (cleanedNumber.startsWith('+91')) {
      cleanedNumber = cleanedNumber.substring(3);
    }
    
    // Remove any non-digit characters
    cleanedNumber = cleanedNumber.replaceAll(RegExp(r'\D'), '');
    
    // Check if the cleaned number is exactly 10 digits (for Indian phone numbers)
    if (cleanedNumber.length != 10) {
      throw ValidationException('phone number must be 10 digits');
    }
  }

  void _validateEmail(String? email) {
    if (email == null) return;
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      throw ValidationException('email');
    }
  }

  void _validateUsername(String? username) {
    if (username == null || username.trim().isEmpty) {
      throw ValidationException('username');
    }
    
    // Optional: Add more username validation rules
    if (username.length < 2) {
      throw ValidationException('username must be at least 2 characters');
    }
  }

  void _validateUserData(UserProfile userProfile) {
    _validateUsername(userProfile.username);
    _validatePhoneNumber(userProfile.phoneNumber);
    _validateEmail(userProfile.email);
    
    // Optional: Add date of birth validation if needed
    if (userProfile.dateOfBirth != null) {
      if (userProfile.dateOfBirth!.isAfter(DateTime.now())) {
        throw ValidationException('date of birth cannot be in the future');
      }
    }
  }

  // Main service methods
  Future<UserProfile?> getCurrentUser({bool forceRefresh = false}) async {
    if (!_isAuthenticated()) {
      throw AuthenticationException();
    }

    try {
      // Return cached data if valid
      if (!forceRefresh && _isCacheValid()) {
        return _cachedUser;
      }

      final userId = _supabase.auth.currentUser!.id;
      
      final response = await _supabase
          .from('users')
          .select()
          .eq('user_id', userId)
          .single();

      if (response.isEmpty) return null;

      _cachedUser = UserProfile.fromJson(response);
      _lastFetch = DateTime.now();
      
      return _cachedUser;
    } catch (e) {
      throw UserServiceException('Failed to fetch user data: ${e.toString()}');
    }
  }

  Future<void> updateUserProfile(UserProfile updatedProfile) async {
    if (!_isAuthenticated()) {
      throw AuthenticationException();
    }

    try {
      // Validate user data
      _validateUserData(updatedProfile);

      final userId = _supabase.auth.currentUser!.id;
      
      // Prepare the data for update
      final updateData = updatedProfile.toJson();
      
      // Ensure phone number is stored with country code
      if (updateData['phone_number'] != null) {
        // If phone number doesn't start with +91, add it
        if (!updateData['phone_number'].startsWith('+91')) {
          updateData['phone_number'] = '+91${updateData['phone_number']}';
        }
      }
      
      // Update database
      await _supabase
          .from('users')
          .update(updateData)
          .eq('user_id', userId);

      // Clear cache to force refresh on next fetch
      _cachedUser = null;
      _lastFetch = null;
      
    } catch (e) {
      if (e is ValidationException) {
        rethrow;
      }
      throw UserServiceException('Failed to update user profile: ${e.toString()}');
    }
  }

  // Additional features (can be implemented later)
  Future<void> requestPhoneVerification(String phoneNumber) async {
    // Implement phone verification logic
  }

  Future<void> requestEmailVerification(String email) async {
    // Implement email verification logic
  }

  Future<String?> uploadProfilePicture(String filePath) async {
    // Implement profile picture upload logic
    return null;
  }
}

// Custom exceptions
class UserServiceException implements Exception {
  final String message;
  UserServiceException(this.message);

  @override
  String toString() => message;
}

class AuthenticationException extends UserServiceException {
  AuthenticationException() : super('User not authenticated');
}

class ValidationException extends UserServiceException {
  ValidationException(String message) : super('Invalid $message');
}
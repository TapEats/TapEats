// lib/models/user_profile.dart

class UserProfile {
  final String? userId;
  final String? username;
  final String? role;
  final String? phoneNumber;
  final String? email;
  final DateTime? dateOfBirth;
  final String? gender;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  UserProfile({
    this.userId,
    this.username,
    this.role,
    this.phoneNumber,
    this.email,
    this.dateOfBirth,
    this.gender,
    this.createdAt,
    this.updatedAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      userId: json['user_id'],
      username: json['username'],
      role: json['role'],
      phoneNumber: json['phone_number']?.toString(),
      email: json['email'],
      dateOfBirth: json['date_of_birth'] != null 
          ? DateTime.parse(json['date_of_birth'])
          : null,
      gender: json['gender'],
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'role': role,
      'phone_number': phoneNumber,
      'email': email,
      'date_of_birth': dateOfBirth?.toIso8601String(),
      'gender': gender,
      'updated_at': DateTime.now().toIso8601String(),
    };
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
  ValidationException(String field) : super('Invalid $field provided');
}
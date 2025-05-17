class UserProfile {
  final String? userId;
  final String? username;
  final String? email;
  final String? phoneNumber;
  final DateTime? dateOfBirth;
  final String? gender;
  final String? role;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? profileImageUrl;

  UserProfile({
    this.userId,
    this.username,
    this.email,
    this.phoneNumber,
    this.dateOfBirth,
    this.gender,
    this.role,
    this.createdAt,
    this.updatedAt,
    this.profileImageUrl,
  });

  // Add copyWith method:
  UserProfile copyWith({
    String? userId,
    String? username,
    String? email,
    String? phoneNumber,
    DateTime? dateOfBirth,
    String? gender,
    String? role,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? profileImageUrl,
  }) {
    return UserProfile(
      userId: userId ?? this.userId,
      username: username ?? this.username,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
    );
  }

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
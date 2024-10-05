import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class OtpService {
  final SupabaseClient _supabaseClient;

  OtpService(this._supabaseClient);

  // Method to send OTP
  Future<void> sendOtp(String phoneNumber) async {
    try {
      await _supabaseClient.auth.signInWithOtp(
        phone: phoneNumber,
      );
      if (kDebugMode) {
        print('OTP sent to $phoneNumber');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error sending OTP: $e');
      }
      rethrow; // Forward the exception to be handled where the method is called
    }
  }

  // Method to verify OTP
  Future<void> verifyOtp(String phoneNumber, String otpCode) async {
    try {
      await _supabaseClient.auth.verifyOTP(
        type: OtpType.sms,
        token: otpCode,
        phone: phoneNumber,
      );
      if (kDebugMode) {
        print('OTP verified successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error verifying OTP: $e');
      }
      rethrow; // Forward the exception to be handled where the method is called
    }
  }
}

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:tapeats/presentation/screens/otp_verification_page.dart';
import 'package:tapeats/services/otp_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final OtpService _otpService = OtpService(Supabase.instance.client);

  // Function to format the phone number with country code
  String _formatPhoneNumber(String phoneNumber) {
    if (!phoneNumber.startsWith('91')) {
      return '91$phoneNumber';
    }
    return phoneNumber;
  }

Future<void> _handleLogin() async {
  String phoneNumber = _phoneController.text.trim();
  String username = _usernameController.text.trim();

  if (phoneNumber.isEmpty || username.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Please enter both phone number and username')),
    );
    return;
  }

  String formattedPhoneNumber = _formatPhoneNumber(phoneNumber);

  try {
    await _otpService.sendOtp(formattedPhoneNumber);
    if (!mounted) return;
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OtpVerificationPage(
          phoneNumber: formattedPhoneNumber,
          username: username,
        ),
      ),
    );
  } catch (e) {
    if (kDebugMode) {
      print('Error during login: $e');
    }
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Failed to send OTP: ${e.toString()}')),
    );
  }
}

  @override
  void dispose() {
    _phoneController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF151611),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 100),
              const Text(
                'TapEats',
                textAlign: TextAlign.left,
                style: TextStyle(
                  color: Color(0xFFEEEFEF),
                  fontSize: 32,
                  fontWeight: FontWeight.normal,
                  fontFamily: 'Helvetica Neue',
                ),
              ),
              const SizedBox(height: 50),
              const Text(
                'Hi! Welcome To TapEats',
                textAlign: TextAlign.left,
                style: TextStyle(
                  color: Color(0xFFEEEFEF),
                  fontSize: 24,
                  fontWeight: FontWeight.w300,
                  fontFamily: 'Helvetica Neue',
                ),
              ),
              const SizedBox(height: 25),
              const Text(
                'Enter your username and phone number',
                textAlign: TextAlign.left,
                style: TextStyle(
                  color: Color(0xFFEEEFEF),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Helvetica Neue',
                ),
              ),
              const SizedBox(height: 10),

              // Username Input
              Container(
                margin: const EdgeInsets.only(bottom: 15),
                decoration: BoxDecoration(
                  color: const Color(0xFF222222),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: TextField(
                  controller: _usernameController,
                  decoration: const InputDecoration(
                    hintText: 'Username',
                    hintStyle: TextStyle(
                      color: Color(0xFFEEEFEF),
                      fontFamily: 'Helvetica Neue',
                      fontWeight: FontWeight.w200,
                      fontSize: 14,
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.all(15),
                  ),
                  style: const TextStyle(
                    color: Color(0xFFEEEFEF),
                  ),
                ),
              ),

              // Phone Number Input with Country Flag
              Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: const Color(0xFF222222),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(
                      child: Image(
                        image: AssetImage('assets/images/in.png'),
                        width: 30,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Container(
                      height: 50,
                      decoration: BoxDecoration(
                        color: const Color(0xFF222222),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: TextField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          prefixIcon: Icon(
                            Icons.call,
                            color: Color(0xFFD0F0C0),
                          ),
                          hintText: 'Phone Number',
                          hintStyle: TextStyle(
                            color: Color(0xFFEEEFEF),
                            fontFamily: 'Helvetica Neue',
                            fontWeight: FontWeight.w200,
                            fontSize: 14,
                          ),
                          border: InputBorder.none,
                        ),
                        style: const TextStyle(
                          color: Color(0xFFEEEFEF),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: _handleLogin,  // Use the extracted method
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD0F0C0),
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Next',
                  style: TextStyle(
                    color: Color(0xFF151611),
                    fontWeight: FontWeight.normal,
                    fontSize: 20,
                    fontFamily: 'Helvetica Neue',
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:tapeats/presentation/screens/user_side/home_page.dart';
import 'dart:async'; // For the Timer functionality
import 'package:tapeats/services/otp_service.dart'; // Import the OTP service
import 'package:supabase_flutter/supabase_flutter.dart';

class OtpVerificationPage extends StatefulWidget {
  final String phoneNumber;
  final int selectedIndex = 0;
  const OtpVerificationPage({super.key, required this.phoneNumber});

  @override
  State<OtpVerificationPage> createState() => _OtpVerificationPageState();
}

class _OtpVerificationPageState extends State<OtpVerificationPage> {
  final TextEditingController otpController1 = TextEditingController();
  final TextEditingController otpController2 = TextEditingController();
  final TextEditingController otpController3 = TextEditingController();
  final TextEditingController otpController4 = TextEditingController();
  final OtpService _otpService = OtpService(Supabase.instance.client);  // Instance of the service

  late FocusNode focusNode1;
  late FocusNode focusNode2;
  late FocusNode focusNode3;
  late FocusNode focusNode4;

  bool _isResendAllowed = false; // Controls the ability to resend the OTP
  int _resendCooldown = 30; // Cooldown in seconds
  Timer? _timer; // Timer for countdown

  @override
  void initState() {
    super.initState();

    // Initialize FocusNodes
    focusNode1 = FocusNode();
    focusNode2 = FocusNode();
    focusNode3 = FocusNode();
    focusNode4 = FocusNode();

    // Start the cooldown timer immediately
    startResendCooldown();
  }

  @override
  void dispose() {
    // Dispose FocusNodes and controllers
    otpController1.dispose();
    otpController2.dispose();
    otpController3.dispose();
    otpController4.dispose();
    focusNode1.dispose();
    focusNode2.dispose();
    focusNode3.dispose();
    focusNode4.dispose();
    _timer?.cancel(); // Dispose of the timer
    super.dispose();
  }

  // Logic to handle OTP verification
Future<void> verifyOtp() async {
  String otp = '${otpController1.text}${otpController2.text}${otpController3.text}${otpController4.text}';
  try {
    await _otpService.verifyOtp(widget.phoneNumber, otp);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('OTP verified successfully')));

    // Navigate to the HomePage after successful verification
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => HomePage(selectedIndex: widget.selectedIndex,)), // Replace with your HomePage widget
    );
  } catch (e) {
    print('Error verifying OTP: $e');
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to verify OTP')));
  }
}


  // Logic for handling resend OTP
  Future<void> resendOtp() async {
    if (!_isResendAllowed) return;

    try {
      await _otpService.sendOtp(widget.phoneNumber);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('OTP has been resent')));
      
      // Start the cooldown after sending OTP
      startResendCooldown();
    } catch (e) {
      print('Error resending OTP: $e');
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to resend OTP')));
    }
  }

  // Start the cooldown for resending OTP
  void startResendCooldown() {
    setState(() {
      _isResendAllowed = false;
      _resendCooldown = 30; // Reset cooldown to 30 seconds
    });

    // Cancel any existing timer before starting a new one
    _timer?.cancel();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_resendCooldown > 0) {
          _resendCooldown--; // Decrease the cooldown time
        } else {
          _isResendAllowed = true;  // Allow resending OTP after the cooldown
          timer.cancel();  // Stop the timer
        }
      });
    });
  }

  // Build the OTP box
  Widget _buildOtpBox(TextEditingController controller, FocusNode focusNode) {
    return Container(
      width: 60,
      height: 55,
      decoration: BoxDecoration(
        color: focusNode.hasFocus
            ? const Color(0xFF151611)  // Focused box background
            : controller.text.isEmpty
                ? const Color(0xFF222222)  // Empty box background
                : const Color(0xFFD0F0C0), // Filled box background
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: focusNode.hasFocus ? const Color(0xFFD0F0C0) : Colors.transparent,  // Green border for focused box
          width: 2,
        ),
        boxShadow: controller.text.isEmpty
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.25), // Inner shadow for empty boxes
                  offset: const Offset(0, 0),
                  blurRadius: 10,
                  spreadRadius: 0,
                ),
              ]
            : null,  // No shadow for filled boxes
      ),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        cursorColor: const Color(0xFFD0F0C0),
        style: TextStyle(
          fontSize: 24,
          color: focusNode.hasFocus
              ? const Color(0xFFD0F0C0) // Cursor color in focused box
              : const Color(0xFF151611), // Filled box text color
          fontWeight: FontWeight.bold,
        ),
        maxLength: 1,
        decoration: InputDecoration(
          border: InputBorder.none,
          counterText: "",
          hintText: controller.text.isEmpty ? '_' : '',
          hintStyle: const TextStyle(
            color: Color(0xFF151611),
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        onChanged: (value) {
          if (value.isNotEmpty) {
            FocusScope.of(context).nextFocus();  // Move to the next OTP box on input
          }
          setState(() {});  // Refresh to update background color
        },
        onTap: () {
          setState(() {});  // Refresh to apply focus border and background color
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF151611),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 100),
            const Text(
              'TapEats',
              style: TextStyle(
                color: Color(0xFFEEEFEF),
                fontSize: 32,
                fontWeight: FontWeight.normal,
                fontFamily: 'Helvetica Neue',
              ),
            ),
            const SizedBox(height: 33),
            const Text(
              'Verify Phone Number',
              style: TextStyle(
                color: Color(0xFFEEEFEF),
                fontSize: 24,
                fontWeight: FontWeight.w300,
                fontFamily: 'Helvetica Neue',
              ),
            ),
            const SizedBox(height: 33),
            Text(
              'Code has been sent to +${widget.phoneNumber}',
              style: const TextStyle(
                color: Color(0xFFEEEFEF),
                fontSize: 12,
                fontWeight: FontWeight.bold,
                fontFamily: 'Helvetica Neue',
              ),
            ),
            const SizedBox(height: 30),
            // OTP Input Fields
            Row(
              mainAxisAlignment: MainAxisAlignment.start,  // Align to left
              children: [
                _buildOtpBox(otpController1, focusNode1),
                const SizedBox(width: 10),  // Space between boxes
                _buildOtpBox(otpController2, focusNode2),
                const SizedBox(width: 10),
                _buildOtpBox(otpController3, focusNode3),
                const SizedBox(width: 10),
                _buildOtpBox(otpController4, focusNode4),
              ],
            ),
            const SizedBox(height: 20),
            const Text(
              'Didn\'t get OTP Code?',
              style: TextStyle(
                color: Color(0xFFEEEFEF),
                fontWeight: FontWeight.bold,
                fontSize: 12,
                fontFamily: 'Helvetica Neue',
              ),
            ),
            GestureDetector(
              onTap: _isResendAllowed ? resendOtp : null,  // Handle resend OTP
              child: Text(
                _isResendAllowed ? 'Resend Code' : 'Resend in $_resendCooldown sec',
                style: TextStyle(
                  color: _isResendAllowed ? const Color(0xFFD0F0C0) : Colors.grey,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  fontFamily: 'Helvetica Neue',
                ),
              ),
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: verifyOtp,  // Call the verify OTP function
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD0F0C0),
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Verify',
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
    );
  }
}

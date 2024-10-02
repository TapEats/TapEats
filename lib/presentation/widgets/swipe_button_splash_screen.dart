import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class SwipeButtonSplashScreen extends StatefulWidget {
  const SwipeButtonSplashScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _SwipeButtonSplashScreenState createState() => _SwipeButtonSplashScreenState();
}

class _SwipeButtonSplashScreenState extends State<SwipeButtonSplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0),
      end: const Offset(1, 0),
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  void _onSwipeRight() {
    // Start the animation
    _controller.forward();
    // TODO: Implement navigation to next screen or action after animation
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragEnd: (details) {
  if (kDebugMode) {
    print(details.primaryVelocity);
  }
  if (details.primaryVelocity! > 0) {
    _onSwipeRight();
  }
},

      child: Stack(
        alignment: Alignment.centerLeft,
        children: [
          Container(
            height: 60,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(50),
              border: Border.all(color: const Color(0xFFD0F0C0), width: 2),  // Light green border color
              color: Colors.transparent,
            ),
            alignment: Alignment.center,
            child: const Text(
              'BON APPÉTIT',
              style: TextStyle(
                fontFamily: 'Helvetica Neue',
                fontWeight: FontWeight.bold,
                color: Color(0xFFEEEFEF),  // Light grey text color
                fontSize: 16,
              ),
            ),
          ),
          SlideTransition(
            position: _slideAnimation,
            child: Container(
              height: 60,
              width: 60,
              decoration: BoxDecoration(
                color: const Color(0xFFD0F0C0),  // Light green background for the sliding button
                borderRadius: BorderRadius.circular(30),
              ),
              alignment: Alignment.center,
              child: const Text(
                '>',
                style: TextStyle(
                  fontFamily: 'Helvetica Neue',
                  color: Color(0xFFEEEFEF),  // Light grey arrow color
                  fontSize: 24,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

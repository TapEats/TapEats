import 'package:flutter/material.dart';
import 'package:tapeats/presentation/widgets/swipe_button_splash_screen.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
    return Scaffold(
      body: Stack(
        children: [
          // Background image (Main food bowl)
          Positioned.fill(
            child: Image.asset(
              'assets/images/splashscreenfoodbowl.png',
              fit: BoxFit.cover,
            ),
          ),
          // Title (TapEats)
          Positioned(
            top: 150, // Adjusted for better positioning
            left: 0,
            right: 0,
            child: Center(
              child: Image.asset(
                'assets/images/TapEats_title.png',
                width: 250, // Adjust as needed
              ),
            ),
          ),
          // Double Frame
          Positioned(
            child: Center(
              child: Image.asset(
                'assets/images/frame.png',
                width: screenWidth * 0.97,
                height: screenHeight * 0.95,
              ),
            ),
          ),
          // Dots on bottom right
          Positioned(
            bottom: 0, // Adjust the bottom position as needed
            right: -20, // Adjust the right position as needed
            child: Image.asset(
              'assets/images/dots.png',
              width: 200, // Adjust the size as needed
              height: 200, // Adjust the height as needed
            ),
          ),
          // Swipe Button Splash Screen (Animated)
          const Positioned(
            left: 75,
            right: 75,
            bottom: 200,
            child: SwipeButtonSplashScreen(), // Your custom swipe button
          ),
        ],
      ),
    );
  }
}

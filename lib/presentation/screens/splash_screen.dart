import 'package:flutter/material.dart';
import 'package:tapeats/presentation/widgets/swipe_button_splash_screen.dart';

class SplashScreen  extends StatelessWidget {
  const SplashScreen ({super.key});

  @override
  Widget build(BuildContext context) {
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
          // Title and assets on top
          Positioned(
            top: 100,
            left: 30,
            right: 30,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Tapeats Title
                Image.asset(
                  'assets/images/TapEats_title.png',
                  width: 200,
                ),
                const SizedBox(height: 20),
                // Double frame
                Image.asset(
                  'assets/images/frame.png',
                  width: 250,  // Adjust the width as needed
  height: 400,
                ),
                const SizedBox(height: 20),
                // Aahar Line (Sanskrit)
                Image.asset(
                  'assets/images/aahar_line.png',
                  width: 200,
                ),
              ],
            ),
          ),
          // Dots on bottom right
          // Dots on bottom right
Positioned(
  bottom: 0,  // Adjust the bottom position as needed
  right: -40,   // Adjust the right position as needed
  child: Image.asset(
    'assets/images/dots.png',
    width: 200, // Adjust the size as needed
    height: 200, // Adjust the height as needed
  ),
),

          // Swipe Button (Animated)
          const Positioned(
            bottom: 100,
            left: 30,
            right: 30,
            child: SwipeButtonSplashScreen(),
          ),
        ],
      ),
    );
  }
}

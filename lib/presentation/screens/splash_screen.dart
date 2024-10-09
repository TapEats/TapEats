import 'package:flutter/material.dart';
import 'package:tapeats/presentation/widgets/swipe_button_splash_screen.dart';

class SplashScreen extends StatefulWidget {
  final int selectedIndex; // Add selectedIndex parameter

  const SplashScreen({super.key, required this.selectedIndex});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/splashscreenfoodbowl.png',
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            top: 150, 
            left: 0,
            right: 0,
            child: Center(
              child: Image.asset(
                'assets/images/TapEats_title.png',
                width: 250, 
              ),
            ),
          ),
          Positioned(
            child: Center(
              child: Image.asset(
                'assets/images/frame.png',
                width: screenWidth * 0.97,
                height: screenHeight * 0.95,
              ),
            ),
          ),
          Positioned(
            bottom: 0, 
            right: -20, 
            child: Image.asset(
              'assets/images/dots.png',
              width: 200, 
              height: 200, 
            ),
          ),
          Positioned(
            left: 75,
            right: 75,
            bottom: 200,
            // Access widget.selectedIndex correctly in StatefulWidget
            child: SwipeButtonSplashScreen(selectedIndex: widget.selectedIndex), 
          ),
        ],
      ),
    );
  }
}

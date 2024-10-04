import 'package:flutter/material.dart';
import 'package:tapeats/presentation/screens/login_page.dart';

class SwipeButtonSplashScreen extends StatefulWidget {
  const SwipeButtonSplashScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _SwipeButtonSplashScreenState createState() =>
      _SwipeButtonSplashScreenState();
}

class _SwipeButtonSplashScreenState extends State<SwipeButtonSplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Color?> _rectBackgroundAnimation;

  bool _isCompleted = false;

  @override
  void initState() {
    super.initState();

    // Initialize the controller for the animation
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    // Background color transition for the entire rectangle container
    _rectBackgroundAnimation = ColorTween(
      begin: Colors.transparent, // Initial transparent background
      end: const Color(
          0xFF151611), // Target color (dark green) as the background changes
    ).animate(_controller);
  }

  // Function to handle swipe right completion
  void _onSwipeRight() {
    if (!_isCompleted) {
      _controller.forward();
      setState(() {
        _isCompleted = true;
      });

      // Navigate to Login Page after swipe completion
      Future.delayed(const Duration(milliseconds: 200), () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) => const LoginPage()), // Navigate to LoginPage
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        double containerWidth =
            constraints.maxWidth; // Get rectangle container width
        double buttonWidth = 60; // The width of the swipe button itself
        double maxDragDistance = containerWidth -
            buttonWidth; // Maximum distance the button can travel

        return GestureDetector(
          onHorizontalDragUpdate: (details) {
            setState(() {
              // Calculate the swipe percentage based on the drag distance relative to the maximum drag distance
              double dragPercentage = details.primaryDelta! / containerWidth;
              if (dragPercentage > 0) {
                _controller.value += dragPercentage;
              }
            });
          },
          onHorizontalDragEnd: (details) {
            // Complete the swipe if dragged more than 50%
            if (_controller.value > 0.5) {
              _onSwipeRight(); // Call swipe completion function
            } else {
              // Otherwise, revert back to the starting position
              _controller.reverse();
              setState(() {
                _isCompleted = false;
              });
            }
          },
          child: Stack(
            alignment: Alignment.centerLeft,
            children: [
              // Rectangle container with dynamic background color and text
              AnimatedBuilder(
                animation: _rectBackgroundAnimation,
                builder: (context, child) {
                  return Container(
                    height: 60,
                    width: containerWidth, // Rectangle adjusts to screen size
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(50),
                      border: Border.all(
                          color: const Color(0xFFD0F0C0),
                          width: 3), // Heavier stroke
                      color: _rectBackgroundAnimation
                          .value, // Dynamic background color
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      'BON APPÉTIT',
                      style: TextStyle(
                        fontFamily: 'Helvetica Neue',
                        fontWeight: FontWeight.w300, // Light font weight
                        color: Color(0xFFEEEFEF), // Light text color
                        fontSize: 12, // Adjusted font size
                        letterSpacing: 2.0, // Space between letters
                      ),
                    ),
                  );
                },
              ),
              // Swipe button with color transition and arrow
              AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  // Transform the button based on the controller value, ensuring it moves up to the maximum distance
                  return Transform.translate(
                    offset: Offset(_controller.value * maxDragDistance,
                        0), // Button moves across the container
                    child: Container(
                      height: 60,
                      width: buttonWidth, // Static button width
                      decoration: BoxDecoration(
                        color: const Color(
                            0xFFD0F0C0), // Static color for the button itself
                        borderRadius: BorderRadius.circular(30),
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        '>',
                        style: TextStyle(
                          fontFamily: 'Helvetica Neue',
                          color: Color(0xFFEEEFEF), // Light arrow color
                          fontSize: 24,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

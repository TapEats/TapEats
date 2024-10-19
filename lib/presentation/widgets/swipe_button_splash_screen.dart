import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tapeats/presentation/screens/user_side/home_page.dart';
import 'package:tapeats/presentation/screens/login_page.dart';

class SwipeButtonSplashScreen extends StatefulWidget {
  final int selectedIndex;
  const SwipeButtonSplashScreen({super.key, required this.selectedIndex});

  @override
  _SwipeButtonSplashScreenState createState() =>
      _SwipeButtonSplashScreenState();
}

class _SwipeButtonSplashScreenState extends State<SwipeButtonSplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Color?> _rectBackgroundAnimation;
  final SupabaseClient supabase = Supabase.instance.client; // Supabase client
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
      end: const Color(0xFF151611), // Target color (dark green)
    ).animate(_controller);
  }

  // Function to handle swipe right completion
  void _onSwipeRight() async {
    if (!_isCompleted) {
      _controller.forward();
      setState(() {
        _isCompleted = true;
      });

      // Check if the user is logged in
      final session = supabase.auth.currentSession;

      Future.delayed(const Duration(milliseconds: 200), () {
        if (session != null) {
          // User is already logged in, navigate to the HomePage
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomePage(selectedIndex: 0,)),
          );
        } else {
          // User is not logged in, navigate to the LoginPage
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => LoginPage()),
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        double containerWidth = constraints.maxWidth; // Get rectangle container width
        double buttonWidth = 60; // The width of the swipe button itself
        double maxDragDistance = containerWidth - buttonWidth; // Max drag distance

        return GestureDetector(
          onHorizontalDragUpdate: (details) {
            setState(() {
              // Calculate the swipe percentage
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
                      border: Border.all(color: const Color(0xFFD0F0C0), width: 4),
                      color: _rectBackgroundAnimation.value, // Dynamic background color
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
                  return Transform.translate(
                    offset: Offset(_controller.value * maxDragDistance, 0),
                    child: Container(
                      height: 60,
                      width: buttonWidth, // Static button width
                      decoration: BoxDecoration(
                        color: const Color(0xFFD0F0C0),
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: const [
                          BoxShadow(blurRadius: 20, color: Color.fromARGB(102, 98, 98, 98)),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        '>',
                        style: TextStyle(
                          fontFamily: 'Helvetica Neue',
                          color: Color(0xFFEEEFEF), // Light arrow color
                          fontSize: 24,
                          shadows: [
                            Shadow(blurRadius: 20, color: Color.fromARGB(255, 98, 98, 98)),
                          ],
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

import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';  // Import Iconsax icons

class HeaderWidget extends StatelessWidget {
  final IconData leftIcon;
  final VoidCallback onLeftButtonPressed;
  final String headingText;
  final IconData? headingIcon; // Made optional
  final VoidCallback? onHeadingButtonPressed; // Made optional
  final IconData rightIcon;
  final VoidCallback onRightButtonPressed;

  const HeaderWidget({
    super.key,
    required this.leftIcon,
    required this.onLeftButtonPressed,
    required this.headingText,
    this.headingIcon,  // Optional heading icon
    this.onHeadingButtonPressed,  // Optional heading button press callback
    required this.rightIcon,
    required this.onRightButtonPressed,
  });

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width; // Get screen width
    double iconSize = screenWidth * 0.06;  // Icon size relative to screen width
    double containerSize = screenWidth * 0.12;  // Container size relative to screen

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),  // Responsive padding
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left Icon (e.g., user icon)
          GestureDetector(
            onTap: onLeftButtonPressed,
            child: Container(
              width: containerSize,
              height: containerSize,
              decoration: BoxDecoration(
                color: const Color(0xFF222222),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                leftIcon,
                color: const Color(0xFFD0F0C0),
                size: iconSize,
              ),
            ),
          ),

          // Middle (Location text and optional heading icon)
          GestureDetector(
            onTap: onHeadingButtonPressed ?? () {},  // Handle if onHeadingButtonPressed is provided
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.03),
              decoration: BoxDecoration(
                color: const Color(0xFF222222),
                borderRadius: BorderRadius.circular(10),
              ),
              height: containerSize,
              child: Row(
                children: [
                  if (headingIcon != null)  // Only show the headingIcon if it's provided
                    Icon(
                      headingIcon,
                      color: const Color(0xFFD0F0C0),
                      size: iconSize,
                    ),
                  const SizedBox(width: 8),
                  Text(
                    headingText,
                    style: const TextStyle(
                      color: Color(0xFFEEEFEF),
                      fontSize: 20,  // Set font size to 20
                      fontWeight: FontWeight.normal,  // Set weight to normal
                      fontFamily: 'Helvetica Neue',  // Set font to Helvetica Neue
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Right Icon (e.g., menu icon)
          GestureDetector(
            onTap: onRightButtonPressed,
            child: Container(
              width: containerSize,
              height: containerSize,
              decoration: BoxDecoration(
                color: const Color(0xFF222222),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                rightIcon,
                color: const Color(0xFFD0F0C0),
                size: iconSize,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

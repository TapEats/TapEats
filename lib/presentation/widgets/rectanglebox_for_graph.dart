import 'package:flutter/material.dart';

class RoundedImageBox extends StatelessWidget {
  final String imageUrl;

  const RoundedImageBox({
    super.key,
    required this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    // Get the screen width and height
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Adjust the size relative to the screen size
    final boxWidth = screenWidth * 0.91; // 80% of screen width
    final boxHeight = screenHeight * 0.2; // 20% of screen height

    return Container(
      width: boxWidth,
      height: boxHeight,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16), // Rounded edges
        color: Colors.grey[800], // Background color
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16), // Rounded edges for the image
        child: Image.asset(
          imageUrl,
          fit: BoxFit.cover, // Make the image cover the entire box
        ),
      ),
    );
  }
}

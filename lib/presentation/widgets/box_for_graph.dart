import 'package:flutter/material.dart';

class RoundedSquareImageBox extends StatelessWidget {
  final String imageUrl;

  const RoundedSquareImageBox({
    super.key,
    required this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    // Get the screen width and height
    final screenWidth = MediaQuery.of(context).size.width;

    // Adjust the size relative to the screen size
    final boxSize = screenWidth * 0.4; // Make the box size 35% of screen width

    return Container(
      width: boxSize,
      height: boxSize, // Making it a square box
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

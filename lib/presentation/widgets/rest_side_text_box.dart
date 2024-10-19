import 'package:flutter/material.dart';

class RoundedTextBox extends StatelessWidget {
  final String text;

  const RoundedTextBox({
    super.key,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 304,
      height: 180,
      padding: const EdgeInsets.all(16), // Padding for text inside the box
      decoration: BoxDecoration(
        color: Colors.grey[800], // Background color
        borderRadius: BorderRadius.circular(16), // Rounded edges
      ),
      child: Center(
        child: Text(
          text,
          textAlign: TextAlign.center, // Center the text inside the box
          style: const TextStyle(
            color: Colors.white, // Text color
            fontSize: 16, // Font size
            fontWeight: FontWeight.bold, // Font weight
          ),
        ),
      ),
    );
  }
}

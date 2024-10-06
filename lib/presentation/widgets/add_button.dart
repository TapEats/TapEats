import 'package:flutter/material.dart';

class AddButton extends StatelessWidget {
  final VoidCallback onPressed;

  const AddButton({required this.onPressed, super.key});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFD0F0C0),  // Highlight button color
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),  // Custom padding
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: const Text(
        'Add',
        style: TextStyle(
          color: Color(0xFF151611),  // Contrasting text color
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

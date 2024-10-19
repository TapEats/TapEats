import 'package:flutter/material.dart';

// AddButton Widget
class AddButton extends StatelessWidget {
  final VoidCallback onPressed;

  const AddButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed, // This triggers the add-to-cart logic
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        decoration: BoxDecoration(
          color: const Color(0xFFD0F0C0),
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Row(
          children: [
            SizedBox(width: 4),
            Text('Add', style: TextStyle(color: Color(0xFF151611))),
            SizedBox(width: 2),
            Icon(Icons.add, color: Color(0xFF151611)),
          ],
        ),
      ),
    );
  }
}

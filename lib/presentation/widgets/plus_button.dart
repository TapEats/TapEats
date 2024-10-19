import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

class PlusButton extends StatelessWidget {
  final VoidCallback onPressed;

  const PlusButton({required this.onPressed, super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFD0F0C0),
          borderRadius: BorderRadius.circular(4),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
        child: const Icon(Iconsax.add, color: Color(0xFF151611), size: 14),
      ),
    );
  }
}

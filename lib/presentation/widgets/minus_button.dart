import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

class MinusButton extends StatelessWidget {
  final VoidCallback onPressed;

  const MinusButton({required this.onPressed, super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      icon: const Icon(Iconsax.minus, color: Color(0xFFD0F0C0)),
    );
  }
}

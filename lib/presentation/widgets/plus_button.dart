import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

class PlusButton extends StatelessWidget {
  final VoidCallback onPressed;

  const PlusButton({required this.onPressed, super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      icon: const Icon(Iconsax.add, color: Color(0xFFD0F0C0)),
    );
  }
}

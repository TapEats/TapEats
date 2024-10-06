import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

class CustomSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final VoidCallback onSearch;

  const CustomSearchBar({
    super.key,
    required this.controller,
    required this.hintText,
    required this.onSearch,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A), // Background color
        borderRadius: BorderRadius.circular(15), // Border radius
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        children: [
          const SizedBox(width: 10),
          const Icon(
            Iconsax.search_normal, // Search icon
            color: Color(0xFFD0F0C0), // Icon color
          ),
          const SizedBox(width: 15), // Space between icon and text field
          Expanded(
            child: TextField(
              controller: controller,
              style: const TextStyle(
                color: Color(0xFFEEEFEF), // Text color
                fontFamily: 'Helvetica Neue', // Use Helvetica Neue
                fontWeight: FontWeight.w400, // Thin font weight
                fontSize: 16, // Same font size as in header section
              ),
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: const TextStyle(
                  color: Color(0xFFEEEFEF), // Hint text color
                  fontFamily: 'Helvetica Neue', // Font for hint text
                  fontWeight: FontWeight.w300, // Thin font weight
                ),
                border: InputBorder.none, // No border for text field
              ),
              onSubmitted: (value) {
                onSearch(); // Call onSearch when search is submitted
              },
            ),
          ),
        ],
      ),
    );
  }
}

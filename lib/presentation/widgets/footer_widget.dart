import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:tapeats/presentation/screens/user_side/favourite_page.dart';
import 'package:tapeats/presentation/screens/user_side/menu_page.dart';

class CustomFooter extends StatefulWidget {
  const CustomFooter({super.key});

  @override
  State<CustomFooter> createState() => _CustomFooterState();
}

class _CustomFooterState extends State<CustomFooter> {
  int _selectedIndex = 0;
  final Duration _duration = const Duration(milliseconds: 300);

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;

      // Navigate to the MenuPage when the Menu icon is pressed (index 1)
      if (index == 1) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const MenuPage()),
        );
      }
      if (index == 2) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const FavouritesPage()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70, // Slightly reduced height
      decoration: const BoxDecoration(
        color: Color(0xFF222222),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(25), // Top rounded corners
          topRight: Radius.circular(25),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Stack(
        alignment: Alignment.center,
        children: [
          _selectedIndex >= 0
              ? _buildInverseTriangle(_selectedIndex)
              : Container(), // Triangle image

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(Iconsax.home, 0),
              _buildNavItem(Iconsax.book_saved, 1),
              _buildNavItem(Iconsax.heart, 2),
              _buildNavItem(Iconsax.profile_circle, 3),
            ],
          ),
        ],
      ),
    );
  }

  // Custom widget to add the triangle behind the selected icon using an image
  Widget _buildInverseTriangle(int index) {
    return AnimatedAlign(
      alignment: Alignment(
          (index * 2 - 3) * 0.29, -5), // Smooth alignment change based on index
      duration: const Duration(milliseconds: 300), // Smooth transition duration
      curve: Curves.easeInOut, // Easing curve for smoothness
      child: AnimatedScale(
        scale: 1.4, // Keep the scaling for larger size
        duration: const Duration(
            milliseconds: 300), // Smooth scale animation duration
        curve: Curves.easeInOut, // Same curve for smooth scaling
        child: ClipRect(
          child: SizedBox(
            width: 60, // Keep the original width and height
            height: 40,
            child: Image.asset(
              'assets/images/invtriangle.png', // Path to the triangle image
              fit: BoxFit.cover, // Ensure it covers the clipped area
            ),
          ),
        ),
      ),
    );
  }

  // Build individual navigation items
  Widget _buildNavItem(IconData iconData, int index) {
    bool isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () => _onItemTapped(index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              // Circle background around the selected icon
              AnimatedAlign(
                alignment: Alignment.center,
                duration: _duration,
                child: AnimatedContainer(
                  duration: _duration,
                  width: isSelected ? 50 : 40, // Circle size for selected icon
                  height: isSelected ? 50 : 40,
                  decoration: const BoxDecoration(
                    color: Color(0xFF222222), // Same color as rectangle
                    shape: BoxShape.circle,
                  ),
                  transform: isSelected
                      ? Matrix4.translationValues(
                          0, -40, 0) // Circle rises with the icon
                      : Matrix4.translationValues(0, 0, 0),
                ),
              ),
              // Icon rising smoothly
              AnimatedContainer(
                duration: _duration,
                transform: isSelected
                    ? Matrix4.translationValues(
                        0, -40, 0) // Icon rise animation
                    : Matrix4.translationValues(0, 0, 0),
                child: Icon(
                  iconData,
                  color: isSelected
                      ? const Color(0xFFD0F0C0) // Selected icon color
                      : const Color(0xFFEEEFEF), // Default icon color
                  size: 28,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

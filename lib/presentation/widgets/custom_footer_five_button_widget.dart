import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:tapeats/presentation/screens/restaurant_side/received_page.dart';
import 'package:tapeats/presentation/screens/restaurant_side/restaurant_home_page.dart';
import 'package:tapeats/presentation/screens/restaurant_side/rest_add_menu.dart';

class CustomFiveFooter extends StatefulWidget {
  final int selectedIndex; // Keep this as selectedIndex

  const CustomFiveFooter({super.key, required this.selectedIndex});

  @override
  State<CustomFiveFooter> createState() => _CustomFiveFooterState();
}

class _CustomFiveFooterState extends State<CustomFiveFooter> {
  final Duration _duration = const Duration(milliseconds: 300);

  late int selectedIndex; // Declare a mutable state variable

  @override
  void initState() {
    super.initState();
    // If no selectedIndex is passed, default to the first page (RestaurantHomePage)
    selectedIndex = widget.selectedIndex;
  }

  void _onItemTapped(int index) {
    if (selectedIndex != index) {
      setState(() {
        selectedIndex = index; // Update the local mutable state
      });

      // Handle navigation logic based on the selected index
      switch (index) {
        case 0:
          // Navigate to RestaurantHomePage
          Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => RestaurantHomePage(
                  selectedIndex:
                      selectedIndex, // Pass the current selected index
                ),
              ));

          break;
        case 1:
          // Navigate to RestaurantHomePage
          Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ReceivedOrdersPage(
                  selectedIndex:
                      selectedIndex, // Pass the current selected index
                ),
              ));
          break;

        case 3:
          // Navigate to AddMenuPage
          Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AddMenuPage(
                  selectedIndex:
                      selectedIndex, // Pass the current selected index
                ),
              ));
          break;
        // Add cases for other buttons if needed
        default:
          break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70,
      decoration: const BoxDecoration(
        color: Color(0xFF222222),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(25),
          topRight: Radius.circular(25),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Stack(
        alignment: Alignment.center,
        children: [
          selectedIndex >= 0
              ? _buildInverseTriangle(selectedIndex)
              : Container(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(Iconsax.home, 0),
              _buildNavItem(Iconsax.book_saved, 1),
              _buildNavItem(Iconsax.heart, 2),
              _buildNavItem(Iconsax.user, 3),
              _buildNavItem(
                  Iconsax.setting, 4), // Add the icon for the new button
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInverseTriangle(int index) {
    return AnimatedAlign(
      alignment: Alignment(
          (index * 2 - 4) * 0.25, -5), // Adjust alignment for 5 buttons
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: AnimatedScale(
        scale: 1.4,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        child: ClipRect(
          child: SizedBox(
            width: 60,
            height: 40,
            child: Image.asset(
              'assets/images/invtriangle.png',
              fit: BoxFit.cover,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData iconData, int index) {
    bool isSelected = selectedIndex == index;
    return GestureDetector(
      onTap: () => _onItemTapped(index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              AnimatedAlign(
                alignment: Alignment.center,
                duration: _duration,
                child: AnimatedContainer(
                  duration: _duration,
                  width: isSelected ? 50 : 40,
                  height: isSelected ? 50 : 40,
                  decoration: const BoxDecoration(
                    color: Color(0xFF222222),
                    shape: BoxShape.circle,
                  ),
                  transform: isSelected
                      ? Matrix4.translationValues(0, -40, 0)
                      : Matrix4.translationValues(0, 0, 0),
                ),
              ),
              AnimatedContainer(
                duration: _duration,
                transform: isSelected
                    ? Matrix4.translationValues(0, -40, 0)
                    : Matrix4.translationValues(0, 0, 0),
                child: Icon(
                  iconData,
                  color: isSelected
                      ? const Color(0xFFD0F0C0)
                      : const Color(0xFFEEEFEF),
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

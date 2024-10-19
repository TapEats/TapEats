import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:tapeats/presentation/screens/user_side/favourite_page.dart';
import 'package:tapeats/presentation/screens/user_side/menu_page.dart';
import 'package:tapeats/presentation/screens/user_side/home_page.dart';
import 'package:tapeats/presentation/screens/user_side/profile_page.dart';

class CustomFooter extends StatefulWidget {
  final int selectedIndex;

  const CustomFooter({super.key, required this.selectedIndex});

  @override
  State<CustomFooter> createState() => _CustomFooterState();
}

class _CustomFooterState extends State<CustomFooter> {
  final Duration _duration = const Duration(milliseconds: 300);

  void _onItemTapped(int index) {
    setState(() {
      if (widget.selectedIndex != index) {
        // Perform navigation and set state
        switch (index) {
          case 0:
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => HomePage(selectedIndex: index)),
            );
            break;
          case 1:
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => MenuPage(selectedIndex: index)),
            );
            break;
          case 2:
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => FavouritesPage(selectedIndex: index)),
            );
            break;
          case 3:
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => ProfilePage(selectedIndex: index)),
            );
            break;
        }
      }
    });
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
          widget.selectedIndex >= 0
              ? _buildInverseTriangle(widget.selectedIndex)
              : Container(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(Iconsax.home, 0),
              _buildNavItem(Iconsax.book_saved, 1),
              _buildNavItem(Iconsax.heart, 2),
              _buildNavItem(Iconsax.user, 3),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInverseTriangle(int index) {
    return AnimatedAlign(
      alignment: Alignment((index * 2 - 3) * 0.29, -5),
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
    bool isSelected = widget.selectedIndex == index;
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

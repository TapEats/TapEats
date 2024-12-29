import 'package:flutter/material.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
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
  void _onItemTapped(int index) {
    if (widget.selectedIndex != index) {
      switch (index) {
        case 0:
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => HomePage()),
          );
          break;
        case 1:
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => MenuPage()),
          );
          break;
        case 2:
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => FavouritesPage()),
          );
          break;
        case 3:
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => ProfilePage()),
          );
          break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return CurvedNavigationBar(
      index: widget.selectedIndex,
      height: 60,
      backgroundColor: Colors.transparent,
      color: const Color(0xFF222222),
      buttonBackgroundColor: const Color(0xFF222222),
      animationDuration: const Duration(milliseconds: 300),
      animationCurve: Curves.easeInOut,
      items: const <Widget>[
        Icon(Iconsax.home, color: Color(0xFFEEEFEF), size: 28),
        Icon(Iconsax.book_saved, color: Color(0xFFEEEFEF), size: 28),
        Icon(Iconsax.heart, color: Color(0xFFEEEFEF), size: 28),
        Icon(Iconsax.user, color: Color(0xFFEEEFEF), size: 28),
      ],
      onTap: _onItemTapped,
    );
  }
}
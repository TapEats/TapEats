import 'package:flutter/material.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:iconsax/iconsax.dart';
import 'package:tapeats/presentation/screens/user_side/favourite_page.dart';
import 'package:tapeats/presentation/screens/user_side/menu_page.dart';
import 'package:tapeats/presentation/screens/user_side/home_page.dart';
import 'package:tapeats/presentation/screens/user_side/profile_page.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  
  final List<Widget> _pages = [
    const HomePage(),
    const MenuPage(),
    const FavouritesPage(),
    const ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF151611),
      extendBody: true,
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: CurvedNavigationBar(
        index: _selectedIndex,
        backgroundColor: Colors.transparent,
        color: const Color(0xFF222222),
        buttonBackgroundColor: const Color(0xFF222222),
        height: 60,
        animationDuration: const Duration(milliseconds: 300),
        animationCurve: Curves.easeInOut,
        items: <Widget>[
          Icon(Iconsax.home, 
            color: _selectedIndex == 0 ? const Color(0xFFD0F0C0) : const Color(0xFFEEEFEF),
            size: 28
          ),
          Icon(Iconsax.book_saved,
            color: _selectedIndex == 1 ? const Color(0xFFD0F0C0) : const Color(0xFFEEEFEF),
            size: 28
          ),
          Icon(Iconsax.heart,
            color: _selectedIndex == 2 ? const Color(0xFFD0F0C0) : const Color(0xFFEEEFEF),
            size: 28
          ),
          Icon(Iconsax.user,
            color: _selectedIndex == 3 ? const Color(0xFFD0F0C0) : const Color(0xFFEEEFEF),
            size: 28
          ),
        ],
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
    );
  }
}
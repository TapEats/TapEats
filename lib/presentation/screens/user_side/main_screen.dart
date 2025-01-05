import 'package:flutter/material.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import 'package:tapeats/presentation/screens/user_side/favourite_page.dart';
import 'package:tapeats/presentation/screens/user_side/menu_page.dart';
import 'package:tapeats/presentation/screens/user_side/home_page.dart';
import 'package:tapeats/presentation/screens/user_side/profile_page.dart';
import 'package:tapeats/presentation/state_management/navbar_state.dart';

class MainScreen extends StatelessWidget {
  MainScreen({super.key});

  final List<Widget> _pages = [
    const HomePage(),
    const MenuPage(),
    const FavouritesPage(),
    const ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Consumer<NavbarState>(
      builder: (context, navbarState, _) {
        return Scaffold(
          backgroundColor: const Color(0xFF151611),
          extendBody: true,
          body: IndexedStack(
            index: navbarState.currentIndex,
            children: _pages,
          ),
          bottomNavigationBar: CurvedNavigationBar(
            index: navbarState.currentIndex,
            backgroundColor: Colors.transparent,
            color: const Color(0xFF222222),
            buttonBackgroundColor: const Color(0xFF222222),
            height: 60,
            animationDuration: const Duration(milliseconds: 300),
            animationCurve: Curves.easeInOut,
            items: <Widget>[
              Icon(Iconsax.home, 
                color: navbarState.currentIndex == 0 
                  ? const Color(0xFFD0F0C0) 
                  : const Color(0xFFEEEFEF),
                size: 28
              ),
              Icon(Iconsax.book_saved,
                color: navbarState.currentIndex == 1 
                  ? const Color(0xFFD0F0C0) 
                  : const Color(0xFFEEEFEF),
                size: 28
              ),
              Icon(Iconsax.heart,
                color: navbarState.currentIndex == 2 
                  ? const Color(0xFFD0F0C0) 
                  : const Color(0xFFEEEFEF),
                size: 28
              ),
              Icon(Iconsax.user,
                color: navbarState.currentIndex == 3 
                  ? const Color(0xFFD0F0C0) 
                  : const Color(0xFFEEEFEF),
                size: 28
              ),
            ],
            onTap: (index) {
              navbarState.updateIndex(index);
            },
          ),
        );
      }
    );
  }
}
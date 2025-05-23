import 'package:flutter/material.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import 'package:tapeats/presentation/state_management/navbar_state.dart';

class DynamicFooter extends StatelessWidget {
  const DynamicFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<NavbarState>(
      builder: (context, navbarState, child) {
        final selectedIndex = navbarState.selectedIndex;
        final items = _buildNavItems(navbarState, selectedIndex);
        
        return CurvedNavigationBar(
          index: selectedIndex,
          height: 60,
          backgroundColor: Colors.transparent,
          color: const Color(0xFF222222),
          buttonBackgroundColor: const Color(0xFF222222),
          animationDuration: const Duration(milliseconds: 300),
          animationCurve: Curves.easeInOut,
          items: items,
          onTap: (index) => _onItemTapped(context, index, navbarState),
        );
      },
    );
  }

  List<Widget> _buildNavItems(NavbarState navbarState, int selectedIndex) {
    final userRole = navbarState.userRole;
    final accentColor = const Color(0xFFD0F0C0); // Accent color for selected items
    final defaultColor = const Color(0xFFEEEFEF); // Default color for unselected items
    
    if (userRole == 'customer') {
      // Customer navigation items
      return [
        Icon(Iconsax.home, color: selectedIndex == 0 ? accentColor : defaultColor, size: 28),
        Icon(Iconsax.book_saved, color: selectedIndex == 1 ? accentColor : defaultColor, size: 28),
        Icon(Iconsax.heart, color: selectedIndex == 2 ? accentColor : defaultColor, size: 28),
        Icon(Iconsax.user, color: selectedIndex == 3 ? accentColor : defaultColor, size: 28),
      ];
    } else if (userRole == 'restaurant_inventory_manager') {
      // Inventory manager has a smaller set of navigation options
      return [
        Icon(Iconsax.home, color: selectedIndex == 0 ? accentColor : defaultColor, size: 28),
        Icon(Iconsax.box, color: selectedIndex == 1 ? accentColor : defaultColor, size: 28),
        Icon(Iconsax.chart, color: selectedIndex == 2 ? accentColor : defaultColor, size: 28),
      ];
    } else if (userRole == 'restaurant_chef') {
      return [
        Icon(Iconsax.home, color: selectedIndex == 0 ? accentColor : defaultColor, size: 28),
        Icon(Iconsax.book_1, color: selectedIndex == 1 ? accentColor : defaultColor, size: 28),
        Icon(Iconsax.box, color: selectedIndex == 2 ? accentColor : defaultColor, size: 28),
        Icon(Iconsax.coffee, color: selectedIndex == 3 ? accentColor : defaultColor, size: 28),
      ];
    } else if (userRole == 'restaurant_waiter') {
      return [
        Icon(Iconsax.home, color: selectedIndex == 0 ? accentColor : defaultColor, size: 28),
        Icon(Iconsax.book_1, color: selectedIndex == 1 ? accentColor : defaultColor, size: 28),
        Icon(Iconsax.element_4, color: selectedIndex == 2 ? accentColor : defaultColor, size: 28),
        Icon(Iconsax.calendar_1, color: selectedIndex == 3 ? accentColor : defaultColor, size: 28),
      ];
    } else if (userRole == 'restaurant_cashier') {
      return [
        Icon(Iconsax.home, color: selectedIndex == 0 ? accentColor : defaultColor, size: 28),
        Icon(Iconsax.receipt, color: selectedIndex == 1 ? accentColor : defaultColor, size: 28),
        Icon(Iconsax.money, color: selectedIndex == 2 ? accentColor : defaultColor, size: 28),
        Icon(Iconsax.document_1, color: selectedIndex == 3 ? accentColor : defaultColor, size: 28),
      ];
    } else if (userRole?.startsWith('restaurant_') ?? false) {
      // Default for owner and manager (full access)
      return [
        Icon(Iconsax.home, color: selectedIndex == 0 ? accentColor : defaultColor, size: 28),
        Icon(Iconsax.book_1, color: selectedIndex == 1 ? accentColor : defaultColor, size: 28),
        Icon(Iconsax.element_4, color: selectedIndex == 2 ? accentColor : defaultColor, size: 28),
        Icon(Iconsax.box, color: selectedIndex == 3 ? accentColor : defaultColor, size: 28),
        Icon(Iconsax.chart, color: selectedIndex == 4 ? accentColor : defaultColor, size: 28),
      ];
    } else {
      // Default to customer if role is unknown
      return [
        Icon(Iconsax.home, color: selectedIndex == 0 ? accentColor : defaultColor, size: 28),
        Icon(Iconsax.book_saved, color: selectedIndex == 1 ? accentColor : defaultColor, size: 28),
        Icon(Iconsax.heart, color: selectedIndex == 2 ? accentColor : defaultColor, size: 28),
        Icon(Iconsax.user, color: selectedIndex == 3 ? accentColor : defaultColor, size: 28),
      ];
    }
  }

  void _onItemTapped(BuildContext context, int index, NavbarState navbarState) {
    // Update selected index in the provider
    navbarState.updateIndex(index);
    
    // For debugging - print to verify index is changing
    print('Navigation index changed to: $index');
    
    // Make sure any deep navigation stacks are popped when changing tabs
    while (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }
}
import 'package:flutter/material.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import 'package:tapeats/presentation/state_management/navbar_state.dart';

class DynamicFooter extends StatefulWidget {
  const DynamicFooter({super.key});

  @override
  State<DynamicFooter> createState() => _DynamicFooterState();
}

class _DynamicFooterState extends State<DynamicFooter> with SingleTickerProviderStateMixin {
  // Keep a GlobalKey that we'll recreate only when item count changes
  GlobalKey<CurvedNavigationBarState> _navBarKey = GlobalKey();
  late AnimationController _animationController;
  int? _previousItemCount;
  String? _previousRole;
  
  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    // Start animation when widget is first built
    _animationController.forward();
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<NavbarState>(
      builder: (context, navbarState, child) {
        final selectedIndex = navbarState.selectedIndex;
        final userRole = navbarState.userRole;
        
        // Get the icons based on role
        final iconList = _getIconsForRole(userRole);
        final currentItemCount = iconList.length;
        
        // Check if we need to create a new key
        if (_previousItemCount != currentItemCount || _previousRole != userRole) {
          // Create a new key only when item count or role changes
          _navBarKey = GlobalKey<CurvedNavigationBarState>();
          
          // Run animation for smoother transition
          _animationController.reset();
          _animationController.forward();
        }
        
        // Update previous values
        _previousItemCount = currentItemCount;
        _previousRole = userRole;
        
        // Build items with adaptive sizing
        final items = _buildNavItems(iconList, selectedIndex);
        
        // AnimatedBuilder for smooth transitions
        return AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return CurvedNavigationBar(
              key: _navBarKey,
              index: selectedIndex,
              height: 60,
              backgroundColor: Colors.transparent,
              color: const Color(0xFF222222),
              buttonBackgroundColor: const Color(0xFF222222),
              animationDuration: const Duration(milliseconds: 300),
              animationCurve: Curves.easeOutQuad,
              items: items,
              onTap: (index) => _onItemTapped(context, index, navbarState),
            );
          },
        );
      },
    );
  }

  List<IconData> _getIconsForRole(String? userRole) {
    if (userRole == 'super_admin' || userRole == 'developer_admin') {
      return [
        Iconsax.home_2,      // Dashboard
        Iconsax.user_edit,   // User Management
        Iconsax.cpu,         // System
        Iconsax.setting_2,   // Settings
        Iconsax.user,        // Profile
      ];
    } else if (userRole == 'customer') {
      return [
        Iconsax.home,        // Home
        Iconsax.book_saved,  // Menu
        Iconsax.heart,       // Favourites
        Iconsax.user,        // Profile
      ];
    } else if (userRole == 'restaurant_owner' || userRole == 'restaurant_manager') {
      return [
        Iconsax.home,        // Dashboard
        Iconsax.receipt,     // Orders
        Iconsax.element_4,   // Tables
        Iconsax.box,         // Inventory
        Iconsax.chart,       // Reports
      ];
    } else if (userRole == 'restaurant_chef') {
      return [
        Iconsax.home,        // Dashboard
        Iconsax.receipt,     // Orders
        Iconsax.book_1,      // Menu
        Iconsax.box,         // Inventory
      ];
    } else if (userRole == 'restaurant_waiter') {
      return [
        Iconsax.home,        // Dashboard
        Iconsax.receipt,     // Orders
        Iconsax.element_4,   // Tables
        Iconsax.add_square,  // New Order
      ];
    } else if (userRole == 'restaurant_cashier') {
      return [
        Iconsax.home,        // Dashboard
        Iconsax.receipt,     // Orders
        Iconsax.money,       // Payments
        Iconsax.chart,       // Reports
      ];
    } else if (userRole == 'restaurant_inventory_manager') {
      return [
        Iconsax.home,        // Dashboard
        Iconsax.box,         // Inventory
        Iconsax.chart,       // Reports
      ];
    } else {
      // Default to customer icons
      return [
        Iconsax.home,
        Iconsax.book_saved,
        Iconsax.heart,
        Iconsax.user,
      ];
    }
  }

  List<Widget> _buildNavItems(List<IconData> iconList, int selectedIndex) {
    final accentColor = const Color(0xFFD0F0C0);
    final defaultColor = const Color(0xFFEEEFEF);
    
    return List.generate(iconList.length, (index) {
      final bool isSelected = selectedIndex == index;
      
      return SizedBox(
        width: 40,
        height: 40,
        child: Center(
          child: Icon(
            iconList[index],
            color: isSelected ? accentColor : defaultColor,
            size: 28,
          ),
        ),
      );
    });
  }

  void _onItemTapped(BuildContext context, int index, NavbarState navbarState) {
    if (navbarState.selectedIndex == index) return;
    
    navbarState.updateIndex(index);
    print('Navigation index changed to: $index');
    
    Future.delayed(const Duration(milliseconds: 100), () {
      if (!mounted) return;
      while (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    });
  }
}
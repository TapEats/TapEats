import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tapeats/presentation/screens/restaurant_side/inventory_management/inventory_management_page.dart';
import 'package:tapeats/presentation/screens/restaurant_side/received_page.dart';
import 'package:tapeats/presentation/screens/restaurant_side/restaurant_home_page.dart';
import 'package:tapeats/presentation/screens/user_side/favourite_page.dart';
import 'package:tapeats/presentation/screens/user_side/home_page.dart';
import 'package:tapeats/presentation/screens/user_side/menu_page.dart';
import 'package:tapeats/presentation/screens/user_side/profile_page.dart';
import 'package:tapeats/presentation/state_management/navbar_state.dart';
import 'package:tapeats/presentation/widgets/footer_widget.dart';
import 'package:tapeats/services/side_menu_service.dart';
import 'package:iconsax/iconsax.dart';

class MainScreen extends StatelessWidget {
  final Widget? body;
  final String? title;
  final List<Widget>? actions;
  final bool showLeading;
  
  const MainScreen({
    super.key,
    this.body,
    this.title,
    this.actions,
    this.showLeading = true,
  });

  @override
Widget build(BuildContext context) {
  return Consumer<NavbarState>(
    builder: (context, navbarState, child) {
      return Scaffold(
        // Your AppBar if needed
        body: body ?? _buildBody(navbarState),
        extendBody: true,
        bottomNavigationBar: const DynamicFooter(),
      );
    },
  );
}

Widget _buildBody(NavbarState navbarState) {
  final userRole = navbarState.userRole;
  
  if (userRole == 'customer') {
    return IndexedStack(
      index: navbarState.selectedIndex,
      children: const [
        HomePage(),
        MenuPage(),
        FavouritesPage(),
        ProfilePage(),
      ],
    );
  } else if (userRole?.startsWith('restaurant_') ?? false) {
    // Create appropriate stack for restaurant roles
    return IndexedStack(
      index: navbarState.selectedIndex,
      children: [
        const RestaurantHomePage(selectedIndex: 0),
        const ReceivedOrdersPage(selectedIndex: 1),
        const InventoryManagementPage(selectedIndex: 2),
        // Add other pages
      ],
    );
  } else {
    // Default stack
    return IndexedStack(
      index: navbarState.selectedIndex,
      children: const [HomePage()],
    );
  }
}

  // String _getDefaultTitle(NavbarState navbarState) {
  //   final index = navbarState.selectedIndex;
  //   final userRole = navbarState.userRole;
  //   final labels = navbarState.getNavBarLabels();
    
  //   // Use the label from the current index if available
  //   if (index >= 0 && index < labels.length) {
  //     return labels[index];
  //   }
    
  //   // Fallback titles
  //   if (userRole?.startsWith('restaurant_') ?? false) {
  //     return 'Restaurant Portal';
  //   } else {
  //     return 'TapEats';
  //   }
  // }

  // List<Widget> _getDefaultActions(BuildContext context, NavbarState navbarState) {
  //   final List<Widget> actions = [];
  //   final userRole = navbarState.userRole;
  //   final index = navbarState.selectedIndex;
    
  //   // Add role-specific action buttons
  //   if (userRole == 'customer') {
  //     // For customer role
  //     actions.add(
  //       IconButton(
  //         icon: const Icon(Iconsax.shopping_cart),
  //         onPressed: () {
  //           // Navigate to cart page
  //         },
  //       ),
  //     );
      
  //     // Add search for menu page
  //     if (index == 1) {
  //       actions.add(
  //         IconButton(
  //           icon: const Icon(Iconsax.search_normal),
  //           onPressed: () {
  //             // Show search functionality
  //           },
  //         ),
  //       );
  //     }
  //   } else if (userRole?.startsWith('restaurant_') ?? false) {
  //     // Common restaurant actions
  //     if (index == 0) { // Dashboard for all roles
  //       actions.add(
  //         IconButton(
  //           icon: const Icon(Iconsax.notification),
  //           onPressed: () {
  //             // Show notifications
  //           },
  //         ),
  //       );
  //     }
      
  //     // Role-specific actions
  //     if ((userRole == 'restaurant_owner' || userRole == 'restaurant_manager') && index == 1) {
  //       // Menu management for owner/manager
  //       actions.add(
  //         IconButton(
  //           icon: const Icon(Iconsax.edit),
  //           onPressed: () {
  //             // Edit menu
  //           },
  //         ),
  //       );
  //     }
      
  //     if ((userRole == 'restaurant_owner' || userRole == 'restaurant_manager' || 
  //          userRole == 'restaurant_inventory_manager') && 
  //         (index == 3 || (userRole == 'restaurant_inventory_manager' && index == 1))) {
  //       // Inventory actions
  //       actions.add(
  //         IconButton(
  //           icon: const Icon(Iconsax.scan_barcode),
  //           onPressed: () {
  //             // Scan inventory item
  //           },
  //         ),
  //       );
  //     }
      
  //     // Waiter-specific actions
  //     if (userRole == 'restaurant_waiter' && index == 2) { // Tables view
  //       actions.add(
  //         IconButton(
  //           icon: const Icon(Iconsax.add_square),
  //           onPressed: () {
  //             // Add new table or reservation
  //           },
  //         ),
  //       );
  //     }
      
  //     // Chef-specific actions
  //     if (userRole == 'restaurant_chef' && index == 3) { // Kitchen display
  //       actions.add(
  //         IconButton(
  //           icon: const Icon(Iconsax.timer_1),
  //           onPressed: () {
  //             // View order timers
  //           },
  //         ),
  //       );
  //     }
      
  //     // Cashier-specific actions
  //     if (userRole == 'restaurant_cashier' && index == 2) { // Payments
  //       actions.add(
  //         IconButton(
  //           icon: const Icon(Iconsax.calculator),
  //           onPressed: () {
  //             // Open calculator
  //           },
  //         ),
  //       );
  //     }
      
  //     // Reports page (for roles that have access)
  //     if ((userRole == 'restaurant_owner' || userRole == 'restaurant_manager') && index == 4) {
  //       actions.add(
  //         IconButton(
  //           icon: const Icon(Iconsax.document_download),
  //           onPressed: () {
  //             // Download report
  //           },
  //         ),
  //       );
        
  //       actions.add(
  //         IconButton(
  //           icon: const Icon(Iconsax.filter),
  //           onPressed: () {
  //             // Filter reports
  //           },
  //         ),
  //       );
  //     }
  //   }
    
  //   return actions;
  // }

  // Color _getAppBarColor(String? userRole) {
  //   return const Color(0xFF222222);
  // }
}
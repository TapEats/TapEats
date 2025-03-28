import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'package:tapeats/presentation/state_management/navbar_state.dart';
import 'package:tapeats/services/profile_image_service.dart';

// Import all possible screens for different roles
// Customer pages
import 'package:tapeats/presentation/screens/user_side/home_page.dart';
import 'package:tapeats/presentation/screens/user_side/menu_page.dart';
import 'package:tapeats/presentation/screens/user_side/favourite_page.dart';
import 'package:tapeats/presentation/screens/user_side/order_history_page.dart';
import 'package:tapeats/presentation/screens/user_side/profile_page.dart';

// Restaurant pages - common
import 'package:tapeats/presentation/screens/restaurant_side/received_page.dart';
import 'package:tapeats/presentation/screens/restaurant_side/restaurant_home_page.dart';
// import 'package:tapeats/presentation/screens/restaurant_side/dashboard_page.dart';
// import 'package:tapeats/presentation/screens/restaurant_side/active_orders_page.dart';
// import 'package:tapeats/presentation/screens/restaurant_side/received_orders_page.dart';
// import 'package:tapeats/presentation/screens/restaurant_side/menu_view_page.dart';
// import 'package:tapeats/presentation/screens/restaurant_side/tables_overview_page.dart';
// import 'package:tapeats/presentation/screens/restaurant_side/table_orders_page.dart';

// // Restaurant pages - role specific
// import 'package:tapeats/presentation/screens/restaurant_side/edit_menu_page.dart';
// import 'package:tapeats/presentation/screens/restaurant_side/inventory_management_page.dart';
// import 'package:tapeats/presentation/screens/restaurant_side/reports_page.dart';
// import 'package:tapeats/presentation/screens/restaurant_side/rbac_management_page.dart';
// import 'package:tapeats/presentation/screens/restaurant_side/stock_management_page.dart';
// import 'package:tapeats/presentation/screens/restaurant_side/supplier_management_page.dart';
// import 'package:tapeats/presentation/screens/restaurant_side/kitchen_display_page.dart';
// import 'package:tapeats/presentation/screens/restaurant_side/recipe_management_page.dart';
// import 'package:tapeats/presentation/screens/restaurant_side/reservation_management_page.dart';
// import 'package:tapeats/presentation/screens/restaurant_side/customer_notes_page.dart';
// import 'package:tapeats/presentation/screens/restaurant_side/payment_processing_page.dart';
// import 'package:tapeats/presentation/screens/restaurant_side/reconciliation_page.dart';
// import 'package:tapeats/presentation/screens/restaurant_side/restaurant_profile_page.dart';

class MenuItem {
  final String title;
  final IconData icon;
  final Widget page;
  final List<String> allowedRoles;

  MenuItem({
    required this.title,
    required this.icon,
    required this.page,
    required this.allowedRoles,
  });
}

class RoleBasedSideMenu extends StatefulWidget {
  const RoleBasedSideMenu({super.key});

  @override
  State<RoleBasedSideMenu> createState() => _RoleBasedSideMenuState();
}

class _RoleBasedSideMenuState extends State<RoleBasedSideMenu>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  String? _profileImageUrl;
  String? _userRole;
  String? _userName;
  final _supabase = Supabase.instance.client;
  final _profileImageService = ProfileImageService();

  // Define all possible menu items across all roles
  final List<MenuItem> _allMenuItems = [
    // Customer Menu Items
    MenuItem(
      title: 'Home',
      icon: Iconsax.home,
      page: const HomePage(),
      allowedRoles: ['customer'],
    ),
    MenuItem(
      title: 'Menu',
      icon: Iconsax.book_saved,
      page: const MenuPage(),
      allowedRoles: ['customer'],
    ),
    MenuItem(
      title: 'Favourites',
      icon: Iconsax.heart,
      page: const FavouritesPage(),
      allowedRoles: ['customer'],
    ),
    MenuItem(
      title: 'Order History',
      icon: Iconsax.calendar,
      page: const OrderHistoryPage(),
      allowedRoles: ['customer'],
    ),
    MenuItem(
      title: 'Profile',
      icon: Iconsax.user,
      page: const ProfilePage(),
      allowedRoles: ['customer'],
    ),

    // === RESTAURANT COMMON PAGES ===
    // Dashboard (For all restaurant roles)
    MenuItem(
      title: 'Dashboard',
      icon: Iconsax.home,
      page: const RestaurantHomePage(selectedIndex: 0),
      allowedRoles: [
        'restaurant_owner',
        'restaurant_manager',
        'restaurant_chef',
        'restaurant_waiter',
        'restaurant_inventory_manager',
        'restaurant_cashier'
      ],
    ),

    // // Active Orders (For roles that manage orders)
    // MenuItem(
    //   title: 'Active Orders',
    //   icon: Iconsax.activity,
    //   page: const ActiveOrdersPage(),
    //   allowedRoles: [
    //     'restaurant_owner',
    //     'restaurant_manager',
    //     'restaurant_chef',
    //     'restaurant_waiter',
    //     'restaurant_cashier'
    //   ],
    // ),

    // Received Orders
    MenuItem(
      title: 'Received Orders',
      icon: Iconsax.receipt,
      page: const ReceivedOrdersPage(selectedIndex: 1),
      allowedRoles: [
        'restaurant_owner',
        'restaurant_manager',
        'restaurant_chef',
        'restaurant_waiter',
        'restaurant_cashier'
      ],
    ),

    // // Menu View (Read-only for most)
    // MenuItem(
    //   title: 'Menu',
    //   icon: Iconsax.book_1,
    //   page: const MenuViewPage(),
    //   allowedRoles: [
    //     'restaurant_owner',
    //     'restaurant_manager',
    //     'restaurant_chef',
    //     'restaurant_waiter',
    //     'restaurant_cashier'
    //   ],
    // ),

    // // Tables Overview
    // MenuItem(
    //   title: 'Tables',
    //   icon: Iconsax.element_4,
    //   page: const TablesOverviewPage(),
    //   allowedRoles: [
    //     'restaurant_owner',
    //     'restaurant_manager',
    //     'restaurant_waiter'
    //   ],
    // ),

    // // Table Orders
    // MenuItem(
    //   title: 'Table Orders',
    //   icon: Iconsax.clipboard_text,
    //   page: const TableOrdersPage(),
    //   allowedRoles: [
    //     'restaurant_owner',
    //     'restaurant_manager',
    //     'restaurant_waiter',
    //     'restaurant_cashier'
    //   ],
    // ),

    // // === OWNER & MANAGER SPECIFIC PAGES ===

    // // Edit Menu
    // MenuItem(
    //   title: 'Edit Menu',
    //   icon: Iconsax.edit,
    //   page: const EditMenuPage(),
    //   allowedRoles: [
    //     'restaurant_owner',
    //     'restaurant_manager'
    //   ],
    // ),

    // // Inventory Management
    // MenuItem(
    //   title: 'Inventory',
    //   icon: Iconsax.box,
    //   page: const InventoryManagementPage(),
    //   allowedRoles: [
    //     'restaurant_owner',
    //     'restaurant_manager',
    //     'restaurant_inventory_manager'
    //   ],
    // ),

    // // Reports & Analytics
    // MenuItem(
    //   title: 'Reports',
    //   icon: Iconsax.chart,
    //   page: const ReportsPage(),
    //   allowedRoles: [
    //     'restaurant_owner',
    //     'restaurant_manager',
    //     'restaurant_inventory_manager' // Limited reports for inventory
    //   ],
    // ),

    // // RBAC Management (Owner only)
    // MenuItem(
    //   title: 'Roles/RBAC',
    //   icon: Iconsax.security_user,
    //   page: const RBACManagementPage(),
    //   allowedRoles: [
    //     'restaurant_owner'
    //   ],
    // ),

    // // === INVENTORY MANAGER SPECIFIC ===

    // // Stock Management
    // MenuItem(
    //   title: 'Stock',
    //   icon: Iconsax.box_1,
    //   page: const StockManagementPage(),
    //   allowedRoles: [
    //     'restaurant_owner',
    //     'restaurant_manager',
    //     'restaurant_inventory_manager',
    //     'restaurant_chef' // Read-only for chef
    //   ],
    // ),

    // // Supplier Management
    // MenuItem(
    //   title: 'Suppliers',
    //   icon: Iconsax.truck,
    //   page: const SupplierManagementPage(),
    //   allowedRoles: [
    //     'restaurant_owner',
    //     'restaurant_manager',
    //     'restaurant_inventory_manager'
    //   ],
    // ),

    // // === CHEF SPECIFIC ===

    // // Kitchen Display
    // MenuItem(
    //   title: 'Kitchen Display',
    //   icon: Iconsax.cooking,
    //   page: const KitchenDisplayPage(),
    //   allowedRoles: [
    //     'restaurant_owner',
    //     'restaurant_manager',
    //     'restaurant_chef'
    //   ],
    // ),

    // // Recipe Management
    // MenuItem(
    //   title: 'Recipes',
    //   icon: Iconsax.document_text,
    //   page: const RecipeManagementPage(),
    //   allowedRoles: [
    //     'restaurant_owner',
    //     'restaurant_manager',
    //     'restaurant_chef'
    //   ],
    // ),

    // // === WAITER SPECIFIC ===

    // // Reservation Management
    // MenuItem(
    //   title: 'Reservations',
    //   icon: Iconsax.calendar_1,
    //   page: const ReservationManagementPage(),
    //   allowedRoles: [
    //     'restaurant_owner',
    //     'restaurant_manager',
    //     'restaurant_waiter'
    //   ],
    // ),

    // // Customer Notes
    // MenuItem(
    //   title: 'Customer Notes',
    //   icon: Iconsax.note_1,
    //   page: const CustomerNotesPage(),
    //   allowedRoles: [
    //     'restaurant_owner',
    //     'restaurant_manager',
    //     'restaurant_waiter'
    //   ],
    // ),

    // // === CASHIER SPECIFIC ===

    // // Payment Processing
    // MenuItem(
    //   title: 'Payments',
    //   icon: Iconsax.money,
    //   page: const PaymentProcessingPage(),
    //   allowedRoles: [
    //     'restaurant_owner',
    //     'restaurant_manager',
    //     'restaurant_cashier'
    //   ],
    // ),

    // // End-of-Day Reconciliation
    // MenuItem(
    //   title: 'Reconciliation',
    //   icon: Iconsax.document_1,
    //   page: const ReconciliationPage(),
    //   allowedRoles: [
    //     'restaurant_owner',
    //     'restaurant_manager',
    //     'restaurant_cashier'
    //   ],
    // ),

    // // === SHARED SETTINGS ===

    // // Restaurant Profile Settings
    // MenuItem(
    //   title: 'Settings',
    //   icon: Iconsax.setting,
    //   page: const RestaurantProfilePage(),
    //   allowedRoles: [
    //     'restaurant_owner',
    //     'restaurant_manager'
    //   ],
    // ),
  ];

  // Filtered menu items based on user role
  List<MenuItem> _filteredMenuItems = [];
  // Grouped menu items for better organization
  Map<String, List<MenuItem>> _groupedMenuItems = {};

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(-1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    _controller.forward();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user != null) {
        // Load profile image
        final imageUrl = await _profileImageService.getProfileImageUrl(user.id);

        // Get user role from Supabase
        final userData = await _supabase
            .from('users')
            .select('role, username')
            .eq('user_id', user.id)
            .single();

        final userRole = userData['role'] as String?;
        final userName = userData['username'] as String?;

        if (mounted) {
          setState(() {
            _profileImageUrl = imageUrl;
            _userRole = userRole;
            _userName = userName;

            // Filter menu items based on user role
            _filteredMenuItems = _allMenuItems
                .where((item) => item.allowedRoles.contains(userRole))
                .toList();

            // Group menu items for restaurant roles
            if (userRole?.startsWith('restaurant_') ?? false) {
              _groupMenuItems();
            }
          });
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading user data: $e');
      }
    }
  }

  void _groupMenuItems() {
    _groupedMenuItems = {
      'Main': [], // For dashboard and main navigation
      'Orders': [], // For order management
      'Menu & Tables': [], // For menu and table management
      'Inventory': [], // For inventory and stock
      'Reports': [], // For analytics and reports
      'Settings': [], // For settings and configuration
    };

    for (var item in _filteredMenuItems) {
      if (item.title == 'Dashboard' || item.title == 'Home') {
        _groupedMenuItems['Main']!.add(item);
      } else if (item.title.contains('Order') ||
          item.title == 'Kitchen Display' ||
          item.title == 'Payments' ||
          item.title == 'Reconciliation') {
        _groupedMenuItems['Orders']!.add(item);
      } else if (item.title.contains('Menu') ||
          item.title.contains('Table') ||
          item.title == 'Reservations') {
        _groupedMenuItems['Menu & Tables']!.add(item);
      } else if (item.title.contains('Inventory') ||
          item.title.contains('Stock') ||
          item.title == 'Suppliers' ||
          item.title == 'Recipes') {
        _groupedMenuItems['Inventory']!.add(item);
      } else if (item.title.contains('Report') || item.title == 'Analytics') {
        _groupedMenuItems['Reports']!.add(item);
      } else if (item.title == 'Settings' ||
          item.title == 'Roles/RBAC' ||
          item.title == 'Profile') {
        _groupedMenuItems['Settings']!.add(item);
      } else {
        // Add to Main if doesn't fit elsewhere
        _groupedMenuItems['Main']!.add(item);
      }
    }

    // Remove empty categories
    _groupedMenuItems.removeWhere((key, value) => value.isEmpty);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _closeMenu() {
    _controller.reverse().then((_) => Navigator.of(context).pop());
  }

  Future<void> _handleSignOut() async {
    try {
      // First close the menu with animation
      await _controller.reverse();
      if (!mounted) return;

      // Remove the overlay
      Navigator.of(context).pop();

      // Then sign out
      await _supabase.auth.signOut();
      if (!mounted) return;

      // Navigate to login using named route and clear stack
      await Navigator.of(context).pushNamedAndRemoveUntil(
        '/auth/login',
        (route) => false,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error signing out: $e');
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error signing out. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _navigateToPage(Widget page) async {
    // Special handling for standalone pages that don't affect bottom navbar
    bool isStandalonePage = page is ReceivedOrdersPage
        //  ||
        // page is ActiveOrdersPage ||
        // page is ReservationManagementPage ||
        // page is RBACManagementPage ||
        // page is SupplierManagementPage
        ;

    if (isStandalonePage) {
      // Wait for animation to complete before navigation
      await _controller.reverse();
      if (!mounted) return;

      // Remove the overlay
      Navigator.of(context).pop();

      // Add a small delay to ensure overlay is completely gone
      await Future.delayed(const Duration(milliseconds: 50));
      if (!mounted) return;

      // Navigate to standalone page
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => page,
        ),
      );
    } else {
      // Wait for animation
      await _controller.reverse();
      if (!mounted) return;

      // Remove the overlay
      Navigator.of(context).pop();

      // If we're currently in a pushed route, pop back to main navigation
      while (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      // Update NavbarState based on the page
      _updateNavbarState(page);
    }
  }

  void _updateNavbarState(Widget page) {
    // Get the NavbarState
    final navbarState = Provider.of<NavbarState>(context, listen: false);

    if (_userRole == 'customer') {
      if (page is HomePage) {
        navbarState.updateIndex(0);
      } else if (page is MenuPage) {
        navbarState.updateIndex(1);
      } else if (page is FavouritesPage) {
        navbarState.updateIndex(2);
      } else if (page is ProfilePage) {
        navbarState.updateIndex(3);
      }
    } else if (_userRole?.startsWith('restaurant_') ?? false) {
      // Restaurant side navigation - the exact indices would depend on your NavbarState implementation
      if (page is RestaurantHomePage) {
        navbarState.updateIndex(0);
      }
      // else if (page is MenuViewPage || page is EditMenuPage) {
      //   navbarState.updateIndex(1);
      // } else if (page is TablesOverviewPage) {
      //   navbarState.updateIndex(2);
      // } else if (page is InventoryManagementPage || page is StockManagementPage) {
      //   navbarState.updateIndex(3);
      // } else if (page is ReportsPage) {
      //   navbarState.updateIndex(4);
      // }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _closeMenu,
      onHorizontalDragUpdate: (details) {
        if (details.primaryDelta != null && details.primaryDelta! < 0) {
          _closeMenu();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black.withAlpha(150),
        body: Stack(
          children: [
            GestureDetector(
              onTap: () {},
              child: SlideTransition(
                position: _slideAnimation,
                child: Container(
                  width: 280,
                  height: MediaQuery.of(context).size.height,
                  decoration: const BoxDecoration(
                    color: Color(
                        0xFF222222), // Consistent dark background for all roles
                    borderRadius: BorderRadius.only(
                      topRight: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 50),
                      CircleAvatar(
                        radius: 40,
                        backgroundImage: _profileImageUrl != null
                            ? NetworkImage(_profileImageUrl!)
                            : const AssetImage('assets/images/cupcake.png')
                                as ImageProvider,
                      ),
                      const SizedBox(height: 10),
                      if (_userName != null)
                        Text(
                          _userName!,
                          style: const TextStyle(
                            color: Color(0xFFEEEFEF),
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Helvetica Neue',
                          ),
                        ),
                      if (_userRole != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20.0),
                          child: Text(
                            _formatRoleForDisplay(_userRole!),
                            style: TextStyle(
                              color: Colors.white.withAlpha(179), // 70% alpha
                              fontSize: 14,
                              fontFamily: 'Helvetica Neue',
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      const SizedBox(height: 20),
                      const Divider(color: Color(0xFF333333)),

                      // Menu Items Section
                      Expanded(
                        child: _userRole?.startsWith('restaurant_') ?? false
                            ? _buildGroupedMenuItems() // For restaurant roles
                            : _buildCustomerMenuItems(), // For customer role
                      ),

                      // Bottom section with sign out
                      const Divider(color: Color(0xFF333333)),
                      _buildMenuItem(
                        'Sign out',
                        Iconsax.logout,
                        onTap: _handleSignOut,
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerMenuItems() {
    return ListView(
      padding: EdgeInsets.zero,
      children: _filteredMenuItems
          .map(
            (item) => _buildMenuItem(
              item.title,
              item.icon,
              onTap: () => _navigateToPage(item.page),
            ),
          )
          .toList(),
    );
  }

  Widget _buildGroupedMenuItems() {
    return ListView(
      padding: EdgeInsets.zero,
      children: _groupedMenuItems.entries.map((entry) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding:
                  const EdgeInsets.only(left: 16.0, top: 12.0, bottom: 4.0),
              child: Text(
                entry.key,
                style: const TextStyle(
                  color: Color(0xFFEEEFEF),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            ...entry.value.map(
              (item) => _buildMenuItem(
                item.title,
                item.icon,
                onTap: () => _navigateToPage(item.page),
              ),
            ),
            const SizedBox(height: 8),
            if (entry.key != _groupedMenuItems.keys.last)
              const Divider(color: Color(0xFF333333), height: 1),
          ],
        );
      }).toList(),
    );
  }

  String _formatRoleForDisplay(String role) {
    // Convert roles like "restaurant_owner" to "Restaurant Owner"
    if (role.startsWith('restaurant_')) {
      final rolePart = role.substring('restaurant_'.length);
      return 'Restaurant ${rolePart[0].toUpperCase()}${rolePart.substring(1)}';
    } else {
      return role[0].toUpperCase() + role.substring(1);
    }
  }

  Widget _buildMenuItem(String title, IconData icon, {VoidCallback? onTap}) {
    return ListTile(
      dense: true,
      visualDensity: const VisualDensity(horizontal: 0, vertical: -1),
      leading: Icon(icon, color: const Color(0xFFEEEFEF), size: 20),
      title: Text(
        title,
        style: const TextStyle(
          color: Color(0xFFEEEFEF),
          fontSize: 15,
          fontFamily: 'Helvetica Neue',
        ),
      ),
      onTap: onTap,
    );
  }
}

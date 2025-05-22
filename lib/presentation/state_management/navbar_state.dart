import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tapeats/presentation/screens/admin/settings_admin_page.dart';
import 'package:tapeats/presentation/screens/admin/admin_panel.dart';
import 'package:tapeats/presentation/screens/admin/system_admin_page.dart';
import 'package:tapeats/presentation/screens/admin/users_admin_page.dart';
import 'package:tapeats/presentation/screens/restaurant_side/employee_page.dart';
import 'package:tapeats/presentation/screens/restaurant_side/inventory_management/inventory_management_page.dart';
import 'package:tapeats/presentation/screens/restaurant_side/payment_history_page.dart';
import 'package:tapeats/presentation/screens/restaurant_side/reports_page.dart';
import 'package:tapeats/presentation/screens/restaurant_side/rest_edit_add_menu.dart';
import 'package:tapeats/presentation/screens/restaurant_side/rest_ordering_page.dart';
import 'package:tapeats/presentation/screens/restaurant_side/rest_table_page.dart';

// Import customer pages
import 'package:tapeats/presentation/screens/user_side/home_page.dart';
import 'package:tapeats/presentation/screens/user_side/menu_page.dart';
import 'package:tapeats/presentation/screens/user_side/favourite_page.dart';
import 'package:tapeats/presentation/screens/user_side/profile_page.dart';

// Import restaurant pages
import 'package:tapeats/presentation/screens/restaurant_side/restaurant_home_page.dart';
import 'package:tapeats/presentation/screens/restaurant_side/received_page.dart';
// import 'package:tapeats/presentation/screens/restaurant_side/dashboard_page.dart';
// import 'package:tapeats/presentation/screens/restaurant_side/menu_view_page.dart';
// import 'package:tapeats/presentation/screens/restaurant_side/tables_overview_page.dart';
// import 'package:tapeats/presentation/screens/restaurant_side/inventory_management_page.dart';
// import 'package:tapeats/presentation/screens/restaurant_side/reports_page.dart';
// import 'package:tapeats/presentation/screens/restaurant_side/kitchen_display_page.dart';
// import 'package:tapeats/presentation/screens/restaurant_side/reservation_management_page.dart';
// import 'package:tapeats/presentation/screens/restaurant_side/payment_processing_page.dart';
// import 'package:tapeats/presentation/screens/restaurant_side/received_orders_page.dart';
// import 'package:tapeats/presentation/screens/restaurant_side/reconciliation_page.dart';

class NavbarState extends ChangeNotifier {
  int _selectedIndex = 0;
  String? _userRole;
  final _supabase = Supabase.instance.client;
  
  NavbarState() {
    _initUserRole();
  }
  
  // Initialize the user role
  Future<void> _initUserRole() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user != null) {
        final userData = await _supabase
            .from('users')
            .select('role')
            .eq('user_id', user.id)
            .single();
        
        _userRole = userData['role'] as String?;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error initializing user role: $e');
    }
  }
  
  int get selectedIndex => _selectedIndex;
  String? get userRole => _userRole;
  
  // Update the role if it changes (e.g., after sign in)
  Future<void> updateRole() async {
    await _initUserRole();
  }
  
  void updateIndex(int index) {
    _selectedIndex = index;
    notifyListeners();
  }
  
  // Get the appropriate page based on role and index
  Widget getPageForIndex(int index) {
    if (_userRole == 'customer') {
      return _getCustomerPage(index);
    } else if (_userRole == 'restaurant_inventory_manager') {
      return _getInventoryManagerPage(index);
    } else if (_userRole == 'restaurant_chef') {
      return _getChefPage(index);
    } else if (_userRole == 'restaurant_waiter') {
      return _getWaiterPage(index);
    } else if (_userRole == 'restaurant_cashier') {
      return _getCashierPage(index);
    } else if (_userRole == 'restaurant_owner' ||
               _userRole == 'restaurant_manager') {
      // Default for owner and manager
      return _getManagerPage(index);
    } else {
      // Default to customer pages if role is not recognized
      return _getCustomerPage(index);
    }
  }
  
  // Customer navigation
  Widget _getCustomerPage(int index) {
    switch (index) {
      case 0:
        return const HomePage();
      case 1:
        return const MenuPage();
      case 2:
        return const FavouritesPage();
      case 3:
        return const ProfilePage();
      default:
        return const HomePage();
    }
  }
  
  // Restaurant Owner & Manager (full access)
  Widget _getManagerPage(int index) {
    switch (index) {
      case 0:
        return const RestaurantHomePage();
      case 1:
        return const ReceivedOrdersPage();
      case 2:
        return const InventoryManagementPage();
      case 3:
        return const ReportsPage();
      case 4:
        return const EmployeeManagementPage();
      default:
        return const RestaurantHomePage();
    }
  }
  
  // Inventory Manager specific navigation
  Widget _getInventoryManagerPage(int index) {
    switch (index) {
      case 0:
        return const RestaurantHomePage();
      // case 1:
      //   return const InventoryManagementPage();
      // case 2:
      //   return const ReportsPage();
      default:
        return const RestaurantHomePage();
    }
  }
  
  // Chef specific navigation
  Widget _getChefPage(int index) {
    switch (index) {
      case 0:
        return const RestaurantHomePage();
      // case 1:
      //   return const MenuViewPage();
      // case 2:
      //   return const InventoryManagementPage();
      // case 3:
      //   return const KitchenDisplayPage();
      default:
        return const RestaurantHomePage();
    }
  }
  
  // Waiter specific navigation
  Widget _getWaiterPage(int index) {
    switch (index) {
      case 0:
        return const RestaurantHomePage();
      // case 1:
      //   return const MenuViewPage();
      // case 2:
      //   return const TablesOverviewPage();
      // case 3:
      //   return const ReservationManagementPage();
      default:
        return const RestaurantHomePage();
    }
  }
  
  // Cashier specific navigation
  Widget _getCashierPage(int index) {
    switch (index) {
      case 0:
        return const RestaurantHomePage();
      case 1:
        return const ReceivedOrdersPage();
      // case 2:
      //   return const PaymentProcessingPage();
      // case 3:
      //   return const ReconciliationPage();
      default:
        return const RestaurantHomePage();
    }
  }
  
  // Get the labels for bottom navigation bar items based on role
  List<String> getNavBarLabels() {
    if (_userRole == 'super_admin' || _userRole == 'developer_admin') {
      return ['Dashboard', 'Users', 'System', 'Settings', 'Profile'];
    } else if (_userRole == 'customer') {
      return ['Home', 'Menu', 'Favourites', 'Profile'];
    } else if (_userRole == 'restaurant_owner' || _userRole == 'restaurant_manager') {
      return ['Dashboard', 'Orders', 'Tables', 'Inventory', 'Reports'];
    } else if (_userRole == 'restaurant_chef') {
      return ['Dashboard', 'Orders', 'Menu', 'Inventory'];
    } else if (_userRole == 'restaurant_waiter') {
      return ['Dashboard', 'Orders', 'Tables', 'New Order'];
    } else if (_userRole == 'restaurant_cashier') {
      return ['Dashboard', 'Orders', 'Payments', 'Reports'];
    } else if (_userRole == 'restaurant_inventory_manager') {
      return ['Dashboard', 'Inventory', 'Reports'];
    } else {
      return ['Home', 'Menu', 'Favourites', 'Profile'];
    }
  }
  
  // Helper method for navigation via the side menu
  void navigateToSpecificPage(BuildContext context, Widget page) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => page),
    );
  }
  
  // Check if current user has access to a specific feature
  bool hasAccess(String feature) {
    if (_userRole == 'customer') {
      // Customer access rights
      final customerFeatures = [
        'home', 'menu', 'favourites', 'profile', 'order_history'
      ];
      return customerFeatures.contains(feature);
    } else if (_userRole == 'restaurant_owner') {
      // Owner has access to everything
      return true;
    } else if (_userRole == 'restaurant_manager') {
      // Manager has access to most things except role management
      return feature != 'rbac_management';
    } else if (_userRole == 'restaurant_inventory_manager') {
      // Inventory manager access
      final inventoryFeatures = [
        'dashboard', 'inventory', 'stock', 'suppliers', 'inventory_reports'
      ];
      return inventoryFeatures.contains(feature);
    } else if (_userRole == 'restaurant_chef') {
      // Chef access
      final chefFeatures = [
        'dashboard', 'menu_view', 'inventory_view', 'kitchen_display', 
        'active_orders', 'received_orders', 'recipes'
      ];
      return chefFeatures.contains(feature);
    } else if (_userRole == 'restaurant_waiter') {
      // Waiter access
      final waiterFeatures = [
        'dashboard', 'menu_view', 'tables', 'active_orders', 
        'received_orders', 'reservations', 'customer_notes'
      ];
      return waiterFeatures.contains(feature);
    } else if (_userRole == 'restaurant_cashier') {
      // Cashier access
      final cashierFeatures = [
        'dashboard', 'received_orders', 'active_orders', 
        'payments', 'reconciliation', 'table_orders'
      ];
      return cashierFeatures.contains(feature);
    }
    
    // Default deny if role is unknown
    return false;
  }

List<Widget> getPagesForRole() {
  if (_userRole == 'super_admin' || _userRole == 'developer_admin') {
    return [
      const AdminDashboardPage(),  
      const UsersAdminPage(),    
      const SystemAdminPage(),   
      const SettingsAdminPage(), 
      const ProfilePage(),       
    ];
  } else if (_userRole == 'customer') {
    return [
      const HomePage(),
      const MenuPage(),
      const FavouritesPage(),
      const ProfilePage(),
    ];
  } else if (_userRole == 'restaurant_owner' || _userRole == 'restaurant_manager') {
    // Owner and Manager get full access (5 main tabs)
    return [
      const RestaurantHomePage(),        // Dashboard
      const ReceivedOrdersPage(),        // Orders
      const TableManagementScreen(),             // Tables
      const InventoryManagementPage(),   // Inventory
      const ReportsPage(),               // Reports
    ];
  } else if (_userRole == 'restaurant_chef') {
    // Chef gets access to orders, menu, and inventory
    return [
      const RestaurantHomePage(),        // Dashboard
      const ReceivedOrdersPage(),        // Orders
      const MenuManagementScreen(),       // Menu Management
      const InventoryManagementPage(),   // Inventory (view only)
    ];
  } else if (_userRole == 'restaurant_waiter') {
    // Waiter gets access to orders and tables
    return [
      const RestaurantHomePage(),        // Dashboard
      const ReceivedOrdersPage(),        // Orders
      const TableManagementScreen(),             // Tables
      const RestMenuPage(),          // Take Orders
    ];
  } else if (_userRole == 'restaurant_cashier') {
    // Cashier gets access to orders and payments
    return [
      const RestaurantHomePage(),        // Dashboard
      const ReceivedOrdersPage(),        // Orders
      const PaymentHistoryPage(),        // Payments
      const ReportsPage(),               // Financial Reports
    ];
  } else if (_userRole == 'restaurant_inventory_manager') {
    // Inventory manager focused on stock and reports
    return [
      const RestaurantHomePage(),        // Dashboard
      const InventoryManagementPage(),   // Inventory
      const ReportsPage(),               // Inventory Reports
    ];
  } else {
    // Default to customer pages
    return [
      const HomePage(),
      const MenuPage(),
      const FavouritesPage(),
      const ProfilePage(),
    ];
  }
}
}
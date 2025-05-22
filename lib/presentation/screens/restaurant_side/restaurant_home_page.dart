import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tapeats/presentation/screens/restaurant_side/received_page.dart';
import 'package:tapeats/presentation/screens/restaurant_side/subscription_plan_page.dart';
import 'package:tapeats/presentation/state_management/navbar_state.dart';
import 'package:tapeats/presentation/widgets/footer_widget.dart';
import 'package:tapeats/presentation/widgets/header_widget.dart';
import 'package:tapeats/presentation/widgets/slider_button.dart';
import 'package:tapeats/presentation/widgets/sidemenu_overlay.dart';
import 'package:tapeats/services/subscription_service.dart';

class RestaurantHomePage extends StatefulWidget {
  const RestaurantHomePage({super.key});

  @override
  State<RestaurantHomePage> createState() => _RestaurantHomePageState();
}

class _RestaurantHomePageState extends State<RestaurantHomePage> {
  final SupabaseClient _supabase = Supabase.instance.client;
  final SubscriptionService _subscriptionService = SubscriptionService();

  // Theme colors
  final Color _bgColor = const Color(0xFF151611);
  final Color _secondaryColor = const Color(0xFF222222);
  final Color _accentColor = const Color(0xFFD0F0C0);
  final Color _textColor = const Color(0xFFEEEFED);

  // State variables
  List<Map<String, dynamic>> _tables = [];
  bool _isLoadingTables = true;
  bool _isLoading = true;
  bool _isLoadingStats = true;
  bool _pageLoaded = false; // Fixed: should start as false
  String? _restaurantId;
  String? _userRole;
  Map<String, dynamic>? _subscriptionSummary;
  int _pendingOrders = 0;

  // Stats data
  final Map<String, dynamic> _todayStats = {
    'orders': 0,
    'revenue': 0.0,
    'avgOrder': 0.0,
  };

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    // Get user role first
    await _getUserRole();
    
    // Load data in parallel
    await Future.wait([
      _fetchTodayStats(),
      _fetchTables(),
      _loadSubscriptionStatus(),
      _fetchPendingOrders(),
    ]);

    // Set page as loaded after data is fetched
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _pageLoaded = true;
        });
      }
    });
  }

  Future<void> _getUserRole() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user != null) {
        final userData = await _supabase
            .from('users')
            .select('role')
            .eq('user_id', user.id)
            .single();
        
        setState(() {
          _userRole = userData['role'] as String?;
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error getting user role: $e');
      }
    }
  }

  Future<void> _fetchPendingOrders() async {
    try {
      final response = await _supabase
          .from('orders')
          .select('*')
          .eq('status', 'Received')
          .count();
      
      setState(() {
        _pendingOrders = response.count ?? 0;
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching pending orders: $e');
      }
    }
  }

  Future<void> _loadSubscriptionStatus() async {
    // Only show subscription info for owners and managers
    if (_userRole != 'restaurant_owner' && _userRole != 'restaurant_manager') {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      _restaurantId = await _subscriptionService.getRestaurantIdForUser(user.id);
      
      if (_restaurantId == null) {
        setState(() {
          _subscriptionSummary = _subscriptionService.getSubscriptionSummary(null, null);
        });
        return;
      }

      final subscription = await _subscriptionService.getCurrentSubscription(_restaurantId!);
      final summary = _subscriptionService.getSubscriptionSummary(
        subscription?['plan_id'],
        subscription?['expiry_date'],
      );
      
      setState(() {
        _subscriptionSummary = summary;
      });
      
    } catch (e) {
      if (kDebugMode) {
        print('Error loading subscription status: $e');
      }
      setState(() {
        _subscriptionSummary = _subscriptionService.getSubscriptionSummary(null, null);
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchTables() async {
    // Only fetch tables for roles that need them
    if (!_shouldShowTables()) {
      setState(() {
        _isLoadingTables = false;
      });
      return;
    }

    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      final userResponse = await _supabase
          .from('users')
          .select('restaurant_id')
          .eq('user_id', userId)
          .single();

      if (userResponse['restaurant_id'] == null) return;

      final tablesResponse = await _supabase
          .from('restaurant_tables')
          .select()
          .eq('restaurant_id', userResponse['restaurant_id'])
          .order('table_number');

      setState(() {
        _tables = List<Map<String, dynamic>>.from(tablesResponse);
        _isLoadingTables = false;
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching tables: $e');
      }
      setState(() => _isLoadingTables = false);
    }
  }

  Future<void> _fetchTodayStats() async {
    try {
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);
      final todayEnd = todayStart.add(const Duration(days: 1));

      final response = await _supabase
          .from('orders')
          .select('total_price, order_time')
          .gte('order_time', todayStart.toIso8601String())
          .lt('order_time', todayEnd.toIso8601String());

      if (response.isNotEmpty) {
        final orders = response as List<dynamic>;
        final totalRevenue = orders.fold(0.0,
            (sum, order) => sum + (order['total_price'] as num).toDouble());
        final avgOrder = orders.isNotEmpty ? totalRevenue / orders.length : 0.0;

        setState(() {
          _todayStats['orders'] = orders.length;
          _todayStats['revenue'] = totalRevenue;
          _todayStats['avgOrder'] = avgOrder;
          _isLoadingStats = false;
        });
      } else {
        setState(() {
          _todayStats['orders'] = 0;
          _todayStats['revenue'] = 0.0;
          _todayStats['avgOrder'] = 0.0;
          _isLoadingStats = false;
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching today stats: $e');
      }
      setState(() {
        _isLoadingStats = false;
      });
    }
  }

  // Role-based visibility methods
  bool _shouldShowSubscription() {
    return _userRole == 'restaurant_owner' || _userRole == 'restaurant_manager';
  }

  bool _shouldShowTables() {
    return _userRole == 'restaurant_owner' || 
           _userRole == 'restaurant_manager' || 
           _userRole == 'restaurant_waiter';
  }

  bool _shouldShowFinancials() {
    return _userRole == 'restaurant_owner' || 
           _userRole == 'restaurant_manager' ||
           _userRole == 'restaurant_cashier';
  }

  bool _shouldShowKitchenStats() {
    return _userRole == 'restaurant_chef' || 
           _userRole == 'restaurant_owner' || 
           _userRole == 'restaurant_manager';
  }

  // Get role-specific greeting
  String _getRoleSpecificGreeting() {
    switch (_userRole) {
      case 'restaurant_owner':
        return 'Welcome Back,\nOwner';
      case 'restaurant_manager':
        return 'Manage Your\nRestaurant';
      case 'restaurant_chef':
        return 'Kitchen\nCommand Center';
      case 'restaurant_waiter':
        return 'Service\nDashboard';
      case 'restaurant_cashier':
        return 'Payment\nControl Center';
      case 'restaurant_inventory_manager':
        return 'Inventory\nManagement';
      default:
        return 'Restaurant\nDashboard';
    }
  }

  // Navigation methods
  void _openProfile() {
    // Profile navigation
  }

  void _openSideMenu() {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        pageBuilder: (_, __, ___) => const RoleBasedSideMenu(),
      ),
    );
  }

  void _navigateToSubscription() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SubscriptionPlansPage()),
    );
  }

  void _navigateToOrders() {
    final navbarState = Provider.of<NavbarState>(context, listen: false);
    navbarState.updateIndex(1);
  }

  // Table management
  void _showTableStatusDialog(Map<String, dynamic> table, bool isOccupied, bool isReserved) {
    // Only allow table management for owners, managers, and waiters
    if (!_shouldShowTables()) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Text('Table ${table['table_number']}',
            style: TextStyle(color: _textColor)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text('Occupied',
                  style: TextStyle(color: isOccupied ? Colors.red : _textColor)),
              trailing: isOccupied ? Icon(Iconsax.tick_circle, color: Colors.red) : null,
              onTap: () {
                Navigator.pop(context);
                _updateTableStatus(table, 'occupied');
              },
            ),
            ListTile(
              title: Text('Reserved',
                  style: TextStyle(color: isReserved ? Colors.orange : _textColor)),
              trailing: isReserved ? Icon(Iconsax.tick_circle, color: Colors.orange) : null,
              onTap: () {
                Navigator.pop(context);
                _updateTableStatus(table, 'reserved');
              },
            ),
            ListTile(
              title: Text('Available',
                  style: TextStyle(color: !isOccupied && !isReserved ? Colors.green : _textColor)),
              trailing: !isOccupied && !isReserved ? Icon(Iconsax.tick_circle, color: Colors.green) : null,
              onTap: () {
                Navigator.pop(context);
                _updateTableStatus(table, 'available');
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateTableStatus(Map<String, dynamic> table, String newStatus) async {
    try {
      final updates = {
        'is_reserved': newStatus == 'occupied',
        'is_prebooked': newStatus == 'reserved',
        'updated_at': DateTime.now().toIso8601String(),
      };

      await _supabase
          .from('restaurant_tables')
          .update(updates)
          .eq('table_id', table['table_id']);

      await _fetchTables();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating table: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return PopScope(
      canPop: true,
      child: Scaffold(
        backgroundColor: _bgColor,
        body: SafeArea(
          child: Column(
            children: [
              // Header Section
              HeaderWidget(
                leftIcon: Iconsax.user,
                onLeftButtonPressed: _openProfile,
                headingText: 'Dashboard',
                headingIcon: Iconsax.home,
                rightIcon: Iconsax.menu_1,
                onRightButtonPressed: _openSideMenu,
              ),

              // Main content - Scrollable
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: AnimatedOpacity(
                    opacity: _pageLoaded ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeOut,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Role-specific header
                        _buildRoleSpecificHeader(),

                        // Subscription Status Section (Owner/Manager only)
                        if (_shouldShowSubscription()) _buildSubscriptionSection(),

                        // Today's Overview Section
                        Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: _buildOverviewSection(),
                        ),

                        // Table Status Section (Owner/Manager/Waiter only)
                        if (_shouldShowTables())
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20.0),
                            child: _buildTableStatusSection(),
                          ),

                        // Recent Activity Section
                        Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: _buildActivitySection(),
                        ),

                        const SizedBox(height: 100), // Space for bottom bar
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleSpecificHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20.0, 10.0, 20.0, 20.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left side text - role specific
          Expanded(
            flex: 3,
            child: Text(
              _getRoleSpecificGreeting(),
              style: GoogleFonts.greatVibes(
                color: _textColor,
                fontSize: 42,
                height: 1.1,
              ),
            ),
          ),

          // Right side decorative elements
          Expanded(
            flex: 1,
            child: Stack(
              alignment: Alignment.topRight,
              children: [
                Image.asset(
                  'assets/images/macaroon_1.png',
                  height: 80,
                  width: 80,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubscriptionSection() {
    if (_isLoading) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _secondaryColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(_accentColor),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Loading subscription...',
              style: GoogleFonts.lato(
                color: _textColor,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    if (_subscriptionSummary == null) {
      return const SizedBox.shrink();
    }

    final hasSubscription = _subscriptionSummary!['has_subscription'] as bool;
    final planName = _subscriptionSummary!['plan_name'] as String;
    final status = _subscriptionSummary!['status'] as String;
    final daysRemaining = _subscriptionSummary!['days_remaining'] as int;

    Color statusColor;
    IconData statusIcon;
    String statusText;

    if (hasSubscription) {
      switch (status) {
        case 'active':
          statusColor = _accentColor;
          statusIcon = Iconsax.tick_circle;
          statusText = '$planName Plan';
          break;
        case 'expiring_soon':
          statusColor = Colors.orange;
          statusIcon = Iconsax.warning_2;
          statusText = '$planName Plan (${daysRemaining}d left)';
          break;
        default:
          statusColor = Colors.red;
          statusIcon = Iconsax.close_circle;
          statusText = 'Plan Expired';
      }
    } else {
      statusColor = Colors.orange;
      statusIcon = Iconsax.warning_2;
      statusText = 'No Active Plan';
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
      decoration: BoxDecoration(
        color: _secondaryColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor, width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _navigateToSubscription,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(statusIcon, color: statusColor, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hasSubscription ? 'Your Subscription' : 'Subscription Required',
                        style: GoogleFonts.lato(
                          color: _textColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        statusText,
                        style: GoogleFonts.lato(
                          color: statusColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: hasSubscription ? statusColor.withOpacity(0.1) : _accentColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    hasSubscription ? 'Manage' : 'Subscribe',
                    style: GoogleFonts.lato(
                      color: hasSubscription ? statusColor : Colors.black,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Iconsax.arrow_right_3, color: Colors.grey[400], size: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOverviewSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Iconsax.chart_success, color: _accentColor, size: 20),
            const SizedBox(width: 10),
            Text(
              _getOverviewTitle(),
              style: TextStyle(
                color: _textColor,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontFamily: 'Helvetica Neue',
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _secondaryColor,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Text(
                _getTodayDate(),
                style: TextStyle(
                  color: _textColor,
                  fontSize: 12,
                  fontFamily: 'Helvetica Neue',
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 15),
        _buildRoleSpecificOverviewCards(),
      ],
    );
  }

  String _getOverviewTitle() {
    switch (_userRole) {
      case 'restaurant_chef':
        return "Kitchen Overview";
      case 'restaurant_waiter':
        return "Service Overview";
      case 'restaurant_cashier':
        return "Payment Overview";
      case 'restaurant_inventory_manager':
        return "Inventory Overview";
      default:
        return "Today's Overview";
    }
  }

  Widget _buildRoleSpecificOverviewCards() {
    if (_userRole == 'restaurant_chef') {
      return _buildKitchenOverviewCards();
    } else if (_userRole == 'restaurant_waiter') {
      return _buildWaiterOverviewCards();
    } else if (_userRole == 'restaurant_cashier') {
      return _buildCashierOverviewCards();
    } else if (_userRole == 'restaurant_inventory_manager') {
      return _buildInventoryOverviewCards();
    } else {
      return _buildDefaultOverviewCards();
    }
  }

  Widget _buildDefaultOverviewCards() {
    return Row(
      children: [
        Expanded(
          child: _buildOverviewCard(
            icon: Iconsax.clipboard_text,
            iconColor: _accentColor,
            title: 'Orders',
            value: _isLoadingStats ? '...' : _todayStats['orders'].toString(),
          ),
        ),
        const SizedBox(width: 10),
        if (_shouldShowFinancials()) ...[
          Expanded(
            child: _buildOverviewCard(
              icon: Iconsax.money_recive,
              iconColor: _accentColor,
              title: 'Revenue',
              value: _isLoadingStats ? '...' : '\$${_todayStats['revenue'].toStringAsFixed(2)}',
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _buildOverviewCard(
              icon: Iconsax.chart,
              iconColor: _accentColor,
              title: 'Avg Order',
              value: _isLoadingStats ? '...' : '\$${_todayStats['avgOrder'].toStringAsFixed(2)}',
            ),
          ),
        ] else ...[
          Expanded(
            child: _buildOverviewCard(
              icon: Iconsax.people,
              iconColor: _accentColor,
              title: 'Tables',
              value: _tables.length.toString(),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _buildOverviewCard(
              icon: Iconsax.timer_1,
              iconColor: _accentColor,
              title: 'Pending',
              value: _pendingOrders.toString(),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildKitchenOverviewCards() {
    return Row(
      children: [
        Expanded(
          child: _buildOverviewCard(
            icon: Iconsax.timer_1,
            iconColor: _accentColor,
            title: 'Cooking',
            value: '3', // This would come from actual kitchen data
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildOverviewCard(
            icon: Iconsax.timer_1,
            iconColor: _accentColor,
            title: 'Pending',
            value: _pendingOrders.toString(),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildOverviewCard(
            icon: Iconsax.tick_circle,
            iconColor: _accentColor,
            title: 'Ready',
            value: '1', // This would come from actual kitchen data
          ),
        ),
      ],
    );
  }

  Widget _buildWaiterOverviewCards() {
    return Row(
      children: [
        Expanded(
          child: _buildOverviewCard(
            icon: Iconsax.people,
            iconColor: _accentColor,
            title: 'Tables',
            value: _tables.length.toString(),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildOverviewCard(
            icon: Iconsax.receipt,
            iconColor: _accentColor,
            title: 'Orders',
            value: _pendingOrders.toString(),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildOverviewCard(
            icon: Iconsax.clock,
            iconColor: _accentColor,
            title: 'Avg Time',
            value: '12m', // This would come from actual service data
          ),
        ),
      ],
    );
  }

  Widget _buildCashierOverviewCards() {
    return Row(
      children: [
        Expanded(
          child: _buildOverviewCard(
            icon: Iconsax.money_recive,
            iconColor: _accentColor,
            title: 'Revenue',
            value: _isLoadingStats ? '...' : '\$${_todayStats['revenue'].toStringAsFixed(2)}',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildOverviewCard(
            icon: Iconsax.receipt_2,
            iconColor: _accentColor,
            title: 'Payments',
            value: _isLoadingStats ? '...' : _todayStats['orders'].toString(),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildOverviewCard(
            icon: Iconsax.timer_1,
            iconColor: _accentColor,
            title: 'Pending',
            value: _pendingOrders.toString(),
          ),
        ),
      ],
    );
  }

  Widget _buildInventoryOverviewCards() {
    return Row(
      children: [
        Expanded(
          child: _buildOverviewCard(
            icon: Iconsax.box,
            iconColor: _accentColor,
            title: 'Low Stock',
            value: '5', // This would come from actual inventory data
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildOverviewCard(
            icon: Iconsax.truck,
            iconColor: _accentColor,
            title: 'Deliveries',
            value: '2', // This would come from actual delivery data
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildOverviewCard(
            icon: Iconsax.warning_2,
            iconColor: Colors.orange,
            title: 'Alerts',
            value: '1', // This would come from actual alert data
          ),
        ),
      ],
    );
  }

  Widget _buildOverviewCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_secondaryColor, _secondaryColor.withOpacity(0.9)],
        ),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            offset: const Offset(0, 3),
            blurRadius: 6,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _bgColor,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: iconColor.withOpacity(0.2),
                      blurRadius: 4,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Icon(icon, color: iconColor, size: 16),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: _textColor.withOpacity(0.7),
                    fontSize: 14,
                    fontFamily: 'Helvetica Neue',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              color: _textColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              fontFamily: 'Helvetica Neue',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableStatusSection() {
    List<Map<String, dynamic>> occupiedTables = [];
    List<Map<String, dynamic>> reservedTables = [];
    List<Map<String, dynamic>> availableTables = [];

    for (var table in _tables) {
      if (table['is_reserved'] == true) {
        occupiedTables.add(table);
      } else if (table['is_prebooked'] == true) {
        reservedTables.add(table);
      } else {
        availableTables.add(table);
      }
    }

    final allTables = [...occupiedTables, ...reservedTables, ...availableTables];
    final showScroll = allTables.length > 6;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Iconsax.tag, color: _accentColor, size: 20),
            const SizedBox(width: 10),
            Text(
              "Table Status",
              style: TextStyle(
                color: _textColor,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontFamily: 'Helvetica Neue',
              ),
            ),
            const Spacer(),
            Row(
              children: [
                _buildStatusIndicator('Available', const Color(0xFF66BB6A)),
                const SizedBox(width: 8),
                _buildStatusIndicator('Reserved', const Color(0xFFD0F0C0)),
                const SizedBox(width: 8),
                _buildStatusIndicator('Occupied', const Color(0xFFEF5350)),
              ],
            ),
          ],
        ),
        const SizedBox(height: 15),
        _isLoadingTables
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFFD0F0C0)),
              )
            : allTables.isEmpty
                ? Center(
                    child: Text(
                      'No tables found',
                      style: TextStyle(color: _textColor),
                    ),
                  )
                : SizedBox(
                    height: 300,
                    child: ListView(
                      scrollDirection: showScroll ? Axis.horizontal : Axis.vertical,
                      physics: showScroll ? const BouncingScrollPhysics() : const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      children: [
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                            childAspectRatio: 0.9,
                          ),
                          itemCount: allTables.length,
                          itemBuilder: (context, index) {
                            final table = allTables[index];
                            Color statusColor = const Color(0xFF66BB6A);
                            String status = 'Available';
                            bool isOccupied = false;
                            bool isReserved = false;

                            if (table['is_reserved'] == true) {
                              statusColor = const Color(0xFFEF5350);
                              status = 'Occupied';
                              isOccupied = true;
                            } else if (table['is_prebooked'] == true) {
                              statusColor = const Color(0xFFD0F0C0);
                              status = 'Reserved';
                              isReserved = true;
                            }

                            return GestureDetector(
                              onTap: () => _showTableStatusDialog(table, isOccupied, isReserved),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFF222222),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: statusColor, width: 2),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.2),
                                      offset: const Offset(0, 2),
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'Table ${table['table_number']}',
                                      style: TextStyle(
                                        color: _textColor,
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'Helvetica Neue',
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Seats: ${table['seating_capacity']}',
                                      style: TextStyle(
                                        color: _textColor.withOpacity(0.8),
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF151611),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        status,
                                        style: TextStyle(
                                          color: statusColor,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          fontFamily: 'Helvetica Neue',
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
      ],
    );
  }

  Widget _buildStatusIndicator(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: _textColor.withOpacity(0.7),
            fontSize: 10,
            fontFamily: 'Helvetica Neue',
          ),
        ),
      ],
    );
  }

  Widget _buildActivitySection() {
    // Role-specific activities
    final activities = _getRoleSpecificActivities();

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: _secondaryColor,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            offset: const Offset(0, 3),
            blurRadius: 6,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Iconsax.activity, color: _accentColor, size: 20),
              const SizedBox(width: 10),
              Text(
                _getActivityTitle(),
                style: TextStyle(
                  color: _textColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Helvetica Neue',
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () {
                  // Handle view all action
                },
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(40, 20),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  "View All",
                  style: TextStyle(color: _accentColor, fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          ...activities.map((activity) => _buildActivityItem(activity)).toList(),
        ],
      ),
    );
  }

  String _getActivityTitle() {
    switch (_userRole) {
      case 'restaurant_chef':
        return "Kitchen Activity";
      case 'restaurant_waiter':
        return "Service Activity";
      case 'restaurant_cashier':
        return "Payment Activity";
      case 'restaurant_inventory_manager':
        return "Inventory Activity";
      default:
        return "Recent Activity";
    }
  }

  List<Map<String, dynamic>> _getRoleSpecificActivities() {
    switch (_userRole) {
      case 'restaurant_chef':
        return [
          {
            'time': '2 min ago',
            'text': 'Order #1003 ready to serve',
            'icon': Iconsax.tick_circle,
            'color': Colors.green
          },
          {
            'time': '5 min ago',
            'text': 'New order received - Table 3',
            'icon': Iconsax.receipt_add,
            'color': _accentColor
          },
          {
            'time': '12 min ago',
            'text': 'Ingredient alert: Low tomatoes',
            'icon': Iconsax.warning_2,
            'color': Colors.orange
          },
        ];
      case 'restaurant_waiter':
        return [
          {
            'time': '1 min ago',
            'text': 'Table 4 requested service',
            'icon': Iconsax.call,
            'color': _accentColor
          },
          {
            'time': '8 min ago',
            'text': 'Order delivered to Table 2',
            'icon': Iconsax.tick_square,
            'color': Colors.green
          },
          {
            'time': '15 min ago',
            'text': 'Table 6 reservation confirmed',
            'icon': Iconsax.calendar_tick,
            'color': _accentColor
          },
        ];
      case 'restaurant_cashier':
        return [
          {
            'time': '3 min ago',
            'text': 'Payment received - Table 1 (\$45.80)',
            'icon': Iconsax.money_recive,
            'color': Colors.green
          },
          {
            'time': '10 min ago',
            'text': 'Cash payment - Table 5 (\$32.50)',
            'icon': Iconsax.money,
            'color': _accentColor
          },
          {
            'time': '20 min ago',
            'text': 'Daily reconciliation completed',
            'icon': Iconsax.document_1,
            'color': _accentColor
          },
        ];
      case 'restaurant_inventory_manager':
        return [
          {
            'time': '30 min ago',
            'text': 'Stock delivery received',
            'icon': Iconsax.truck,
            'color': Colors.green
          },
          {
            'time': '1 hour ago',
            'text': 'Low stock alert: Chicken breast',
            'icon': Iconsax.warning_2,
            'color': Colors.orange
          },
          {
            'time': '2 hours ago',
            'text': 'Inventory count updated',
            'icon': Iconsax.box,
            'color': _accentColor
          },
        ];
      default:
        return [
          {
            'time': '5 min ago',
            'text': 'New order received for Table 3',
            'icon': Iconsax.receipt_add,
            'color': _accentColor
          },
          {
            'time': '15 min ago',
            'text': 'Order #1002 marked as ready',
            'icon': Iconsax.tick_square,
            'color': _accentColor
          },
          {
            'time': '30 min ago',
            'text': 'Payment received for order #1001',
            'icon': Iconsax.money_recive,
            'color': _accentColor
          },
        ];
    }
  }

  Widget _buildActivityItem(Map<String, dynamic> activity) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _bgColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              activity['icon'] as IconData,
              color: activity['color'] as Color,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity['text'] as String,
                  style: TextStyle(
                    color: _textColor,
                    fontSize: 14,
                    fontFamily: 'Helvetica Neue',
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  activity['time'] as String,
                  style: TextStyle(
                    color: _textColor.withOpacity(0.5),
                    fontSize: 12,
                    fontFamily: 'Helvetica Neue',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getTodayDate() {
    final now = DateTime.now();
    return "${now.day} ${_getMonthName(now.month)}, ${now.year}";
  }

  String _getMonthName(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month - 1];
  }
}
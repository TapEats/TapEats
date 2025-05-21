import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tapeats/presentation/widgets/header_widget.dart';
import 'package:tapeats/presentation/state_management/navbar_state.dart';
import 'package:tapeats/presentation/widgets/sidemenu_overlay.dart';
import 'package:tapeats/presentation/screens/admin/users_admin_page.dart';
import 'package:tapeats/presentation/screens/admin/system_admin_page.dart';
import 'package:tapeats/presentation/screens/admin/settings_admin_page.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> with SingleTickerProviderStateMixin {
  final SupabaseClient _supabase = Supabase.instance.client;
  bool _isLoading = false;
  String? _error;
  
  // Stats summary
  int _totalUsers = 0;
  int _totalRestaurants = 0;
  int _activeOrders = 0;
  int _pendingVerifications = 0;
  double _weeklyRevenue = 0;
  
  // Recent activity feed
  List<Map<String, dynamic>> _recentActivity = [];

  // Theme colors
  final Color _bgColor = const Color(0xFF151611);
  final Color _cardColor = const Color(0xFF1A1A1A);
  final Color _accentColor = const Color(0xFFD0F0C0);
  final Color _textColor = const Color(0xFFEEEFEF);
  final Color _secondaryColor = const Color(0xFF222222);

  @override
  void initState() {
    super.initState();
    
    // Ensure the right tab is selected in NavbarState
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final navbarState = Provider.of<NavbarState>(context, listen: false);
      if (navbarState.userRole?.contains('admin') == true) {
        navbarState.updateIndex(0);
      }
    });
    
    _loadDashboardData();
  }

  void _openSideMenu() {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        pageBuilder: (_, __, ___) => const RoleBasedSideMenu(),
      ),
    );
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Load all data in parallel
      await Future.wait([
        _loadStatistics(),
        _loadRecentActivity(),
      ]);
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Error loading dashboard data: $e';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadStatistics() async {
    try {
      // Get count of users
      final usersCount = await _supabase
          .from('users')
          .select('*')
          .count();
      
      // Get count of restaurants 
      final restaurantsCount = await _supabase
          .from('restaurants')
          .select('*')
          .count();
      
      // Get count of active orders
      final ordersCount = await _supabase
          .from('orders')
          .select('*')
          .eq('status', 'Received')
          .count();
          
      // Get count of pending verifications
      final verificationsCount = await _supabase
          .from('verification_requests')
          .select('*')
          .eq('status', 'pending')
          .count();
      
      // Calculate weekly revenue (sample data)
      final weeklyRevenue = 5842.75; // This would normally be calculated from orders table
      
      if (mounted) {
        setState(() {
          _totalUsers = usersCount.count ?? 0;
          _totalRestaurants = restaurantsCount.count ?? 0;
          _activeOrders = ordersCount.count ?? 0;
          _pendingVerifications = verificationsCount.count ?? 0;
          _weeklyRevenue = weeklyRevenue;
        });
      }
    } catch (e) {
      debugPrint('Error loading statistics: $e');
      // Don't set error state as this is not critical
    }
  }

  Future<void> _loadRecentActivity() async {
    try {
      // Fetch recent activities (e.g., new users, new orders, etc.)
      // For demonstration purposes, we'll load recent orders
      final recentOrders = await _supabase
          .from('orders')
          .select('username, order_id, status, order_time, total_price')
          .order('order_time', ascending: false)
          .limit(5);
      
      // Create activity items from these orders
      List<Map<String, dynamic>> activities = [];
      for (var order in recentOrders) {
        activities.add({
          'type': 'order',
          'title': 'Order #${order['order_id']} ${order['status']}',
          'details': '${order['username']} - \$${order['total_price']}',
          'timestamp': DateTime.parse(order['order_time']),
          'iconData': Iconsax.receipt_2,
        });
      }
      
      // Add a sample verification activity if we have any pending verifications
      if (_pendingVerifications > 0) {
        activities.add({
          'type': 'verification',
          'title': 'New Restaurant Verification',
          'details': 'Restaurant application pending approval',
          'timestamp': DateTime.now().subtract(const Duration(hours: 3)),
          'iconData': Iconsax.verify,
        });
      }
      
      // Sort by timestamp
      activities.sort((a, b) => 
        (b['timestamp'] as DateTime).compareTo(a['timestamp'] as DateTime));
      
      if (mounted && activities.isNotEmpty) {
        setState(() {
          _recentActivity = activities;
        });
      }
    } catch (e) {
      debugPrint('Error loading recent activity: $e');
    }
  }

  // Navigate to specific admin pages
  void _navigateToUsersAdmin() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const UsersAdminPage()),
    );
  }
  
  void _navigateToSystemAdmin() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SystemAdminPage()),
    );
  }
  
  void _navigateToSettingsAdmin() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SettingsAdminPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            HeaderWidget(
              leftIcon: Iconsax.refresh,
              onLeftButtonPressed: _loadDashboardData,
              headingText: "Admin Dashboard",
              headingIcon: Iconsax.security_user,
              rightIcon: Iconsax.menu_1,
              onRightButtonPressed: _openSideMenu,
            ),
            
            // Loading indicator
            if (_isLoading)
              LinearProgressIndicator(
                backgroundColor: _secondaryColor,
                valueColor: AlwaysStoppedAnimation<Color>(_accentColor),
              ),
            
            // Error message  
            if (_error != null)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.withAlpha(50),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Iconsax.warning_2, color: Colors.red),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _error!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),
            
            // Main dashboard content
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadDashboardData,
                color: _accentColor,
                backgroundColor: _secondaryColor,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Welcome message
                      _buildWelcomeSection(),
                      const SizedBox(height: 20),
                      
                      // Statistics Cards
                      _buildStatisticsGrid(),
                      const SizedBox(height: 24),
                      
                      // Quick Actions
                      _buildQuickActionsSection(),
                      const SizedBox(height: 24),
                      
                      // Recent Activity
                      _buildRecentActivitySection(),
                      const SizedBox(height: 40),
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

  Widget _buildWelcomeSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            flex: 4,
            child: Text(
              'What’s Happening Today',
              style: GoogleFonts.greatVibes(
                color: const Color(0xFFEEEFEF),
                fontSize: 48,
              ),
              textAlign: TextAlign.left,
            ),
          ),
          Expanded(
            flex: 1,
            child: Image.asset(
              'assets/images/macaroon_1.png', // Path to the macaroon image
              fit: BoxFit.contain,
              height: 100,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsGrid() {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _buildStatCard(
          title: 'Total Users',
          value: _totalUsers.toString(),
          icon: Iconsax.user,
          color: Colors.blueAccent,
        ),
        _buildStatCard(
          title: 'Restaurants',
          value: _totalRestaurants.toString(),
          icon: Iconsax.shop,
          color: Colors.deepPurpleAccent,
        ),
        _buildStatCard(
          title: 'Active Orders',
          value: _activeOrders.toString(),
          icon: Iconsax.receipt_2,
          color: Colors.orangeAccent,
        ),
        _buildStatCard(
          title: 'Weekly Revenue',
          value: '\$${_weeklyRevenue.toStringAsFixed(2)}',
          icon: Iconsax.money_recive,
          color: Colors.greenAccent,
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              value,
              style: GoogleFonts.lato(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: _textColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: GoogleFonts.lato(
                fontSize: 14,
                color: _textColor.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: GoogleFonts.lato(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: _accentColor,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                title: 'User Management',
                icon: Iconsax.user_edit,
                onTap: _navigateToUsersAdmin,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionButton(
                title: 'System Status',
                icon: Iconsax.cpu,
                onTap: _navigateToSystemAdmin,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                title: 'Settings',
                icon: Iconsax.setting,
                onTap: _navigateToSettingsAdmin,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionButton(
                title: 'Verifications',
                icon: Iconsax.verify,
                badge: _pendingVerifications > 0 ? _pendingVerifications.toString() : null,
                onTap: () {
                  // Navigate to verification page (not implemented yet)
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Verification page coming soon')),
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
    String? badge,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        decoration: BoxDecoration(
          color: _cardColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Stack(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _secondaryColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: _accentColor,
                    size: 20,
                  ),
                ),
                if (badge != null)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        badge,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.lato(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: _textColor,
                ),
              ),
            ),
            Icon(
              Iconsax.arrow_right_3,
              color: _textColor.withOpacity(0.5),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivitySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Activity',
          style: GoogleFonts.lato(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: _accentColor,
          ),
        ),
        const SizedBox(height: 16),
        if (_recentActivity.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Text(
                'No recent activity found',
                style: TextStyle(color: _textColor.withOpacity(0.7)),
              ),
            ),
          )
        else
          Container(
            decoration: BoxDecoration(
              color: _cardColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _recentActivity.length,
              itemBuilder: (context, index) {
                final activity = _recentActivity[index];
                return _buildActivityItem(
                  icon: activity['iconData'] as IconData,
                  title: activity['title'] as String,
                  subtitle: activity['details'] as String,
                  time: _formatTimestamp(activity['timestamp'] as DateTime),
                  isLast: index == _recentActivity.length - 1,
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildActivityItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required String time,
    bool isLast = false,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _secondaryColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: _accentColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.lato(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: _textColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: GoogleFonts.lato(
                    fontSize: 12,
                    color: _textColor.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  time,
                  style: GoogleFonts.lato(
                    fontSize: 10,
                    color: _textColor.withOpacity(0.5),
                  ),
                ),
                if (!isLast) ...[
                  const SizedBox(height: 16),
                  Divider(color: _secondaryColor, height: 1),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inSeconds < 60) {
      return 'just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} min ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }
}
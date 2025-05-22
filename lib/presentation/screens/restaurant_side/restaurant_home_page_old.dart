import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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
  final Color _bgColor = const Color(0xFF151611);     // Background
  final Color _secondaryColor = const Color(0xFF222222); // Secondary
  final Color _accentColor = const Color(0xFFD0F0C0);  // Accent
  final Color _textColor = const Color(0xFFEEEFED);   // Text
  
  // Data states
  bool _isLoading = true;
  String? _restaurantId;
  Map<String, dynamic>? _subscriptionSummary;
  
  // Sample data for dashboard
  final List<Map<String, dynamic>> _tableStatus = [
    {'number': 1, 'status': 'Available', 'color': const Color(0xFF66BB6A)},
    {'number': 2, 'status': 'Occupied', 'color': const Color(0xFFFFA726)},
    {'number': 3, 'status': 'Reserved', 'color': const Color(0xFF42A5F5)},
    {'number': 4, 'status': 'Available', 'color': const Color(0xFF66BB6A)},
    {'number': 5, 'status': 'Occupied', 'color': const Color(0xFFFFA726)},
    {'number': 6, 'status': 'Available', 'color': const Color(0xFF66BB6A)},
  ];

  final Map<String, dynamic> _todayStats = {
    'orders': 24,
    'revenue': 1450.75,
    'avgOrder': 60.45,
  };

  // Animation state
  bool _pageLoaded = true;

  @override
  void initState() {
    super.initState();
    _initializeData();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _pageLoaded = true;
        });
      }
    });
  }

  Future<void> _initializeData() async {
    await _loadSubscriptionStatus();
  }

  Future<void> _loadSubscriptionStatus() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        print('❌ No user logged in');
        return;
      }

      // Get restaurant ID
      _restaurantId = await _subscriptionService.getRestaurantIdForUser(user.id);
      print('🏪 Restaurant ID: $_restaurantId');
      
      if (_restaurantId == null) {
        print('❌ No restaurant found for user');
        setState(() {
          _subscriptionSummary = _subscriptionService.getSubscriptionSummary(null, null);
        });
        return;
      }

      // Get current subscription
      final subscription = await _subscriptionService.getCurrentSubscription(_restaurantId!);
      print('💳 Subscription data: $subscription');
      
      // Generate subscription summary
      final summary = _subscriptionService.getSubscriptionSummary(
        subscription?['plan_id'],
        subscription?['expiry_date'],
      );
      
      print('📊 Subscription summary: $summary');
      
      setState(() {
        _subscriptionSummary = summary;
      });
      
    } catch (e) {
      print('❌ Error loading subscription status: $e');
      setState(() {
        _subscriptionSummary = _subscriptionService.getSubscriptionSummary(null, null);
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

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
            crossAxisAlignment: CrossAxisAlignment.stretch,
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
                child: RefreshIndicator(
                  onRefresh: _loadSubscriptionStatus,
                  color: _accentColor,
                  backgroundColor: _secondaryColor,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: AnimatedOpacity(
                      opacity: _pageLoaded ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeOut,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Elegant header
                          _buildElegantHeader(),
                          
                          // Subscription Status Section
                          _buildSubscriptionSection(),
                          
                          // Today's Overview Section
                          Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: _buildOverviewSection(),
                          ),
                          
                          // Table Status Section
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
              ),
            ],
          ),
        ),
        floatingActionButton: Padding(
          padding: const EdgeInsets.only(bottom: 70.0),
          child: SliderButton(
            labelText: 'Orders',
            subText: '2 received',
            onSlideComplete: () {
              // Update NavbarState index directly instead of pushing new route
              final navbarState = Provider.of<NavbarState>(context, listen: false);
              navbarState.updateIndex(1); // Navigate to index 1 (Received Orders page)
            },
            pageId: 'restaurant_orders',
          ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        extendBody: true,
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
        border: Border.all(
          color: statusColor,
          width: 1,
        ),
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
                Icon(
                  statusIcon,
                  color: statusColor,
                  size: 20,
                ),
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
                Icon(
                  Iconsax.arrow_right_3,
                  color: Colors.grey[400],
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildElegantHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20.0, 10.0, 20.0, 20.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left side text
          Expanded(
            flex: 3,
            child: Text(
              'Serve Your\nSignature\nExperience',
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
                // Macaroon image
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

  Widget _buildOverviewSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Iconsax.chart_success,
              color: _accentColor,
              size: 20,
            ),
            const SizedBox(width: 10),
            Text(
              "Today's Overview",
              style: TextStyle(
                color: _textColor,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontFamily: 'Helvetica Neue',
              ),
            ),
            const Spacer(),
            // Date display
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
        _buildOverviewCards(),
      ],
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

  Widget _buildOverviewCards() {
    return Row(
      children: [
        // Orders Card
        Expanded(
          child: _buildOverviewCard(
            icon: Iconsax.clipboard_text,
            iconColor: _accentColor,
            title: 'Orders',
            value: _todayStats['orders'].toString(),
          ),
        ),
        const SizedBox(width: 15),
        // Revenue Card
        Expanded(
          child: _buildOverviewCard(
            icon: Iconsax.money_recive,
            iconColor: _accentColor,
            title: 'Revenue',
            value: '\$${_todayStats['revenue']}',
          ),
        ),
        const SizedBox(width: 15),
        // Avg Order Card
        Expanded(
          child: _buildOverviewCard(
            icon: Iconsax.chart,
            iconColor: _accentColor,
            title: 'Avg Order',
            value: '\$${_todayStats['avgOrder']}',
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
          colors: [
            _secondaryColor,
            _secondaryColor.withOpacity(0.9),
          ],
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
              Text(
                title,
                style: TextStyle(
                  color: _textColor.withOpacity(0.7),
                  fontSize: 14,
                  fontFamily: 'Helvetica Neue',
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Iconsax.tag,
              color: _accentColor,
              size: 20,
            ),
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
            // Status indicators
            Row(
              children: [
                _buildStatusIndicator('Available', const Color(0xFF66BB6A)),
                const SizedBox(width: 8),
                _buildStatusIndicator('Occupied', const Color(0xFFFFA726)),
                const SizedBox(width: 8),
                _buildStatusIndicator('Reserved', const Color(0xFF42A5F5)),
              ],
            ),
          ],
        ),
        const SizedBox(height: 15),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1,
          ),
          itemCount: _tableStatus.length,
          itemBuilder: (context, index) {
            final table = _tableStatus[index];
            return Container(
              decoration: BoxDecoration(
                color: _secondaryColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: table['color'],
                  width: 2,
                ),
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
                    table['number'].toString(),
                    style: TextStyle(
                      color: _textColor,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Helvetica Neue',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _bgColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      table['status'],
                      style: TextStyle(
                        color: table['color'],
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Helvetica Neue',
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
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
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
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
    // Sample activity items
    final activities = [
      {'time': '5 min ago', 'text': 'New order received for Table 3', 'icon': Iconsax.receipt_add, 'color': _accentColor},
      {'time': '15 min ago', 'text': 'Order #1002 marked as ready', 'icon': Iconsax.tick_square, 'color': _accentColor},
      {'time': '30 min ago', 'text': 'Payment received for order #1001', 'icon': Iconsax.money_recive, 'color': _accentColor},
    ];
    
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
              Icon(
                Iconsax.activity,
                color: _accentColor,
                size: 20,
              ),
              const SizedBox(width: 10),
              Text(
                "Recent Activity",
                style: TextStyle(
                  color: _textColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Helvetica Neue',
                ),
              ),
              const Spacer(),
              // View all button
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
                  style: TextStyle(
                    color: _accentColor,
                    fontSize: 12,
                  ),
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
}
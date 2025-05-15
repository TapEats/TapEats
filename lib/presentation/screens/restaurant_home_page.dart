import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:tapeats/presentation/screens/received_page.dart';
import 'package:tapeats/presentation/state_management/navbar_state.dart';
import 'package:tapeats/presentation/widgets/custom_footer_five_button_widget.dart';
import 'package:tapeats/presentation/widgets/footer_widget.dart';
import 'package:tapeats/presentation/widgets/header_widget.dart';
import 'package:tapeats/presentation/widgets/slider_button.dart';
import 'package:tapeats/presentation/widgets/sidemenu_overlay.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tapeats/presentation/state_management/slider_state.dart';

class RestaurantHomePage extends StatefulWidget {
  final int selectedIndex;

  const RestaurantHomePage({super.key, required this.selectedIndex});

  @override
  State<RestaurantHomePage> createState() => _RestaurantHomePageState();
}

class _RestaurantHomePageState extends State<RestaurantHomePage> {
  // Theme colors
  final Color _bgColor = const Color(0xFF151611); // Background
  final Color _secondaryColor = const Color(0xFF222222); // Secondary
  final Color _accentColor = const Color(0xFFD0F0C0); // Accent
  final Color _textColor = const Color(0xFFEEEFED); // Text
  List<Map<String, dynamic>> _tables = [];
  bool _isLoadingTables = true;

  // Sample data for dashboard
  final List<Map<String, dynamic>> _tableStatus = [
    {
      'number': 1,
      'status': 'Available',
      'color': const Color(0xFF66BB6A)
    }, // Green
    {
      'number': 2,
      'status': 'Occupied',
      'color': const Color(0xFFFFA726)
    }, // Orange
    {
      'number': 3,
      'status': 'Reserved',
      'color': const Color(0xFF42A5F5)
    }, // Blue
    {
      'number': 4,
      'status': 'Available',
      'color': const Color(0xFF66BB6A)
    }, // Green
    {
      'number': 5,
      'status': 'Occupied',
      'color': const Color(0xFFFFA726)
    }, // Orange
    {
      'number': 6,
      'status': 'Available',
      'color': const Color(0xFF66BB6A)
    }, // Green
  ];

  final SupabaseClient supabase = Supabase.instance.client;
  final Map<String, dynamic> _todayStats = {
    'orders': 0,
    'revenue': 0.0,
    'avgOrder': 0.0,
  };
  bool _isLoadingStats = true;

  // Animation state
  bool _pageLoaded = false;

  @override
  void initState() {
    super.initState();
    _fetchTodayStats();
    _fetchTables();
    // Set the initial index in the NavbarState
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final navbarState = Provider.of<NavbarState>(context, listen: false);
      navbarState.updateIndex(widget.selectedIndex);

      // Set page as loaded after a short delay
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          setState(() {
            _pageLoaded = true;
          });
        }
      });
    });
  }

  void _showTableStatusDialog(
      Map<String, dynamic> table, bool isOccupied, bool isReserved) {
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
                  style:
                      TextStyle(color: isOccupied ? Colors.red : _textColor)),
              trailing: isOccupied
                  ? Icon(Iconsax.tick_circle, color: Colors.red)
                  : null,
              onTap: () {
                Navigator.pop(context);
                _updateTableStatus(table, 'occupied');
              },
            ),
            ListTile(
              title: Text('Reserved',
                  style: TextStyle(
                      color: isReserved ? Colors.orange : _textColor)),
              trailing: isReserved
                  ? Icon(Iconsax.tick_circle, color: Colors.orange)
                  : null,
              onTap: () {
                Navigator.pop(context);
                _updateTableStatus(table, 'reserved');
              },
            ),
            ListTile(
              title: Text('Available',
                  style: TextStyle(
                      color: !isOccupied && !isReserved
                          ? Colors.green
                          : _textColor)),
              trailing: !isOccupied && !isReserved
                  ? Icon(Iconsax.tick_circle, color: Colors.green)
                  : null,
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

  Future<void> _updateTableStatus(
      Map<String, dynamic> table, String newStatus) async {
    try {
      final updates = {
        'is_reserved': newStatus == 'occupied',
        'is_prebooked': newStatus == 'reserved',
        'updated_at': DateTime.now().toIso8601String(),
      };

      await supabase
          .from('restaurant_tables')
          .update(updates)
          .eq('table_id', table['table_id']);

      // Refresh the table data
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

  Future<void> _fetchTables() async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;

      final userResponse = await supabase
          .from('users')
          .select('restaurant_id')
          .eq('user_id', userId)
          .single();

      if (userResponse['restaurant_id'] == null) return;

      final tablesResponse = await supabase
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

  void _openProfile() {
    // Profile navigation
  }
  Future<void> _fetchTodayStats() async {
    try {
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);
      final todayEnd = todayStart.add(const Duration(days: 1));

      final response = await supabase
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

  void _openSideMenu() {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        pageBuilder: (_, __, ___) => const RoleBasedSideMenu(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                      // Elegant header
                      _buildElegantHeader(),

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
          ],
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 15.0),
        child: SliderButton(
          labelText: 'Orders',
          subText: '2 received',
          onSlideComplete: () {
            // Handle slide to view orders
            final navbarState =
                Provider.of<NavbarState>(context, listen: false);
            navbarState.updateIndex(1); // Navigate to Orders tab

            Navigator.pushReplacement(
              context,
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) =>
                    const ReceivedOrdersPage(selectedIndex: 1),
                transitionDuration: const Duration(milliseconds: 150),
              ),
            );
          },
          pageId: 'restaurant_orders',
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      extendBody: true,
      bottomNavigationBar: CustomFiveFooter(
        selectedIndex: widget.selectedIndex,
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
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return months[month - 1];
  }

  Widget _buildOverviewCards() {
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
        Expanded(
          child: _buildOverviewCard(
            icon: Iconsax.money_recive,
            iconColor: _accentColor,
            title: 'Revenue',
            value: _isLoadingStats
                ? '...'
                : '\$${_todayStats['revenue'].toStringAsFixed(2)}',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildOverviewCard(
            icon: Iconsax.chart,
            iconColor: _accentColor,
            title: 'Avg Order',
            value: _isLoadingStats
                ? '...'
                : '\$${_todayStats['avgOrder'].toStringAsFixed(2)}',
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
    // Categorize tables based on status
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

    final allTables = [
      ...occupiedTables,
      ...reservedTables,
      ...availableTables
    ];
    final showScroll = allTables.length > 6;

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
                child: CircularProgressIndicator(
                  color: Color(0xFFD0F0C0),
                ),
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
                      scrollDirection:
                          showScroll ? Axis.horizontal : Axis.vertical,
                      physics: showScroll
                          ? const BouncingScrollPhysics()
                          : const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      children: [
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
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
                              onTap: () => _showTableStatusDialog(
                                  table, isOccupied, isReserved),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFF222222),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: statusColor,
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
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 4),
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
          ...activities
              .map((activity) => _buildActivityItem(activity))
              .toList(),
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

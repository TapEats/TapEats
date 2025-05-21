import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tapeats/presentation/widgets/header_widget.dart';
import 'package:tapeats/presentation/widgets/sidemenu_overlay.dart';

class SystemAdminPage extends StatefulWidget {
  const SystemAdminPage({super.key});

  @override
  State<SystemAdminPage> createState() => _SystemAdminPageState();
}

class _SystemAdminPageState extends State<SystemAdminPage> {
  final SupabaseClient _supabase = Supabase.instance.client;
  bool _isLoading = false;
  String? _error;

  // Stats
  int _totalUsers = 0;
  int _totalRestaurants = 0;
  int _activeOrders = 0;
  
  // Users by role stats
  Map<String, int> _userRoleCounts = {};
  
  // System status
  bool _verificationTableExists = false;
  bool _databaseConnected = true;
  String _appVersion = '1.0.0';

  @override
  void initState() {
    super.initState();
    _loadSystemData();
  }
  
  Future<void> _loadSystemData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    
    try {
      // Run all data loading in parallel
      await Future.wait([
        _loadStats(),
        _checkVerificationTable(),
        _loadUserRoleStats(),
      ]);
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Error loading system data: $e';
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
  
  Future<void> _loadStats() async {
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
      
      if (mounted) {
        setState(() {
          _totalUsers = usersCount.count ?? 0;
          _totalRestaurants = restaurantsCount.count ?? 0;
          _activeOrders = ordersCount.count ?? 0;
        });
      }
    } catch (e) {
      debugPrint('Error loading stats: $e');
      // Don't set error state as this is not critical
    }
  }
  
  Future<void> _loadUserRoleStats() async {
    try {
      final users = await _supabase
          .from('users')
          .select('role');
      
      // Count users by role
      Map<String, int> roleCounts = {};
      
      for (var user in users) {
        final role = user['role'] as String?;
        if (role != null) {
          roleCounts[role] = (roleCounts[role] ?? 0) + 1;
        }
      }
      
      if (mounted) {
        setState(() {
          _userRoleCounts = roleCounts;
        });
      }
    } catch (e) {
      debugPrint('Error loading user role stats: $e');
    }
  }
  
  Future<void> _checkVerificationTable() async {
    try {
      // Check if verification_requests table exists
      final response = await _supabase.rpc(
        'check_table_exists',
        params: {'input_table_name': 'verification_requests'},
      );
      
      if (mounted) {
        setState(() {
          _verificationTableExists = response as bool? ?? false;
        });
      }
    } catch (e) {
      // Table doesn't exist or can't verify
      if (mounted) {
        setState(() {
          _verificationTableExists = false;
        });
      }
    }
  }
  
  Future<void> _createVerificationTable() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    
    try {
      // Execute SQL to create the verification_requests table
      await _supabase.rpc('create_verification_table');
      
      // Refresh the table status
      await _checkVerificationTable();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Verification table created successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Error creating table: $e';
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating table: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
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
      backgroundColor: const Color(0xFF151611),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Column(
            children: [
              // Header
              HeaderWidget(
                leftIcon: Iconsax.refresh,
                onLeftButtonPressed: _loadSystemData,
                headingText: "System Dashboard",
                rightIcon: Iconsax.menu_1,
                onRightButtonPressed: _openSideMenu,
              ),
              
              // Loading indicator
              if (_isLoading)
                const LinearProgressIndicator(
                  backgroundColor: Color(0xFF222222),
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFD0F0C0)),
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
                
              SizedBox(height: 16),  
              // Stats overview
              _buildStatsOverview(),
              
              // Main content area
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // System Status Card
                    _buildSystemStatusCard(),
                    
                    const SizedBox(height: 16),
                    
                    // User Statistics Card
                    _buildUserStatsCard(),
                    
                    const SizedBox(height: 16),
                    
                    // Admin Actions Card
                    _buildAdminActionsCard(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildStatsOverview() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      color: const Color(0xFF222222),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('Users', _totalUsers.toString(), Iconsax.user),
          _buildStatItem('Restaurants', _totalRestaurants.toString(), Iconsax.shop),
          _buildStatItem('Active Orders', _activeOrders.toString(), Iconsax.timer_1),
        ],
      ),
    );
  }
  
  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF151611),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: const Color(0xFFD0F0C0),
            size: 24,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Color(0xFFEEEFEF),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFFEEEFEF),
            fontSize: 12,
          ),
        ),
      ],
    );
  }
  
  Widget _buildSystemStatusCard() {
    return Card(
      color: const Color(0xFF1A1A1A),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'System Status',
              style: TextStyle(
                color: Color(0xFFD0F0C0),
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            _buildStatusItem('Database Connection', 'Connected', Colors.green),
            _buildStatusItem('Authentication', 'Active', Colors.green),
            _buildStatusItem(
              'Verification Table', 
              _verificationTableExists ? 'Available' : 'Not Found', 
              _verificationTableExists ? Colors.green : Colors.red
            ),
            _buildStatusItem('App Version', _appVersion, Colors.blue),
          ],
        ),
      ),
    );
  }
  
  Widget _buildUserStatsCard() {
    return Card(
      color: const Color(0xFF1A1A1A),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'User Statistics',
              style: TextStyle(
                color: Color(0xFFD0F0C0),
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // User role distribution
            ..._userRoleCounts.entries.map((entry) {
              final percentage = _totalUsers > 0 ? (entry.value / _totalUsers * 100) : 0;
              
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          entry.key,
                          style: const TextStyle(
                            color: Color(0xFFEEEFEF),
                            fontFamily: 'Helvetica Neue',
                          ),
                        ),
                        Text(
                          '${entry.value} (${percentage.toStringAsFixed(0)}%)',
                          style: const TextStyle(
                            color: Color(0xFFEEEFEF),
                            fontFamily: 'Helvetica Neue',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Progress bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: _totalUsers > 0 ? entry.value / _totalUsers : 0,
                        minHeight: 8,
                        backgroundColor: const Color(0xFF151611),
                        valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFD0F0C0)),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
  
  Widget _buildAdminActionsCard() {
    return Card(
      color: const Color(0xFF1A1A1A),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Admin Actions',
              style: TextStyle(
                color: Color(0xFFD0F0C0),
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Create Verification Table button
            if (!_verificationTableExists)
              _buildActionButton(
                'Create Verification Table',
                Iconsax.add,
                _createVerificationTable,
              ),
              
            // Export User Data button
            _buildActionButton(
              'Export User Data',
              Iconsax.export_1,
              () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Export feature coming soon'),
                    backgroundColor: Colors.blue,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildStatusItem(String service, String status, Color statusColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              service,
              style: const TextStyle(
                color: Color(0xFFEEEFEF),
                fontFamily: 'Helvetica Neue',
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: statusColor.withAlpha(50),
              borderRadius: BorderRadius.circular(10),
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
    );
  }
  
  Widget _buildActionButton(String title, IconData icon, VoidCallback onPressed) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: SizedBox(
        width: double.infinity,
        child: TextButton.icon(
          icon: Icon(icon, color: const Color(0xFFEEEFEF)),
          label: Text(
            title,
            style: const TextStyle(color: Color(0xFFEEEFEF)),
          ),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12),
            alignment: Alignment.centerLeft,
            backgroundColor: const Color(0xFF151611),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          onPressed: onPressed,
        ),
      ),
    );
  }
}
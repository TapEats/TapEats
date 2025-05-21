import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tapeats/presentation/widgets/header_widget.dart';
import 'package:tapeats/presentation/widgets/sidemenu_overlay.dart';

class UsersAdminPage extends StatefulWidget {
  const UsersAdminPage({super.key});

  @override
  State<UsersAdminPage> createState() => _UsersAdminPageState();
}

class _UsersAdminPageState extends State<UsersAdminPage> {
  final SupabaseClient _supabase = Supabase.instance.client;
  bool _isLoading = false;
  String? _error;
  
  // User management
  List<Map<String, dynamic>> _users = [];
  // Restaurant data mapping (user_id -> restaurant name)
  Map<String, String> _restaurantNames = {};
  
  String _searchQuery = '';
  String _roleFilter = 'All';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Load users and restaurant data in parallel
      await Future.wait([
        _loadUsers(),
        _loadRestaurantData(),
      ]);
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Error loading data: $e';
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

  Future<void> _loadUsers() async {
    try {
      final response = await _supabase
          .from('users')
          .select('user_id, email, username, role, created_at, phone_number')
          .order('created_at', ascending: false);
      
      if (mounted) {
        setState(() {
          _users = List<Map<String, dynamic>>.from(response);
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Error loading users: $e';
        });
      }
    }
  }

  Future<void> _loadRestaurantData() async {
    try {
      final response = await _supabase
          .from('restaurants')
          .select('owner_id, name');
      
      // Create mapping of user_id to restaurant name
      Map<String, String> restaurantMap = {};
      for (var restaurant in response) {
        restaurantMap[restaurant['owner_id']] = restaurant['name'];
      }
      
      if (mounted) {
        setState(() {
          _restaurantNames = restaurantMap;
        });
      }
    } catch (e) {
      print('Error loading restaurant data: $e');
      // Non-critical error, don't set error state
    }
  }

  Future<void> _updateUserRole(String userId, String newRole) async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      await _supabase
          .from('users')
          .update({'role': newRole})
          .eq('user_id', userId);
      
      // Refresh user list
      await _loadUsers();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('User role updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating user role: $e'),
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

  Future<void> _createNewUser(String email, String phone, String username, String role) async {
    setState(() {
      _isLoading = true;
    });

    try {
      // For restaurant owners, we need to handle verification
      bool isRestaurantOwner = role == 'restaurant_owner';
      
      // First, create the user with a temporary role if it's a restaurant owner
      String initialRole = isRestaurantOwner ? 'pending_restaurant_owner' : role;
      
      // 1. Create the user
      await _supabase
        .from('users')
        .insert({
          'email': email,
          'phone': phone,
          'username': username,
          'role': initialRole,
          'created_at': DateTime.now().toIso8601String(),
        });
      
      // 2. For restaurant owners, create a verification request
      if (isRestaurantOwner) {
        // Get the newly created user
        final newUser = await _supabase
            .from('users')
            .select('user_id')
            .eq('email', email)
            .single();
        
        // Create verification request
        await _supabase
            .from('verification_requests')
            .insert({
              'owner_id': newUser['user_id'],
              'restaurant_name': 'New Restaurant', // Default name
              'status': 'pending',
              'submitted_at': DateTime.now().toIso8601String(),
              'documents': [] // Empty documents initially
            });
      }
      
      // Refresh data
      await _loadData();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isRestaurantOwner 
              ? 'Restaurant owner created and pending verification' 
              : 'User created successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Error creating user: $e';
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating user: $e'),
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

  void _showEditRoleDialog(BuildContext context, Map<String, dynamic> user) {
    String selectedRole = user['role'];
    final roleOptions = [
      'customer',
      'restaurant_owner',
      'restaurant_manager',
      'restaurant_chef',
      'restaurant_waiter',
      'restaurant_cashier',
      'restaurant_inventory_manager',
      'super_admin',
      'developer_admin',
    ];
    
    // Get restaurant name if available
    String? restaurantName = _restaurantNames[user['user_id']];
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF222222),
        title: const Text(
          'Edit User',
          style: TextStyle(
            color: Color(0xFFEEEFEF),
            fontFamily: 'Helvetica Neue',
          ),
        ),
        content: StatefulBuilder(
          builder: (context, setState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'User: ${user['username']}',
                  style: const TextStyle(
                    color: Color(0xFFD0F0C0),
                    fontFamily: 'Helvetica Neue',
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Email: ${user['email']}',
                  style: TextStyle(
                    color: const Color(0xFFEEEFEF).withAlpha(180),
                    fontSize: 12,
                    fontFamily: 'Helvetica Neue',
                  ),
                ),
                
                // Show restaurant information if available
                if (restaurantName != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Restaurant: $restaurantName',
                    style: const TextStyle(
                      color: Color(0xFFD0F0C0),
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Helvetica Neue',
                    ),
                  ),
                ],
                
                const SizedBox(height: 16),
                const Text(
                  'Select Role:',
                  style: TextStyle(
                    color: Color(0xFFEEEFEF),
                    fontFamily: 'Helvetica Neue',
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF151611),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: DropdownButton<String>(
                    value: selectedRole,
                    isExpanded: true,
                    dropdownColor: const Color(0xFF222222),
                    underline: const SizedBox(),
                    style: const TextStyle(
                      color: Color(0xFFEEEFEF),
                      fontFamily: 'Helvetica Neue',
                    ),
                    items: roleOptions.map((role) {
                      return DropdownMenuItem<String>(
                        value: role,
                        child: Text(role),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedRole = value!;
                      });
                    },
                  ),
                ),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Cancel',
              style: TextStyle(
                color: Colors.grey,
                fontFamily: 'Helvetica Neue',
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _updateUserRole(user['user_id'], selectedRole);
            },
            child: const Text(
              'Save',
              style: TextStyle(
                color: Color(0xFFD0F0C0),
                fontFamily: 'Helvetica Neue',
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  void _showAddUserDialog() {
    final emailController = TextEditingController();
    final phoneController = TextEditingController();
    final usernameController = TextEditingController();
    String selectedRole = 'customer';
    
    final roleOptions = [
      'customer',
      'restaurant_owner',
      'restaurant_manager',
      'restaurant_chef',
      'restaurant_waiter',
      'restaurant_cashier',
      'restaurant_inventory_manager',
      'super_admin',
      'developer_admin',
    ];
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF222222),
        title: const Text(
          'Add New User',
          style: TextStyle(
            color: Color(0xFFEEEFEF),
            fontFamily: 'Helvetica Neue',
          ),
        ),
        content: StatefulBuilder(
          builder: (context, setState) {
            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Username
                  const Text(
                    'Username:',
                    style: TextStyle(
                      color: Color(0xFFEEEFEF),
                      fontFamily: 'Helvetica Neue',
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: usernameController,
                    style: const TextStyle(
                      color: Color(0xFFEEEFEF),
                      fontFamily: 'Helvetica Neue',
                    ),
                    decoration: InputDecoration(
                      hintText: 'Enter username',
                      hintStyle: TextStyle(
                        color: const Color(0xFFEEEFEF).withAlpha(120),
                        fontFamily: 'Helvetica Neue',
                      ),
                      filled: true,
                      fillColor: const Color(0xFF151611),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Email
                  const Text(
                    'Email:',
                    style: TextStyle(
                      color: Color(0xFFEEEFEF),
                      fontFamily: 'Helvetica Neue',
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    style: const TextStyle(
                      color: Color(0xFFEEEFEF),
                      fontFamily: 'Helvetica Neue',
                    ),
                    decoration: InputDecoration(
                      hintText: 'Enter email address',
                      hintStyle: TextStyle(
                        color: const Color(0xFFEEEFEF).withAlpha(120),
                        fontFamily: 'Helvetica Neue',
                      ),
                      filled: true,
                      fillColor: const Color(0xFF151611),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Phone
                  const Text(
                    'Phone:',
                    style: TextStyle(
                      color: Color(0xFFEEEFEF),
                      fontFamily: 'Helvetica Neue',
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    style: const TextStyle(
                      color: Color(0xFFEEEFEF),
                      fontFamily: 'Helvetica Neue',
                    ),
                    decoration: InputDecoration(
                      hintText: 'Enter phone number',
                      hintStyle: TextStyle(
                        color: const Color(0xFFEEEFEF).withAlpha(120),
                        fontFamily: 'Helvetica Neue',
                      ),
                      filled: true,
                      fillColor: const Color(0xFF151611),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Role
                  const Text(
                    'User Role:',
                    style: TextStyle(
                      color: Color(0xFFEEEFEF),
                      fontFamily: 'Helvetica Neue',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF151611),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: DropdownButton<String>(
                      value: selectedRole,
                      isExpanded: true,
                      dropdownColor: const Color(0xFF222222),
                      underline: const SizedBox(),
                      style: const TextStyle(
                        color: Color(0xFFEEEFEF),
                        fontFamily: 'Helvetica Neue',
                      ),
                      items: roleOptions.map((role) {
                        return DropdownMenuItem<String>(
                          value: role,
                          child: Text(role),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedRole = value!;
                        });
                      },
                    ),
                  ),
                  
                  // Warning for restaurant owner
                  if (selectedRole == 'restaurant_owner') ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.withAlpha(50),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Note: Creating a restaurant owner will start the verification process. The user will need to complete verification before getting full access.',
                        style: TextStyle(
                          color: Colors.orange,
                          fontSize: 12,
                          fontFamily: 'Helvetica Neue',
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Cancel',
              style: TextStyle(
                color: Colors.grey,
                fontFamily: 'Helvetica Neue',
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              // Validate inputs
              if (emailController.text.isEmpty || 
                  usernameController.text.isEmpty ||
                  phoneController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please fill all required fields'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              
              Navigator.of(context).pop();
              _createNewUser(
                emailController.text,
                phoneController.text,
                usernameController.text,
                selectedRole
              );
            },
            child: const Text(
              'Create User',
              style: TextStyle(
                color: Color(0xFFD0F0C0),
                fontFamily: 'Helvetica Neue',
              ),
            ),
          ),
        ],
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
                onLeftButtonPressed: _loadData,
                headingText: "User Management",
                rightIcon: Iconsax.menu_1,
                onRightButtonPressed: _openSideMenu,
              ),
              
              // Role filter chips
              _buildRoleFilterChips(),
              
              // Search bar with better padding
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                child: TextField(
                  style: const TextStyle(color: Color(0xFFEEEFEF)),
                  decoration: InputDecoration(
                    hintText: 'Search users...',
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    prefixIcon: const Icon(Iconsax.search_normal, color: Color(0xFFD0F0C0)),
                    filled: true,
                    fillColor: const Color(0xFF222222),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
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
                  margin: const EdgeInsets.symmetric(horizontal: 16),
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
              
              // Add user button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: ElevatedButton.icon(
                  icon: const Icon(Iconsax.user_add, color: Color(0xFF151611)),
                  label: const Text(
                    'Add New User',
                    style: TextStyle(color: Color(0xFF151611)),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD0F0C0),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: _showAddUserDialog,
                ),
              ),
              
              // User list
              Expanded(
                child: _buildUsersList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildRoleFilterChips() {
    final roles = [
      'All',
      'customer',
      'restaurant_owner',
      'restaurant_manager',
      'super_admin',
    ];
    
    return Container(
      height: 40,
      margin: const EdgeInsets.only(top: 8),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: roles.map((role) {
          final isSelected = _roleFilter == role;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(role),
              selected: isSelected,
              showCheckmark: false,
              backgroundColor: const Color(0xFF222222),
              selectedColor: const Color(0xFFD0F0C0),
              labelStyle: TextStyle(
                color: isSelected ? const Color(0xFF151611) : const Color(0xFFEEEFEF),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              onSelected: (selected) {
                setState(() {
                  _roleFilter = role;
                });
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildUsersList() {
    // Filter users based on search query and role filter
    final filteredUsers = _users.where((user) {
      // Apply search filter
      final matchesSearch = _searchQuery.isEmpty ||
          (user['username'] != null && user['username'].toString().toLowerCase().contains(_searchQuery.toLowerCase())) ||
          (user['email'] != null && user['email'].toString().toLowerCase().contains(_searchQuery.toLowerCase())) ||
          (user['role'] != null && user['role'].toString().toLowerCase().contains(_searchQuery.toLowerCase()));
      
      // Apply role filter
      final matchesRole = _roleFilter == 'All' || user['role'] == _roleFilter;
      
      return matchesSearch && matchesRole;
    }).toList();
    
    if (_isLoading && _users.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFFD0F0C0),
        ),
      );
    }
    
    if (filteredUsers.isEmpty) {
      return const Center(
        child: Text(
          'No users found',
          style: TextStyle(color: Color(0xFFEEEFEF)),
        ),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 80),
      itemCount: filteredUsers.length,
      itemBuilder: (context, index) {
        final user = filteredUsers[index];
        return _buildUserCard(user);
      },
    );
  }

  Widget _buildUserCard(Map<String, dynamic> user) {
    final username = user['username'] ?? 'Unknown';
    String firstLetter = '';
    if (username is String && username.isNotEmpty) {
      firstLetter = username.substring(0, 1).toUpperCase();
    }
    
    // Check if this user has a restaurant
    final isRestaurantOwner = user['role'] == 'restaurant_owner';
    final hasRestaurant = _restaurantNames.containsKey(user['user_id']);
    final restaurantName = _restaurantNames[user['user_id']];
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: const Color(0xFF1A1A1A),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: CircleAvatar(
              backgroundColor: const Color(0xFF222222),
              child: Text(
                firstLetter,
                style: const TextStyle(color: Color(0xFFD0F0C0)),
              ),
            ),
            title: Text(
              username.toString(),
              style: const TextStyle(
                color: Color(0xFFEEEFEF),
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (user['email'] != null)
                  Text(
                    user['email'],
                    style: const TextStyle(color: Color(0xFFEEEFEF)),
                  ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF151611),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        user['role'] ?? 'No role',
                        style: const TextStyle(
                          color: Color(0xFFD0F0C0),
                          fontSize: 12,
                        ),
                      ),
                    ),
                    
                    // Show phone number if available
                    if (user['phone'] != null) ...[
                      const SizedBox(width: 8),
                      Text(
                        user['phone'],
                        style: TextStyle(
                          color: const Color(0xFFEEEFEF).withAlpha(150),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
            trailing: IconButton(
              icon: const Icon(
                Iconsax.edit,
                color: Color(0xFFD0F0C0),
              ),
              onPressed: () => _showEditRoleDialog(context, user),
            ),
          ),
          
          // Show restaurant information if this is a restaurant owner
          if (isRestaurantOwner) ...[
            Divider(color: const Color(0xFF222222).withAlpha(150)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  const Icon(
                    Iconsax.shop,
                    color: Color(0xFFD0F0C0),
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  hasRestaurant
                    ? Text(
                        'Restaurant: $restaurantName',
                        style: const TextStyle(
                          color: Color(0xFFEEEFEF),
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : const Text(
                        'No restaurant associated',
                        style: TextStyle(
                          color: Colors.orange,
                          fontSize: 12,
                        ),
                      ),
                  const Spacer(),
                  // Button to view restaurant details
                  if (hasRestaurant)
                    TextButton.icon(
                      icon: const Icon(
                        Iconsax.eye,
                        size: 16,
                      ),
                      label: const Text('View'),
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFFD0F0C0),
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(60, 30),
                      ),
                      onPressed: () {
                        // Show restaurant details dialog
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Restaurant details feature coming soon'),
                            backgroundColor: Colors.blue,
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
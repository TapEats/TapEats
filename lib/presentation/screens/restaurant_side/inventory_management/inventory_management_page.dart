import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tapeats/presentation/screens/restaurant_side/inventory_management/inventory_count_page.dart';
import 'package:tapeats/presentation/screens/restaurant_side/inventory_management/purchase_orders_page.dart';
import 'package:tapeats/presentation/screens/restaurant_side/inventory_management/receiving_page.dart';
import 'package:tapeats/presentation/screens/restaurant_side/inventory_management/recipe_costs_page.dart';
import 'package:tapeats/presentation/screens/restaurant_side/inventory_management/stock_management_page.dart';
import 'package:tapeats/presentation/screens/restaurant_side/inventory_management/suppliers_management_page.dart';
import 'package:tapeats/presentation/screens/restaurant_side/inventory_management/waste_management_page.dart';
import 'package:tapeats/presentation/state_management/navbar_state.dart';
import 'package:tapeats/presentation/widgets/header_widget.dart';
import 'package:tapeats/presentation/widgets/footer_widget.dart';
import 'package:tapeats/presentation/widgets/sidemenu_overlay.dart';

class InventoryManagementPage extends StatefulWidget {
  final int selectedIndex;
  
  const InventoryManagementPage({
    super.key,
    required this.selectedIndex,
  });

  @override
  State<InventoryManagementPage> createState() => _InventoryManagementPageState();
}

class _InventoryManagementPageState extends State<InventoryManagementPage> {
  final SupabaseClient _supabase = Supabase.instance.client;
  
  // Inventory statistics
  int _totalInventoryCount = 0;
  int _lowStockCount = 0;
  int _expiringCount = 0;
  int _suppliersCount = 0;
  int _pendingOrdersCount = 0;
  int _pendingReceivingCount = 0;
  String _lastCountDate = "";
  
  bool _isLoading = true;
  String _selectedCategory = "All";
  
  @override
  void initState() {
    super.initState();
    // Update the navbar state with the correct index
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<NavbarState>(context, listen: false).updateIndex(widget.selectedIndex);
      _fetchInventoryStats();
    });
  }
  
  // Fetch all inventory statistics
  Future<void> _fetchInventoryStats() async {
    setState(() => _isLoading = true);
    
    try {
      // Get restaurant ID (assuming it's stored in user session or similar)
      final user = _supabase.auth.currentUser;
      if (user == null) {
        setState(() => _isLoading = false);
        return;
      }
      
      // Try to get restaurant_id from user data
      final userData = await _supabase
          .from('users')
          .select('restaurant_id')
          .eq('user_id', user.id)
          .maybeSingle();
      
      if (userData == null || userData['restaurant_id'] == null) {
        print('No restaurant_id found for user');
        setState(() => _isLoading = false);
        return;
      }
      
      final restaurantId = userData['restaurant_id'];
      
      // When fetching data, check if tables exist and handle possible errors
      try {
        // 1. Get total inventory count
        final inventoryResult = await _supabase
            .from('inventory')
            .select('inventory_id')
            .eq('restaurant_id', restaurantId);
        
        _totalInventoryCount = inventoryResult.length;
        
        // 2. Get low stock count
        final lowStockResult = await _supabase
            .from('inventory')
            .select('inventory_id, quantity, min_quantity')
            .eq('restaurant_id', restaurantId);
        
        _lowStockCount = lowStockResult.where((item) => 
            item['min_quantity'] != null && 
            item['quantity'] != null &&
            (item['quantity'] as num) < (item['min_quantity'] as num)).length;
      } catch (e) {
        print('Error fetching inventory data: $e');
        // Continue with other data even if inventory fails
      }
      
      try {
        // 3. Get suppliers count (if suppliers table exists)
        final suppliersResult = await _supabase
            .from('suppliers')
            .select('id')
            .eq('restaurant_id', restaurantId);
        
        _suppliersCount = suppliersResult.length;
      } catch (e) {
        print('No suppliers table or error: $e');
        _suppliersCount = 0;
      }
      
      try {
        // 4. Get expiring soon count (next 7 days)
        final now = DateTime.now();
        final nextWeek = now.add(const Duration(days: 7));
        
        final expiringResult = await _supabase
            .from('inventory')
            .select('inventory_id, expiry_date')
            .eq('restaurant_id', restaurantId)
            .not('expiry_date', 'is', null);
        
        _expiringCount = expiringResult.where((item) {
          if (item['expiry_date'] == null) return false;
          try {
            final expDate = DateTime.parse(item['expiry_date']);
            return expDate.isAfter(now) && expDate.isBefore(nextWeek);
          } catch (e) {
            return false;
          }
        }).length;
      } catch (e) {
        print('Error fetching expiry data: $e');
        _expiringCount = 0;
      }
      
      // 5. Try to get data from purchase_orders if it exists
      try {
        if (await _checkTableExists('purchase_orders')) {
          final pendingOrdersResult = await _supabase
              .from('purchase_orders')
              .select('purchase_order_id')
              .eq('restaurant_id', restaurantId)
              .eq('status', 'pending');
              
          _pendingOrdersCount = pendingOrdersResult.length;
          
          // Also get receiving count (approved orders waiting to be received)
          final receivingResult = await _supabase
              .from('purchase_orders')
              .select('purchase_order_id')
              .eq('restaurant_id', restaurantId)
              .eq('status', 'approved');
              
          _pendingReceivingCount = receivingResult.length;
        }
      } catch (e) {
        print('No purchase_orders table or error: $e');
        _pendingOrdersCount = 0;
        _pendingReceivingCount = 0;
      }
      
      // 6. Try to get data from inventory_transactions if it exists
      try {
        if (await _checkTableExists('inventory_transactions')) {
          final lastCountResult = await _supabase
              .from('inventory_transactions')
              .select('created_at')
              .eq('restaurant_id', restaurantId)
              .eq('transaction_type', 'count')
              .order('created_at', ascending: false)
              .limit(1);
              
          if (lastCountResult.isNotEmpty) {
            final lastCountDate = DateTime.parse(lastCountResult[0]['created_at']);
            final now = DateTime.now();
            final difference = now.difference(lastCountDate).inDays;
            
            if (difference == 0) {
              _lastCountDate = 'Today';
            } else if (difference == 1) {
              _lastCountDate = 'Yesterday';
            } else {
              _lastCountDate = '${difference}d ago';
            }
          } else {
            _lastCountDate = 'Never';
          }
        } else {
          _lastCountDate = 'Set up now';
        }
      } catch (e) {
        print('No inventory_transactions table or error: $e');
        _lastCountDate = 'Not Available';
      }
    } catch (e) {
      print('Error fetching inventory stats: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }
  
  // Helper to check if a table exists
  Future<bool> _checkTableExists(String tableName) async {
    try {
      // For purchase_orders table, check its primary key column name
      if (tableName == 'purchase_orders') {
        await _supabase.from(tableName).select('purchase_order_id').limit(1);
      } 
      // For inventory_transactions table, check its primary key column name
      else if (tableName == 'inventory_transactions') {
        await _supabase.from(tableName).select('transaction_id').limit(1);
      } 
      else {
        // Generic check for other tables
        await _supabase.from(tableName).select().limit(1);
      }
      return true;
    } catch (e) {
      print('Table check error: $e');
      return false;
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _openSideMenu() {
    // Show the side menu as a modal overlay
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Side Menu",
      pageBuilder: (context, animation1, animation2) {
        return const RoleBasedSideMenu();
      },
    );
  }

  Future<void> _fetchFilteredData(String category) async {
    setState(() => _isLoading = true);
    
    try {
      // Get restaurant ID
      final user = _supabase.auth.currentUser;
      if (user == null) {
        setState(() => _isLoading = false);
        return;
      }
      
      final userData = await _supabase
          .from('users')
          .select('restaurant_id')
          .eq('user_id', user.id)
          .maybeSingle();
      
      if (userData == null || userData['restaurant_id'] == null) {
        print('No restaurant_id found for user');
        setState(() => _isLoading = false);
        return;
      }
      
      final restaurantId = userData['restaurant_id'];
      
      // Build query based on selected category
      if (category == "All") {
        // Just refresh all stats
        await _fetchInventoryStats();
      } else if (category == "Low Stock") {
        // Focus on low stock items
        final lowStockResult = await _supabase
            .from('inventory')
            .select('inventory_id, quantity, min_quantity')
            .eq('restaurant_id', restaurantId);
        
        _lowStockCount = lowStockResult.where((item) => 
            item['min_quantity'] != null && 
            item['quantity'] != null &&
            (item['quantity'] as num) < (item['min_quantity'] as num)).length;
        _totalInventoryCount = _lowStockCount; // For display purposes
      } else if (category == "Expiring Soon") {
        // Focus on expiring items
        final now = DateTime.now();
        final nextWeek = now.add(const Duration(days: 7));
        
        final expiringResult = await _supabase
            .from('inventory')
            .select('inventory_id, expiry_date')
            .eq('restaurant_id', restaurantId)
            .not('expiry_date', 'is', null);
        
        _expiringCount = expiringResult.where((item) {
          if (item['expiry_date'] == null) return false;
          try {
            final expDate = DateTime.parse(item['expiry_date']);
            return expDate.isAfter(now) && expDate.isBefore(nextWeek);
          } catch (e) {
            return false;
          }
        }).length;
        
        _totalInventoryCount = _expiringCount; // For display purposes
      } else if (category == "Recent Orders") {
        // Focus on recent purchase orders
        if (await _checkTableExists('purchase_orders')) {
          final recentOrdersResult = await _supabase
              .from('purchase_orders')
              .select('purchase_order_id, created_at')
              .eq('restaurant_id', restaurantId);
              
          final weekAgo = DateTime.now().subtract(const Duration(days: 7));
          _pendingOrdersCount = recentOrdersResult.where((order) {
            if (order['created_at'] == null) return false;
            try {
              final orderDate = DateTime.parse(order['created_at']);
              return orderDate.isAfter(weekAgo);
            } catch (e) {
              return false;
            }
          }).length;
        }
      }
    } catch (e) {
      print('Error filtering inventory data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212), // Dark background
      body: SafeArea(
        child: Column(
          children: [
            // Header
            HeaderWidget(
              leftIcon: Iconsax.arrow_left_1,
              onLeftButtonPressed: () {},
              headingText: "Inventory Management",
              rightIcon: Iconsax.menu_1,
              onRightButtonPressed: _openSideMenu,
            ),
            
            const SizedBox(height: 20),
            
            // Category Filter Tabs
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  _buildCategoryChip("All", _selectedCategory == "All"),
                  _buildCategoryChip("Low Stock", _selectedCategory == "Low Stock"),
                  _buildCategoryChip("Expiring Soon", _selectedCategory == "Expiring Soon"),
                  _buildCategoryChip("Recent Orders", _selectedCategory == "Recent Orders"),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Main Content - Grid of feature cards
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFFD0F0C0)))
                  : Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: GridView.count(
                        crossAxisCount: 2,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        childAspectRatio: 1.1,
                        children: [
                          _buildFeatureCard(
                            title: "Stock",
                            icon: Iconsax.box,
                            count: "$_totalInventoryCount",
                            isAlert: _lowStockCount > 0,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => StockManagementPage(selectedIndex: widget.selectedIndex),
                                ),
                              );
                            },
                          ),
                          _buildFeatureCard(
                            title: "Suppliers",
                            icon: Iconsax.truck,
                            count: "$_suppliersCount",
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const SuppliersManagementPage(),
                                ),
                              );
                            },
                          ),
                          _buildFeatureCard(
                            title: "Purchase Orders",
                            icon: Iconsax.document_text,
                            count: "$_pendingOrdersCount",
                            isAlert: _pendingOrdersCount > 0,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const PurchaseOrdersPage(), // Replace with Purchase Orders page
                                ),
                              );
                            },
                          ),
                          _buildFeatureCard(
                            title: "Receiving",
                            icon: Iconsax.box_add,
                            count: "$_pendingReceivingCount",
                            isAlert: _pendingReceivingCount > 0,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const ReceivingPage(), // Replace with Receiving page
                                ),
                              );
                            },
                          ),
                          _buildFeatureCard(
                            title: "Inventory Count",
                            icon: Iconsax.clipboard_text,
                            lastUpdated: _lastCountDate,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const InventoryCountPage(), // Replace with Inventory Count page
                                ),
                              );
                            },
                          ),
                          _buildFeatureCard(
                            title: "Waste",
                            icon: Iconsax.trash,
                            count: "New",
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const WasteManagementPage(), // Replace with Waste page
                                ),
                              );
                            },
                          ),
                          _buildFeatureCard(
                            title: "Recipe Costs",
                            icon: Iconsax.diagram,
                            count: "Calculate",
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const RecipeCostsPage(), // Replace with Recipe Costs page
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
            ),
            
            // Add padding at the bottom for the navbar
            const SizedBox(height: 70),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFFD0F0C0),
        onPressed: () {
          // Add new inventory item
        },
        child: const Icon(Iconsax.add, color: Color(0xFF222222)),
      ),
      bottomNavigationBar: const DynamicFooter(),
    );
  }

  Widget _buildCategoryChip(String label, bool isSelected) {
    return Container(
      margin: const EdgeInsets.only(right: 12),
      child: FilterChip(
        label: Text(
          label,
          style: TextStyle(
            color: isSelected ? const Color(0xFF222222) : const Color(0xFFEEEFEF),
            fontFamily: 'Helvetica Neue',
            fontWeight: FontWeight.w500,
          ),
        ),
        selected: isSelected,
        showCheckmark: false,
        backgroundColor: const Color(0xFF222222),
        selectedColor: const Color(0xFFD0F0C0),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        onSelected: (selected) {
          if (selected) {
            setState(() {
              _selectedCategory = label;
            });
            // Update data based on category selection
            _fetchFilteredData(label);
          }
        },
      ),
    );
  }

  Widget _buildFeatureCard({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
    String? count,
    String? lastUpdated,
    bool isAlert = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF222222),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Stack(
          children: [
            // Main content
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon and counter row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Icon(
                        icon,
                        size: 32,
                        color: const Color(0xFFD0F0C0),
                      ),
                      if (count != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: isAlert 
                                ? const Color(0xFFFF9A8D) 
                                : const Color(0xFF333333),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            count,
                            style: TextStyle(
                              color: isAlert 
                                  ? const Color(0xFF222222) 
                                  : const Color(0xFFEEEFEF),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  
                  const Spacer(),
                  
                  // Title and last updated info
                  Text(
                    title,
                    style: const TextStyle(
                      color: Color(0xFFEEEFEF),
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Helvetica Neue',
                    ),
                  ),
                  if (lastUpdated != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(
                        lastUpdated,
                        style: const TextStyle(
                          color: Color(0xFFAAAAAA),
                          fontSize: 12,
                          fontFamily: 'Helvetica Neue',
                        ),
                      ),
                    ),
                ],
              ),
            ),
            
            // Bottom gradient overlay for visual interest
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: 6,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFFD0F0C0).withOpacity(0.3),
                      const Color(0xFFD0F0C0).withOpacity(0),
                    ],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(15),
                    bottomRight: Radius.circular(15),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
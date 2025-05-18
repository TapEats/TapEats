import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:tapeats/presentation/state_management/navbar_state.dart';
import 'package:tapeats/presentation/widgets/header_widget.dart';
import 'package:tapeats/presentation/widgets/footer_widget.dart';
import 'package:tapeats/presentation/widgets/search_bar.dart';
import 'package:tapeats/presentation/widgets/sidemenu_overlay.dart';

class ReceivingPage extends StatefulWidget {
  
  const ReceivingPage({
    super.key,
  });

  @override
  State<ReceivingPage> createState() => _ReceivingPageState();
}

class _ReceivingPageState extends State<ReceivingPage> {
  final SupabaseClient _supabase = Supabase.instance.client;
  final TextEditingController _searchController = TextEditingController();
  
  bool _isLoading = true;
  List<Map<String, dynamic>> _pendingOrders = [];
  List<Map<String, dynamic>> _filteredOrders = [];
  Map<String, List<Map<String, dynamic>>> _orderItems = {};
  
  @override
  void initState() {
    super.initState();
    
    // Update the navbar state with the correct index
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openSideMenu() {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Side Menu",
      pageBuilder: (context, animation1, animation2) {
        return const RoleBasedSideMenu();
      },
    );
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    
    try {
      // Check if tables exist first
      final tablesExist = await _checkRequiredTables();
      if (!tablesExist) {
        setState(() => _isLoading = false);
        return;
      }
      
      await _fetchPendingOrders();
    } catch (e) {
      print('Error loading initial data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }
  
  Future<bool> _checkRequiredTables() async {
    try {
      // Check if purchase_orders table exists
      try {
        await _supabase.from('purchase_orders').select('purchase_order_id').limit(1);
      } catch (e) {
        print('Purchase orders table does not exist: $e');
        
        // Show message to user
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Purchase orders system is not set up. Please set up purchase orders first.'),
              action: SnackBarAction(
                label: 'Go to Purchase Orders',
                onPressed: () {
                  Navigator.pushReplacementNamed(context, '/purchase_orders');
                },
              ),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 10),
            ),
          );
        }
        return false;
      }
      
      return true;
    } catch (e) {
      print('Error checking required tables: $e');
      return false;
    }
  }
  
  Future<void> _fetchPendingOrders() async {
    try {
      // Get restaurant ID
      final user = _supabase.auth.currentUser;
      if (user == null) return;
      
      final userData = await _supabase
          .from('users')
          .select('restaurant_id')
          .eq('user_id', user.id)
          .maybeSingle();
      
      if (userData == null || userData['restaurant_id'] == null) {
        print('No restaurant_id found for user');
        return;
      }
      
      final restaurantId = userData['restaurant_id'];
      
      // Fetch all approved orders awaiting receiving
      final ordersResult = await _supabase
          .from('purchase_orders')
          .select('''
            purchase_order_id,
            created_at,
            expected_delivery_date,
            status,
            total_amount,
            notes,
            supplier_id (
              supplier_id,
              company_name
            )
          ''')
          .eq('restaurant_id', restaurantId)
          .eq('status', 'approved')
          .order('expected_delivery_date', ascending: true);
      
      // Fetch items for each order
      for (var order in ordersResult) {
        final orderId = order['purchase_order_id'];
        final itemsResult = await _supabase
            .from('purchase_order_items')
            .select('''
              item_id,
              quantity,
              unit_price,
              notes,
              inventory_id (
                inventory_id,
                item_name,
                unit
              )
            ''')
            .eq('purchase_order_id', orderId);
            
        // Store items for each order
        _orderItems[orderId] = itemsResult;
      }
            
      setState(() {
        _pendingOrders = ordersResult;
        _filterOrders(); // Apply initial filtering
      });
    } catch (e) {
      print('Error fetching pending orders: $e');
      setState(() {
        _pendingOrders = [];
        _filteredOrders = [];
      });
    }
  }
  
  void _filterOrders() {
    final searchText = _searchController.text.toLowerCase();
    
    setState(() {
      if (searchText.isEmpty) {
        _filteredOrders = _pendingOrders;
      } else {
        _filteredOrders = _pendingOrders.where((order) {
          // Search in order ID, notes and supplier name
          final orderId = order['purchase_order_id']?.toString().toLowerCase() ?? '';
          final notes = order['notes']?.toString().toLowerCase() ?? '';
          
          // Handle supplier info which might be nested or flat
          String supplierName = '';
          if (order['supplier_id'] is Map) {
            supplierName = order['supplier_id']['company_name']?.toString().toLowerCase() ?? '';
          }
          
          return orderId.contains(searchText) || 
                notes.contains(searchText) ||
                supplierName.contains(searchText);
        }).toList();
      }
    });
  }
  
  String _getSupplierName(Map<String, dynamic> order) {
    // Handle supplier info which might be nested
    if (order['supplier_id'] is Map) {
      return order['supplier_id']['company_name'] ?? 'Unknown Supplier';
    }
    return 'Unknown Supplier';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            HeaderWidget(
              leftIcon: Iconsax.arrow_left_1,
              onLeftButtonPressed: () => Navigator.pop(context),
              headingText: "Receiving",
              rightIcon: Iconsax.menu_1,
              onRightButtonPressed: _openSideMenu,
            ),
            
            const SizedBox(height: 20),
            
            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: CustomSearchBar(
                controller: _searchController,
                hintText: "Search orders to receive...",
                onSearch: _filterOrders,
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Main Content
            Expanded(
              child: _isLoading 
                ? const Center(child: CircularProgressIndicator(color: Color(0xFFD0F0C0)))
                : _filteredOrders.isEmpty 
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      itemCount: _filteredOrders.length,
                      itemBuilder: (context, index) {
                        final order = _filteredOrders[index];
                        return _buildOrderCard(order);
                      },
                    ),
            ),
            
            // Bottom padding for the navbar
            const SizedBox(height: 70),
          ],
        ),
      ),
      bottomNavigationBar: const DynamicFooter(),
    );
  }
  
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Iconsax.box_add, 
            size: 64, 
            color: Colors.white.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            "No approved orders waiting to be received",
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () {
              Navigator.pushReplacementNamed(context, '/purchase_orders');
            },
            icon: const Icon(Iconsax.arrow_right_3, color: Color(0xFFD0F0C0)),
            label: const Text(
              "Go to Purchase Orders",
              style: TextStyle(color: Color(0xFFD0F0C0)),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildOrderCard(Map<String, dynamic> order) {
    // Format date
    String orderDate = 'N/A';
    String expectedDate = 'N/A';
    bool isOverdue = false;
    
    try {
      if (order['created_at'] != null) {
        final date = DateTime.parse(order['created_at']);
        orderDate = DateFormat('MMM d, yyyy').format(date);
      }
      
      if (order['expected_delivery_date'] != null) {
        final date = DateTime.parse(order['expected_delivery_date']);
        expectedDate = DateFormat('MMM d, yyyy').format(date);
        
        // Check if order is overdue
        isOverdue = date.isBefore(DateTime.now());
      }
    } catch (e) {
      print('Error formatting dates: $e');
    }
    
    // Get supplier name
    final supplierName = _getSupplierName(order);
    
    // Get order items
    final items = _orderItems[order['purchase_order_id']] ?? [];
    final itemCount = items.length;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: const Color(0xFF222222),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isOverdue 
            ? const BorderSide(color: Colors.orange, width: 1) 
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Order ID and date
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "PO-${order['purchase_order_id'].toString().substring(0, 8)}",
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Created: $orderDate",
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                
                // Expected delivery date with warning if overdue
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      children: [
                        if (isOverdue)
                          Icon(
                            Iconsax.warning_2,
                            size: 16,
                            color: Colors.orange,
                          ),
                        const SizedBox(width: 4),
                        Text(
                          "Expected: $expectedDate",
                          style: TextStyle(
                            color: isOverdue ? Colors.orange : Colors.white.withOpacity(0.6),
                            fontSize: 12,
                            fontWeight: isOverdue ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "From: $supplierName",
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Order summary
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "$itemCount ${itemCount == 1 ? 'Item' : 'Items'}",
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        "Total: \$${(order['total_amount'] as num?)?.toStringAsFixed(2) ?? '0.00'}",
                        style: const TextStyle(
                          color: Color(0xFFD0F0C0),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 8),
                  const Divider(color: Color(0xFF333333)),
                  const SizedBox(height: 4),
                  
                  // Show first few items or summary
                  if (items.isEmpty)
                    const Text(
                      "No items found for this order",
                      style: TextStyle(color: Colors.red, fontSize: 12),
                    )
                  else
                    Column(
                      children: [
                        // Show up to 3 items
                        for (var i = 0; i < (items.length > 3 ? 3 : items.length); i++)
                          _buildItemRow(items[i]),
                          
                        // Show "and X more" if there are more than 3 items
                        if (items.length > 3)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              "and ${items.length - 3} more items...",
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.5),
                                fontSize: 12,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                      ],
                    ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white54),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  onPressed: () {
                    _showOrderDetailsModal(context, order);
                  },
                  child: const Text("View Details"),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD0F0C0),
                    foregroundColor: const Color(0xFF222222),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  onPressed: () {
                    _showReceiveOrderModal(context, order);
                  },
                  child: const Text("Receive Order"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildItemRow(Map<String, dynamic> item) {
    // Handle nested inventory data
    String itemName = 'Unknown Item';
    String unit = '';
    
    if (item['inventory_id'] is Map) {
      itemName = item['inventory_id']['item_name'] ?? 'Unknown Item';
      unit = item['inventory_id']['unit'] ?? '';
    }
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              itemName,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            "${item['quantity']} $unit",
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
  
  void _showOrderDetailsModal(BuildContext context, Map<String, dynamic> order) {
    // Get order items
    final items = _orderItems[order['purchase_order_id']] ?? [];
    
    // Get supplier name
    final supplierName = _getSupplierName(order);
    
    // Format dates
    String orderDate = 'N/A';
    String expectedDate = 'N/A';
    
    try {
      if (order['created_at'] != null) {
        final date = DateTime.parse(order['created_at']);
        orderDate = DateFormat('MMMM d, yyyy').format(date);
      }
      
      if (order['expected_delivery_date'] != null) {
        final date = DateTime.parse(order['expected_delivery_date']);
        expectedDate = DateFormat('MMMM d, yyyy').format(date);
      }
    } catch (e) {
      print('Error formatting dates: $e');
    }
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (_, scrollController) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  const Center(
                    child: Text(
                      'Order Details',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Order Info
                  _buildDetailRow("Order ID", "PO-${order['purchase_order_id'].toString().substring(0, 8)}"),
                  _buildDetailRow("Created", orderDate),
                  _buildDetailRow("Expected Delivery", expectedDate),
                  _buildDetailRow("Supplier", supplierName),
                  
                  if (order['notes'] != null && order['notes'].toString().isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        const Text(
                          "Notes",
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF222222),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            order['notes'],
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  
                  const SizedBox(height: 24),
                  
                  // Items List Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Order Items',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD0F0C0).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Text(
                          "${items.length} ${items.length == 1 ? 'Item' : 'Items'}",
                          style: const TextStyle(
                            color: Color(0xFFD0F0C0),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Items List
                  Expanded(
                    child: items.isEmpty
                        ? Center(
                            child: Text(
                              'No items in this order',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.5),
                                fontSize: 14,
                              ),
                            ),
                          )
                        : ListView.builder(
                            controller: scrollController,
                            itemCount: items.length,
                            itemBuilder: (context, index) {
                              final item = items[index];
                              return _buildDetailedItemRow(item);
                            },
                          ),
                  ),
                  
                  // Total
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2A2A2A),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Order Total:',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '\$${(order['total_amount'] as num?)?.toStringAsFixed(2) ?? '0.00'}',
                          style: const TextStyle(
                            color: Color(0xFFD0F0C0),
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Action button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD0F0C0),
                        foregroundColor: const Color(0xFF222222),
                        padding: const EdgeInsets.all(12),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        _showReceiveOrderModal(context, order);
                      },
                      child: const Text(
                        'Receive Order',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
  
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildDetailedItemRow(Map<String, dynamic> item) {
    // Handle nested inventory data
    String itemName = 'Unknown Item';
    String unit = '';
    
    if (item['inventory_id'] is Map) {
      itemName = item['inventory_id']['item_name'] ?? 'Unknown Item';
      unit = item['inventory_id']['unit'] ?? '';
    }
    
    final quantity = item['quantity'] ?? 0;
    final unitPrice = item['unit_price'] ?? 0;
    final total = quantity * unitPrice;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF222222),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            itemName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Qty: $quantity $unit",
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 14,
                ),
              ),
              Text(
                "\$${unitPrice.toStringAsFixed(2)} each",
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                "Total: \$${total.toStringAsFixed(2)}",
                style: const TextStyle(
                  color: Color(0xFFD0F0C0),
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          if (item['notes'] != null && item['notes'].toString().isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                "Note: ${item['notes']}",
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
      ),
    );
  }
  
  void _showReceiveOrderModal(BuildContext context, Map<String, dynamic> order) {
    // Get order items
    final items = _orderItems[order['purchase_order_id']] ?? [];
    
    // Create a map to track received quantities
    final receivedQuantities = <String, double>{};
    final receivedNotes = <String, String>{};
    
    // Initialize with ordered quantities
    for (var item in items) {
      if (item['inventory_id'] is Map) {
        final id = item['inventory_id']['inventory_id'];
        receivedQuantities[id] = item['quantity'] ?? 0;
      }
    }
    
    // Date received (defaults to today)
    final receivedDate = DateTime.now();
    
    // Note for the whole order
    final receivingNotesController = TextEditingController();
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.9,
              minChildSize: 0.5,
              maxChildSize: 0.95,
              expand: false,
              builder: (_, scrollController) {
                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      const Center(
                        child: Text(
                          'Receive Order',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Order info
                      Text(
                        "Order ID: PO-${order['purchase_order_id'].toString().substring(0, 8)}",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Supplier: ${_getSupplierName(order)}",
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 14,
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Date received
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          'Date Received',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 14,
                          ),
                        ),
                        subtitle: Text(
                          DateFormat('MMMM d, yyyy').format(receivedDate),
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.6),
                          ),
                        ),
                        trailing: const Icon(
                          Iconsax.calendar,
                          color: Color(0xFFD0F0C0),
                        ),
                      ),
                      
                      const SizedBox(height: 8),
                      
                      // Notes for receiving
                      TextFormField(
                        controller: receivingNotesController,
                        decoration: InputDecoration(
                          labelText: 'Receiving Notes',
                          labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                          filled: true,
                          fillColor: const Color(0xFF2A2A2A),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        style: const TextStyle(color: Colors.white),
                        maxLines: 2,
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Items List Header
                      const Text(
                        'Received Items',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      
                      const SizedBox(height: 8),
                      
                      // Help text
                      Text(
                        'Adjust quantities if the delivered amounts differ from what was ordered.',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Items List
                      Expanded(
                        child: items.isEmpty
                            ? Center(
                                child: Text(
                                  'No items in this order',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.5),
                                    fontSize: 14,
                                  ),
                                ),
                              )
                            : ListView.builder(
                                controller: scrollController,
                                itemCount: items.length,
                                itemBuilder: (context, index) {
                                  final item = items[index];
                                  return _buildReceivingItemRow(
                                    item, 
                                    receivedQuantities, 
                                    receivedNotes,
                                    setState,
                                  );
                                },
                              ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Action buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text(
                              'Cancel',
                              style: TextStyle(color: Colors.white70),
                            ),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFD0F0C0),
                              foregroundColor: const Color(0xFF222222),
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            ),
                            onPressed: () {
                              _processOrderReceiving(
                                context,
                                order,
                                receivedQuantities,
                                receivedNotes,
                                receivedDate,
                                receivingNotesController.text,
                              );
                            },
                            child: const Text('Confirm Receipt'),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
  
  Widget _buildReceivingItemRow(
    Map<String, dynamic> item,
    Map<String, double> receivedQuantities,
    Map<String, String> receivedNotes,
    StateSetter setState,
  ) {
    // Handle nested inventory data
    String itemName = 'Unknown Item';
    String unit = '';
    String inventoryId = '';
    
    if (item['inventory_id'] is Map) {
      itemName = item['inventory_id']['item_name'] ?? 'Unknown Item';
      unit = item['inventory_id']['unit'] ?? '';
      inventoryId = item['inventory_id']['inventory_id'] ?? '';
    }
    
    // Get ordered quantity
    final orderedQuantity = item['quantity'] ?? 0;
    
    // Get or set received quantity
    final receivedQuantity = receivedQuantities[inventoryId] ?? orderedQuantity;
    
    // Get or initialize notes
    final noteController = TextEditingController(text: receivedNotes[inventoryId] ?? '');
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF222222),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Item name and ordered quantity
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  itemName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                "Ordered: $orderedQuantity $unit",
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 14,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Received quantity input
          Row(
            children: [
              const Text(
                "Received: ",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
              SizedBox(
                width: 80,
                child: TextFormField(
                  initialValue: receivedQuantity.toString(),
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    filled: true,
                    fillColor: const Color(0xFF2A2A2A),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: BorderSide.none,
                    ),
                    suffixText: unit,
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(color: Colors.white),
                  onChanged: (value) {
                    setState(() {
                      receivedQuantities[inventoryId] = double.tryParse(value) ?? orderedQuantity;
                    });
                  },
                ),
              ),
              
              // Quick adjustments
              const SizedBox(width: 12),
              InkWell(
                onTap: () {
                  setState(() {
                    receivedQuantities[inventoryId] = orderedQuantity;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF333333),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    "As Ordered",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: () {
                  setState(() {
                    receivedQuantities[inventoryId] = 0;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF333333),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    "None",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Note input
          TextFormField(
            controller: noteController,
            decoration: InputDecoration(
              hintText: 'Add note (optional)',
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              filled: true,
              fillColor: const Color(0xFF2A2A2A),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide.none,
              ),
            ),
            style: const TextStyle(color: Colors.white, fontSize: 14),
            onChanged: (value) {
              receivedNotes[inventoryId] = value;
            },
          ),
        ],
      ),
    );
  }
  
  Future<void> _processOrderReceiving(
    BuildContext context,
    Map<String, dynamic> order,
    Map<String, double> receivedQuantities,
    Map<String, String> receivedNotes,
    DateTime receivedDate,
    String orderNotes,
  ) async {
    // Close the modal
    Navigator.pop(context);
    
    // Show loading indicator
    setState(() => _isLoading = true);
    
    try {
      // Get restaurant ID
      final user = _supabase.auth.currentUser;
      if (user == null) return;
      
      final userData = await _supabase
          .from('users')
          .select('restaurant_id')
          .eq('user_id', user.id)
          .maybeSingle();
      
      if (userData == null || userData['restaurant_id'] == null) return;
      
      final restaurantId = userData['restaurant_id'];
      final orderId = order['purchase_order_id'];
      
      // Get the order items with inventory details
      final items = _orderItems[orderId] ?? [];
      
      // 1. Update the order status to "Received"
      await _supabase
          .from('purchase_orders')
          .update({
            'status': 'Received',
            'notes': orderNotes.isNotEmpty 
                ? "${order['notes'] ?? ''}\n\nReceiving notes: $orderNotes" 
                : order['notes'],
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('purchase_order_id', orderId);
      
      // 2. For each received item, update inventory quantities
      for (var item in items) {
        if (item['inventory_id'] is! Map) continue;
        
        final inventoryId = item['inventory_id']['inventory_id'];
        final receivedQty = receivedQuantities[inventoryId] ?? 0;
        
        if (receivedQty <= 0) continue;
        
        // Get current inventory quantity
        final inventoryResult = await _supabase
            .from('inventory')
            .select('quantity')
            .eq('inventory_id', inventoryId)
            .single();
            
        final currentQty = inventoryResult['quantity'] as num? ?? 0;
        final newQty = currentQty + receivedQty;
        
        // Update inventory quantity
        await _supabase
            .from('inventory')
            .update({
              'quantity': newQty,
              'last_updated': DateTime.now().toIso8601String(),
            })
            .eq('inventory_id', inventoryId);
            
        // Record the transaction if the table exists
        try {
          await _supabase
              .from('inventory_transactions')
              .insert({
                'inventory_id': inventoryId,
                'transaction_type': 'receiving',
                'quantity': receivedQty,
                'notes': receivedNotes[inventoryId] ?? 'Received from order ${order['purchase_order_id']}',
                'user_id': user.id,
                'restaurant_id': restaurantId,
                'reference_id': orderId,
              });
        } catch (e) {
          print('Inventory transactions table may not exist: $e');
          // Continue even if transaction recording fails
        }
      }
      
      // 3. Refresh the orders list
      await _fetchPendingOrders();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order received successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error processing order receiving: $e');
      
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error receiving order: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
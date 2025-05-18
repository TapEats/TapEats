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

class PurchaseOrdersPage extends StatefulWidget {
  
  const PurchaseOrdersPage({
    super.key, // Default to inventory tab index
  });

  @override
  State<PurchaseOrdersPage> createState() => _PurchaseOrdersPageState();
}

class _PurchaseOrdersPageState extends State<PurchaseOrdersPage> {
  final SupabaseClient _supabase = Supabase.instance.client;
  final TextEditingController _searchController = TextEditingController();
  
  bool _isLoading = true;
  List<Map<String, dynamic>> _orders = [];
  List<Map<String, dynamic>> _filteredOrders = [];
  List<Map<String, dynamic>> _suppliers = [];
  List<Map<String, dynamic>> _inventoryItems = [];
  
  String _selectedStatus = 'All';
  final List<String> _statusFilters = ['All', 'Pending', 'Approved', 'Received', 'Cancelled'];
  
  @override
  void initState() {
    super.initState();
    
    // Update the navbar state with the correct index
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndCreatePurchaseOrderTables();
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
  
  Future<void> _checkAndCreatePurchaseOrderTables() async {
    try {
      // Check if purchase_orders table exists
      try {
        await _supabase.from('purchase_orders').select('purchase_order_id').limit(1);
        print('Purchase orders table exists');
      } catch (e) {
        print('Purchase orders table does not exist: $e');
        
        // Ask user if they want to create the tables
        if (mounted) {
          final shouldCreate = await showDialog<bool>(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              backgroundColor: const Color(0xFF222222),
              title: const Text('Create Purchase Order Tables?', style: TextStyle(color: Colors.white)),
              content: const Text(
                'The purchase_orders and related tables do not exist. Would you like to create them now?',
                style: TextStyle(color: Colors.white70),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Not Now', style: TextStyle(color: Colors.white70)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD0F0C0),
                    foregroundColor: const Color(0xFF222222),
                  ),
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Create Tables'),
                ),
              ],
            ),
          );
          
          if (shouldCreate != true) return;
          
          // Create tables
          try {
            await _supabase.rpc('create_purchase_order_tables');
            print('Purchase order tables created successfully');
          } catch (e) {
            print('Error creating purchase order tables: $e');
            
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Failed to create purchase order tables. Please contact your administrator.'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        }
      }
    } catch (e) {
      print('Error checking/creating purchase order tables: $e');
    }
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    
    try {
      // Load data in parallel
      await Future.wait([
        _fetchPurchaseOrders(),
        _fetchSuppliers(),
        _fetchInventoryItems(),
      ]);
    } catch (e) {
      print('Error loading initial data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }
  
  Future<void> _fetchPurchaseOrders() async {
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
      
      try {
        // Try to fetch orders with supplier info
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
            .order('created_at', ascending: false);
            
        setState(() {
          _orders = ordersResult;
          _filterOrders(); // Apply initial filtering
        });
      } catch (e) {
        print('Error fetching purchase orders: $e');
        // Try simplified query if join fails
        try {
          final ordersResult = await _supabase
              .from('purchase_orders')
              .select()
              .eq('restaurant_id', restaurantId)
              .order('created_at', ascending: false);
              
          setState(() {
            _orders = ordersResult;
            _filterOrders();
          });
        } catch (simpleError) {
          print('Error with simplified purchase orders query: $simpleError');
          setState(() {
            _orders = [];
            _filteredOrders = [];
          });
        }
      }
    } catch (e) {
      print('Error in _fetchPurchaseOrders: $e');
    }
  }
  
  Future<void> _fetchSuppliers() async {
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
      
      // Fetch suppliers
      final suppliersResult = await _supabase
          .from('supplier_id')
          .select('supplier_id, company_name, product_type')
          .eq('restaurant_id', restaurantId);
          
      setState(() {
        _suppliers = suppliersResult;
      });
    } catch (e) {
      print('Error fetching suppliers: $e');
      setState(() {
        _suppliers = [];
      });
    }
  }
  
  Future<void> _fetchInventoryItems() async {
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
      
      // Fetch inventory items
      final inventoryResult = await _supabase
          .from('inventory')
          .select('inventory_id, item_name, category, unit, price_per_unit')
          .eq('restaurant_id', restaurantId);
          
      setState(() {
        _inventoryItems = inventoryResult;
      });
    } catch (e) {
      print('Error fetching inventory items: $e');
      setState(() {
        _inventoryItems = [];
      });
    }
  }
  
  void _filterOrders() {
    final searchText = _searchController.text.toLowerCase();
    
    setState(() {
      _filteredOrders = _orders.where((order) {
        // Filter by status first if not "All"
        if (_selectedStatus != 'All' &&
            order['status']?.toString().toLowerCase() != _selectedStatus.toLowerCase()) {
          return false;
        }
        
        // Then filter by search text if any
        if (searchText.isEmpty) {
          return true;
        }
        
        // Search in order ID, notes and supplier name
        final orderId = order['purchase_order_id']?.toString().toLowerCase() ?? '';
        final notes = order['notes']?.toString().toLowerCase() ?? '';
        
        // Handle supplier info which might be nested or flat
        String supplierName = '';
        if (order['supplier_id'] is Map) {
          supplierName = order['supplier_id']['company_name']?.toString().toLowerCase() ?? '';
        } else if (order['supplier_id'] != null) {
          // Try to find matching supplier
          final supplierId = order['supplier_id'];
          final supplier = _suppliers.firstWhere(
            (s) => s['supplier_id'] == supplierId,
            orElse: () => {},
          );
          supplierName = supplier['company_name']?.toString().toLowerCase() ?? '';
        }
        
        return orderId.contains(searchText) || 
               notes.contains(searchText) ||
               supplierName.contains(searchText);
      }).toList();
    });
  }
  
  void _selectStatus(String status) {
    setState(() {
      _selectedStatus = status;
    });
    _filterOrders();
  }
  
  String _getSupplierName(Map<String, dynamic> order) {
    // Handle supplier info which might be nested or flat
    if (order['supplier_id'] is Map) {
      return order['supplier_id']['company_name'] ?? 'Unknown Supplier';
    } else if (order['supplier_id'] != null) {
      // Try to find matching supplier
      final supplierId = order['supplier_id'];
      final supplier = _suppliers.firstWhere(
        (s) => s['supplier_id'] == supplierId,
        orElse: () => {},
      );
      return supplier['company_name'] ?? 'Unknown Supplier';
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
              headingText: "Purchase Orders",
              rightIcon: Iconsax.menu_1,
              onRightButtonPressed: _openSideMenu,
            ),
            
            const SizedBox(height: 20),
            
            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: CustomSearchBar(
                controller: _searchController,
                hintText: "Search orders...",
                onSearch: _filterOrders,
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Status filters
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: _statusFilters.map((status) => 
                  _buildStatusChip(status, _selectedStatus == status)
                ).toList(),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Column Headers
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(
                      "Order Details",
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      "Supplier",
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      "Status",
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Text(
                      "Amount",
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.end,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 8),
            
            // Main content - Purchase Orders List
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
                        return _buildOrderItem(order);
                      },
                    ),
            ),
            
            // Bottom padding for the navbar
            const SizedBox(height: 70),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFFD0F0C0),
        onPressed: () {
          _showCreateOrderModal(context);
        },
        child: const Icon(Iconsax.add, color: Color(0xFF222222)),
      ),
      bottomNavigationBar: const DynamicFooter(),
    );
  }
  
  Widget _buildStatusChip(String label, bool isSelected) {
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
            _selectStatus(label);
          }
        },
      ),
    );
  }
  
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Iconsax.document_text, 
            size: 64, 
            color: Colors.white.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            _selectedStatus != 'All'
                ? "No $_selectedStatus orders found"
                : "No purchase orders found",
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () {
              _showCreateOrderModal(context);
            },
            icon: const Icon(Iconsax.add, color: Color(0xFFD0F0C0)),
            label: const Text(
              "Create New Order",
              style: TextStyle(color: Color(0xFFD0F0C0)),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildOrderItem(Map<String, dynamic> order) {
    // Format date
    String orderDate = 'N/A';
    String expectedDate = 'N/A';
    
    try {
      if (order['created_at'] != null) {
        final date = DateTime.parse(order['created_at']);
        orderDate = DateFormat('MMM d, yyyy').format(date);
      }
      
      if (order['expected_delivery_date'] != null) {
        final date = DateTime.parse(order['expected_delivery_date']);
        expectedDate = DateFormat('MMM d, yyyy').format(date);
      }
    } catch (e) {
      print('Error formatting dates: $e');
    }
    
    // Get supplier name
    final supplierName = _getSupplierName(order);
    
    // Get status color
    Color statusColor;
    switch (order['status']?.toString().toLowerCase()) {
      case 'pending':
        statusColor = Colors.orange;
        break;
      case 'approved':
        statusColor = Colors.blue;
        break;
      case 'received':
        statusColor = Colors.green;
        break;
      case 'cancelled':
        statusColor = Colors.red;
        break;
      default:
        statusColor = Colors.grey;
    }
    
    return InkWell(
      onTap: () {
        _showOrderDetailsModal(context, order);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF222222),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            // Order details
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "PO-${order['purchase_order_id'].toString().substring(0, 8)}",
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Iconsax.calendar,
                        size: 12,
                        color: Colors.white.withOpacity(0.5),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        "Created: $orderDate",
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  if (order['expected_delivery_date'] != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Row(
                        children: [
                          Icon(
                            Iconsax.truck_tick,
                            size: 12,
                            color: Colors.white.withOpacity(0.5),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            "Expected: $expectedDate",
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.5),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            
            // Supplier
            Expanded(
              flex: 2,
              child: Text(
                supplierName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            
            // Status
            Expanded(
              flex: 2,
              child: Container(
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  order['status'] ?? 'Unknown',
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
            
            // Amount
            Expanded(
              flex: 1,
              child: Text(
                order['total_amount'] != null 
                    ? '\$${(order['total_amount'] as num).toStringAsFixed(2)}'
                    : '—',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
                textAlign: TextAlign.end,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateOrderModal(BuildContext context) {
    // Show message if no suppliers or inventory items
    if (_suppliers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Iconsax.warning_2, color: Colors.white),
              const SizedBox(width: 10),
              const Expanded(
                child: Text('You need to add suppliers before creating purchase orders.'),
              ),
              TextButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  Navigator.pushNamed(context, '/suppliers');
                },
                child: const Text('Add Suppliers'),
              )
            ],
          ),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 5),
        ),
      );
      return;
    }
    
    if (_inventoryItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Iconsax.warning_2, color: Colors.white),
              const SizedBox(width: 10),
              const Expanded(
                child: Text('You need to add inventory items before creating purchase orders.'),
              ),
              TextButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  Navigator.pushNamed(context, '/stock');
                },
                child: const Text('Add Items'),
              )
            ],
          ),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 5),
        ),
      );
      return;
    }

    // Initialize for order creation
    var selectedSupplierId = _suppliers.isNotEmpty ? _suppliers[0]['supplier_id'] : null;
    DateTime? deliveryDate = DateTime.now().add(const Duration(days: 7));
    final orderItems = <Map<String, dynamic>>[];
    double totalAmount = 0.0;
    final notesController = TextEditingController();
    
    // Function to update total amount
    void updateTotalAmount() {
      totalAmount = 0;
      for (var item in orderItems) {
        totalAmount += (item['quantity'] ?? 0) * (item['unit_price'] ?? 0);
      }
    }
    
    // Function to add a new item to the order
    void addItemToOrder(Map<String, dynamic> inventoryItem, double quantity) {
      // Check if item already exists in order
      final existingItemIndex = orderItems.indexWhere(
        (item) => item['inventory_id'] == inventoryItem['inventory_id']
      );
      
      if (existingItemIndex >= 0) {
        // Update existing item
        orderItems[existingItemIndex]['quantity'] = quantity;
      } else {
        // Add new item
        orderItems.add({
          'inventory_id': inventoryItem['inventory_id'],
          'item_name': inventoryItem['item_name'],
          'unit': inventoryItem['unit'],
          'quantity': quantity,
          'unit_price': inventoryItem['price_per_unit'] ?? 0.0,
        });
      }
      
      updateTotalAmount();
    }
    
    // Function to remove item from order
    void removeItemFromOrder(int index) {
      orderItems.removeAt(index);
      updateTotalAmount();
    }
    
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
                          'Create Purchase Order',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Supplier dropdown
                      DropdownButtonFormField<String>(
                        decoration: _inputDecoration('Select Supplier'),
                        dropdownColor: const Color(0xFF333333),
                        value: selectedSupplierId,
                        items: _suppliers.map((supplier) {
                          return DropdownMenuItem<String>(
                            value: supplier['supplier_id'],
                            child: Text(
                              supplier['company_name'] ?? 'Unknown Supplier',
                              style: const TextStyle(color: Colors.white),
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedSupplierId = value;
                          });
                        },
                        style: const TextStyle(color: Colors.white),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Expected delivery date picker
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          'Expected Delivery Date',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 14,
                          ),
                        ),
                        subtitle: Text(
                          deliveryDate != null 
                              ? DateFormat('MMM d, yyyy').format(deliveryDate!)
                              : 'Not set',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.6),
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(
                                Iconsax.calendar,
                                color: Color(0xFFD0F0C0),
                              ),
                              onPressed: () async {
                                final pickedDate = await showDatePicker(
                                  context: context,
                                  initialDate: deliveryDate ?? DateTime.now().add(const Duration(days: 7)),
                                  firstDate: DateTime.now(),
                                  lastDate: DateTime.now().add(const Duration(days: 365)),
                                  builder: (context, child) {
                                    return Theme(
                                      data: Theme.of(context).copyWith(
                                        colorScheme: const ColorScheme.dark(
                                          primary: Color(0xFFD0F0C0),
                                          onPrimary: Color(0xFF222222),
                                          surface: Color(0xFF222222),
                                          onSurface: Colors.white,
                                        ),
                                      ),
                                      child: child!,
                                    );
                                  },
                                );
                                
                                if (pickedDate != null) {
                                  setState(() {
                                    deliveryDate = pickedDate;
                                  });
                                }
                              },
                            ),
                            if (deliveryDate != null)
                              IconButton(
                                icon: const Icon(
                                  Iconsax.close_circle,
                                  color: Colors.white54,
                                ),
                                onPressed: () {
                                  setState(() {
                                    deliveryDate = null;
                                  });
                                },
                              ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Notes
                      TextFormField(
                        controller: notesController,
                        decoration: _inputDecoration('Notes (optional)'),
                        style: const TextStyle(color: Colors.white),
                        maxLines: 2,
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Order Items Section
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
                          TextButton.icon(
                            onPressed: () {
                              _showAddItemDialog(context, _inventoryItems, (item, quantity) {
                                setState(() {
                                  addItemToOrder(item, quantity);
                                });
                              });
                            },
                            icon: const Icon(Iconsax.add, color: Color(0xFFD0F0C0), size: 18),
                            label: const Text(
                              'Add Item',
                              style: TextStyle(color: Color(0xFFD0F0C0)),
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 8),
                      
                      // Item list
                      Expanded(
                        child: orderItems.isEmpty
                            ? Center(
                                child: Text(
                                  'No items added yet',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.5),
                                    fontSize: 14,
                                  ),
                                ),
                              )
                            : ListView.builder(
                                controller: scrollController,
                                itemCount: orderItems.length,
                                itemBuilder: (context, index) {
                                  final item = orderItems[index];
                                  return ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    title: Text(
                                      item['item_name'] ?? 'Unknown Item',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                      ),
                                    ),
                                    subtitle: Text(
                                      'Qty: ${item['quantity']} ${item['unit'] ?? ''} • \$${(item['unit_price'] ?? 0).toStringAsFixed(2)} each',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.5),
                                        fontSize: 12,
                                      ),
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          '\$${((item['quantity'] ?? 0) * (item['unit_price'] ?? 0)).toStringAsFixed(2)}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 14,
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(Iconsax.trash, color: Colors.red, size: 18),
                                          onPressed: () {
                                            setState(() {
                                              removeItemFromOrder(index);
                                            });
                                          },
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                      ),
                      
                      // Total amount
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
                              'Total Amount:',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '\$${totalAmount.toStringAsFixed(2)}',
                              style: const TextStyle(
                                color: Color(0xFFD0F0C0),
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                      
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
                            onPressed: orderItems.isEmpty || selectedSupplierId == null
                                ? null // Disable if no items or supplier
                                : () {
                                    // Save purchase order
                                    _savePurchaseOrder(
                                      context,
                                      supplierId: selectedSupplierId!,
                                      deliveryDate: deliveryDate,
                                      notes: notesController.text,
                                      orderItems: orderItems,
                                      totalAmount: totalAmount,
                                    );
                                  },
                            child: const Text('Create Order'),
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
  
  void _showAddItemDialog(
    BuildContext context,
    List<Map<String, dynamic>> inventoryItems,
    Function(Map<String, dynamic>, double) onItemAdded,
  ) {
    Map<String, dynamic>? selectedItem = inventoryItems.isNotEmpty ? inventoryItems[0] : null;
    double quantity = 1.0;
    
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF222222),
              title: const Text(
                'Add Item to Order',
                style: TextStyle(color: Colors.white),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Item selection
                  DropdownButtonFormField<String>(
                    decoration: _inputDecoration('Select Item'),
                    dropdownColor: const Color(0xFF333333),
                    value: selectedItem?['inventory_id'],
                    items: inventoryItems.map((item) {
                      return DropdownMenuItem<String>(
                        value: item['inventory_id'],
                        child: Text(
                          item['item_name'] ?? 'Unknown Item',
                          style: const TextStyle(color: Colors.white),
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedItem = inventoryItems.firstWhere(
                          (item) => item['inventory_id'] == value,
                        );
                      });
                    },
                    style: const TextStyle(color: Colors.white),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Quantity input
                  TextFormField(
                    initialValue: quantity.toString(),
                    decoration: _inputDecoration('Quantity').copyWith(
                      suffixText: selectedItem?['unit'] ?? '',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: const TextStyle(color: Colors.white),
                    onChanged: (value) {
                      setState(() {
                        quantity = double.tryParse(value) ?? 1.0;
                      });
                    },
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Price info
                  if (selectedItem != null)
                    Text(
                      'Price: \$${(selectedItem!['price_per_unit'] ?? 0).toStringAsFixed(2)} per ${selectedItem!['unit'] ?? 'unit'}',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD0F0C0),
                    foregroundColor: const Color(0xFF222222),
                  ),
                  onPressed: selectedItem == null || quantity <= 0
                      ? null
                      : () {
                          Navigator.pop(context);
                          onItemAdded(selectedItem!, quantity);
                        },
                  child: const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }
  
  Future<void> _savePurchaseOrder(
    BuildContext context, {
    required String supplierId,
    required List<Map<String, dynamic>> orderItems,
    required double totalAmount,
    DateTime? deliveryDate,
    String? notes,
  }) async {
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
      
      // Create new purchase order
      final result = await _supabase
          .from('purchase_orders')
          .insert({
            'supplier_id': supplierId,
            'expected_delivery_date': deliveryDate?.toIso8601String(),
            'status': 'Pending',
            'total_amount': totalAmount,
            'notes': notes,
            'restaurant_id': restaurantId,
          })
          .select('purchase_order_id')
          .single();
          
      final purchaseOrderId = result['purchase_order_id'];
      
      // Add order items
      for (var item in orderItems) {
        await _supabase
            .from('purchase_order_items')
            .insert({
              'purchase_order_id': purchaseOrderId,
              'inventory_id': item['inventory_id'],
              'quantity': item['quantity'],
              'unit_price': item['unit_price'],
              'notes': item['notes'],
            });
      }
      
      // Refresh purchase orders
      await _fetchPurchaseOrders();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Purchase order created successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error saving purchase order: $e');
      
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating purchase order: $e'),
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
  
  void _showOrderDetailsModal(BuildContext context, Map<String, dynamic> order) {
    // TODO: Implement order details modal
    // Should show the order items, allow changing status, etc.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Order details feature coming soon'),
        backgroundColor: Colors.blue,
      ),
    );
  }
  
  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
      filled: true,
      fillColor: const Color(0xFF2A2A2A),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFD0F0C0), width: 1),
      ),
    );
  }
}
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

class WasteManagementPage extends StatefulWidget {
  
  const WasteManagementPage({
    super.key,
  });

  @override
  State<WasteManagementPage> createState() => _WasteManagementPageState();
}

class _WasteManagementPageState extends State<WasteManagementPage> {
  final SupabaseClient _supabase = Supabase.instance.client;
  final TextEditingController _searchController = TextEditingController();
  
  bool _isLoading = true;
  List<Map<String, dynamic>> _wasteRecords = [];
  List<Map<String, dynamic>> _filteredRecords = [];
  List<Map<String, dynamic>> _inventoryItems = [];
  
  // Date range filter
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  
  // Waste reason options
  final List<String> _wasteReasons = [
    'Expired',
    'Damaged',
    'Spoiled',
    'Cooking Error',
    'Quality Control',
    'Overproduction',
    'Other'
  ];
  
  @override
  void initState() {
    super.initState();
    
    // Update the navbar state with the correct index
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndCreateWasteTable();
      _loadData();
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
  
  Future<void> _checkAndCreateWasteTable() async {
    try {
      // Try to query waste table to see if it exists
      try {
        await _supabase.from('inventory_waste').select('waste_id').limit(1);
        return; // Table exists
      } catch (e) {
        print('Inventory waste table may not exist: $e');
        
        // Ask user if they want to create the table
        if (mounted) {
          final shouldCreate = await showDialog<bool>(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              backgroundColor: const Color(0xFF222222),
              title: const Text('Create Waste Tracking Table?', style: TextStyle(color: Colors.white)),
              content: const Text(
                'The inventory waste tracking table does not exist. Would you like to create it now?',
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
                  child: const Text('Create Table'),
                ),
              ],
            ),
          );
          
          if (shouldCreate != true) return;
          
          // Create table via RPC
          try {
            await _supabase.rpc('create_waste_tracking_table');
          } catch (e) {
            print('Error creating waste tracking table: $e');
            
            // Show error to user
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Failed to create waste tracking table. Please contact your administrator.'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        }
      }
    } catch (e) {
      print('Error checking/creating waste table: $e');
    }
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      await Future.wait([
        _fetchWasteRecords(),
        _fetchInventoryItems(),
      ]);
    } catch (e) {
      print('Error loading data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }
  
  Future<void> _fetchWasteRecords() async {
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
        // Format dates for query
        final startDateStr = DateFormat('yyyy-MM-dd').format(_startDate);
        final endDateStr = DateFormat('yyyy-MM-dd').format(_endDate.add(const Duration(days: 1)));
        
        // Fetch waste records with inventory item details
        final wasteResult = await _supabase
            .from('inventory_waste')
            .select('''
              waste_id,
              inventory_id,
              quantity,
              cost,
              reason,
              notes,
              created_at,
              created_by,
              inventory:inventory_id (
                item_name,
                unit,
                category
              )
            ''')
            .eq('restaurant_id', restaurantId)
            .gte('created_at', startDateStr)
            .lt('created_at', endDateStr)
            .order('created_at', ascending: false);
            
        setState(() {
          _wasteRecords = wasteResult;
          _applySearch();
        });
      } catch (e) {
        print('Error fetching waste records: $e');
        
        // Try simplified query if join fails
        try {
          final startDateStr = DateFormat('yyyy-MM-dd').format(_startDate);
          final endDateStr = DateFormat('yyyy-MM-dd').format(_endDate.add(const Duration(days: 1)));
          
          final wasteResult = await _supabase
              .from('inventory_waste')
              .select()
              .eq('restaurant_id', restaurantId)
              .gte('created_at', startDateStr)
              .lt('created_at', endDateStr)
              .order('created_at', ascending: false);
              
          setState(() {
            _wasteRecords = wasteResult;
            _applySearch();
          });
        } catch (simpleError) {
          print('Error with simplified waste records query: $simpleError');
          setState(() {
            _wasteRecords = [];
            _filteredRecords = [];
          });
        }
      }
    } catch (e) {
      print('Error in _fetchWasteRecords: $e');
      setState(() {
        _wasteRecords = [];
        _filteredRecords = [];
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
          .select('inventory_id, item_name, unit, category, price_per_unit')
          .eq('restaurant_id', restaurantId)
          .order('item_name', ascending: true);
          
      setState(() {
        _inventoryItems = inventoryResult;
      });
    } catch (e) {
      print('Error fetching inventory items: $e');
    }
  }
  
  void _applySearch() {
    final searchText = _searchController.text.toLowerCase();
    
    if (searchText.isEmpty) {
      setState(() {
        _filteredRecords = _wasteRecords;
      });
      return;
    }
    
    setState(() {
      _filteredRecords = _wasteRecords.where((record) {
        // Get item name from nested inventory object if available
        String itemName = '';
        String category = '';
        
        if (record['inventory'] is Map) {
          itemName = record['inventory']['item_name']?.toString().toLowerCase() ?? '';
          category = record['inventory']['category']?.toString().toLowerCase() ?? '';
        }
        
        final reason = record['reason']?.toString().toLowerCase() ?? '';
        final notes = record['notes']?.toString().toLowerCase() ?? '';
        
        return itemName.contains(searchText) || 
               category.contains(searchText) || 
               reason.contains(searchText) || 
               notes.contains(searchText);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final totalWasteCost = _calculateTotalWasteCost(_filteredRecords);
    
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            HeaderWidget(
              leftIcon: Iconsax.arrow_left_1,
              onLeftButtonPressed: () => Navigator.pop(context),
              headingText: "Waste Management",
              rightIcon: Iconsax.menu_1,
              onRightButtonPressed: _openSideMenu,
            ),
            
            const SizedBox(height: 12),
            
            // Date range selector
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _selectDate(context, true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF222222),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Iconsax.calendar,
                              size: 16,
                              color: Colors.white.withOpacity(0.7),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              DateFormat('MMM d, yyyy').format(_startDate),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8.0),
                    child: Text(
                      "to",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _selectDate(context, false),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF222222),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Iconsax.calendar,
                              size: 16,
                              color: Colors.white.withOpacity(0.7),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              DateFormat('MMM d, yyyy').format(_endDate),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: CustomSearchBar(
                controller: _searchController,
                hintText: "Search waste records...",
                onSearch: _applySearch,
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Total waste cost summary
            if (_filteredRecords.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A2A2A),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Total Waste Cost (${_filteredRecords.length} items):",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        "\$${totalWasteCost.toStringAsFixed(2)}",
                        style: const TextStyle(
                          color: Color(0xFFFF9A8D),
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            
            const SizedBox(height: 12),
            
            // Main Content - Waste Records List
            Expanded(
              child: _isLoading 
                ? const Center(child: CircularProgressIndicator(color: Color(0xFFD0F0C0)))
                : _filteredRecords.isEmpty 
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      itemCount: _filteredRecords.length,
                      itemBuilder: (context, index) {
                        final record = _filteredRecords[index];
                        return _buildWasteRecordItem(record);
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
          _showAddWasteDialog(context);
        },
        child: const Icon(Iconsax.add, color: Color(0xFF222222)),
      ),
      bottomNavigationBar: const DynamicFooter(),
    );
  }
  
  double _calculateTotalWasteCost(List<Map<String, dynamic>> records) {
    double total = 0;
    for (var record in records) {
      total += (record['cost'] as num?)?.toDouble() ?? 0;
    }
    return total;
  }
  
  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final DateTime initialDate = isStart ? _startDate : _endDate;
    final DateTime firstDate = isStart 
        ? DateTime.now().subtract(const Duration(days: 365)) 
        : _startDate;
    final DateTime lastDate = isStart 
        ? _endDate 
        : DateTime.now();
        
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
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
        if (isStart) {
          _startDate = pickedDate;
        } else {
          _endDate = pickedDate;
        }
      });
      
      // Refresh data
      _fetchWasteRecords();
    }
  }
  
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Iconsax.trash, 
            size: 64, 
            color: Colors.white.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            "No waste records found\nin selected date range",
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () {
              _showAddWasteDialog(context);
            },
            icon: const Icon(Iconsax.add, color: Color(0xFFD0F0C0)),
            label: const Text(
              "Record Waste",
              style: TextStyle(color: Color(0xFFD0F0C0)),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildWasteRecordItem(Map<String, dynamic> record) {
    // Get item details
    String itemName = 'Unknown Item';
    String unit = '';
    String category = '';
    
    if (record['inventory'] is Map) {
      itemName = record['inventory']['item_name'] ?? 'Unknown Item';
      unit = record['inventory']['unit'] ?? '';
      category = record['inventory']['category'] ?? '';
    } else if (record['inventory_id'] != null) {
      // Try to find item in inventory list
      final inventoryItem = _inventoryItems.firstWhere(
        (item) => item['inventory_id'] == record['inventory_id'],
        orElse: () => {},
      );
      
      if (inventoryItem.isNotEmpty) {
        itemName = inventoryItem['item_name'] ?? 'Unknown Item';
        unit = inventoryItem['unit'] ?? '';
        category = inventoryItem['category'] ?? '';
      }
    }
    
    // Format date
    String wasteDate = 'Unknown Date';
    
    try {
      if (record['created_at'] != null) {
        final date = DateTime.parse(record['created_at']);
        wasteDate = DateFormat('MMM d, yyyy • h:mm a').format(date);
      }
    } catch (e) {
      print('Error formatting date: $e');
    }
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF222222),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row with item and cost
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      itemName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (category.isNotEmpty)
                      Text(
                        category,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF9A8D).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  "\$${(record['cost'] as num?)?.toStringAsFixed(2) ?? '0.00'}",
                  style: const TextStyle(
                    color: Color(0xFFFF9A8D),
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          // Middle row with quantity and reason
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF333333),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  "${record['quantity']} $unit",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF333333),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  record['reason'] ?? 'Unspecified',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          // Bottom row with date and notes
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Iconsax.calendar,
                size: 12,
                color: Colors.white.withOpacity(0.5),
              ),
              const SizedBox(width: 4),
              Text(
                wasteDate,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 12,
                ),
              ),
            ],
          ),
          
          if (record['notes'] != null && record['notes'].toString().isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                record['notes'],
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
      ),
    );
  }
  
  void _showAddWasteDialog(BuildContext context) {
    // Check if we have inventory items
    if (_inventoryItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Iconsax.warning_2, color: Colors.white),
              const SizedBox(width: 10),
              const Expanded(
                child: Text('You need to add inventory items before recording waste.'),
              ),
              TextButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  Navigator.pushNamed(context, '/stock');
                },
                child: const Text('Add Inventory'),
              )
            ],
          ),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 5),
        ),
      );
      return;
    }
    
    // Selected item and values
    Map<String, dynamic>? selectedItem = _inventoryItems.isNotEmpty ? _inventoryItems[0] : null;
    double quantity = 1.0;
    double cost = selectedItem != null ? (selectedItem['price_per_unit'] as num?)?.toDouble() ?? 0 : 0;
    String reason = _wasteReasons[0];
    String notes = '';
    
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            // Update cost based on quantity and price
            void updateCost() {
              if (selectedItem != null) {
                final unitPrice = (selectedItem?['price_per_unit'] as num?)?.toDouble() ?? 0;
                cost = unitPrice * quantity;
              }
            }
            
            return AlertDialog(
              backgroundColor: const Color(0xFF222222),
              title: const Text(
                'Record Waste',
                style: TextStyle(color: Colors.white),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Item selection
                    DropdownButtonFormField<String>(
                      decoration: _inputDecoration('Select Item'),
                      dropdownColor: const Color(0xFF333333),
                      value: selectedItem?['inventory_id'],
                      items: _inventoryItems.map((item) {
                        return DropdownMenuItem<String>(
                          value: item['inventory_id'],
                          child: Text(
                            "${item['item_name']} (${item['unit']})",
                            style: const TextStyle(color: Colors.white),
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedItem = _inventoryItems.firstWhere(
                            (item) => item['inventory_id'] == value,
                          );
                          updateCost();
                        });
                      },
                      style: const TextStyle(color: Colors.white),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Quantity row
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            initialValue: quantity.toString(),
                            decoration: _inputDecoration('Quantity').copyWith(
                              suffixText: selectedItem?['unit'] ?? '',
                            ),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            style: const TextStyle(color: Colors.white),
                            onChanged: (value) {
                              setState(() {
                                quantity = double.tryParse(value) ?? 1.0;
                                updateCost();
                              });
                            },
                          ),
                        ),
                        
                        const SizedBox(width: 12),
                        
                        Expanded(
                          child: TextFormField(
                            initialValue: cost.toStringAsFixed(2),
                            decoration: _inputDecoration('Cost').copyWith(
                              prefixText: '\$ ',
                            ),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            style: const TextStyle(color: Colors.white),
                            onChanged: (value) {
                              setState(() {
                                cost = double.tryParse(value) ?? 0;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Reason selection
                    DropdownButtonFormField<String>(
                      decoration: _inputDecoration('Reason'),
                      dropdownColor: const Color(0xFF333333),
                      value: reason,
                      items: _wasteReasons.map((r) {
                        return DropdownMenuItem<String>(
                          value: r,
                          child: Text(
                            r,
                            style: const TextStyle(color: Colors.white),
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          reason = value ?? _wasteReasons[0];
                        });
                      },
                      style: const TextStyle(color: Colors.white),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Notes
                    TextFormField(
                      initialValue: notes,
                      decoration: _inputDecoration('Notes (optional)'),
                      style: const TextStyle(color: Colors.white),
                      maxLines: 3,
                      onChanged: (value) {
                        notes = value;
                      },
                    ),
                  ],
                ),
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
                  onPressed: selectedItem == null
                      ? null
                      : () {
                          Navigator.pop(context);
                          _saveWasteRecord(
                            inventoryId: selectedItem!['inventory_id'],
                            quantity: quantity,
                            cost: cost,
                            reason: reason,
                            notes: notes,
                          );
                        },
                  child: const Text('Record Waste'),
                ),
              ],
            );
          },
        );
      },
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
  
  Future<void> _saveWasteRecord({
    required String inventoryId,
    required double quantity,
    required double cost,
    required String reason,
    String? notes,
  }) async {
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
      
      // 1. Record waste in inventory_waste table
      await _supabase
          .from('inventory_waste')
          .insert({
            'inventory_id': inventoryId,
            'quantity': quantity,
            'cost': cost,
            'reason': reason,
            'notes': notes,
            'created_by': user.id,
            'restaurant_id': restaurantId,
          });
          
      // 2. Update inventory quantity
      try {
        // Get current inventory quantity
        final inventoryResult = await _supabase
            .from('inventory')
            .select('quantity')
            .eq('inventory_id', inventoryId)
            .single();
            
        final currentQty = inventoryResult['quantity'] as num? ?? 0;
        final newQty = currentQty - quantity;
        
        // Update inventory quantity
        await _supabase
            .from('inventory')
            .update({
              'quantity': newQty >= 0 ? newQty : 0,
              'last_updated': DateTime.now().toIso8601String(),
            })
            .eq('inventory_id', inventoryId);
      } catch (e) {
        print('Error updating inventory quantity: $e');
        // Continue even if inventory update fails
      }
      
      // 3. Record transaction if table exists
      try {
        await _supabase
            .from('inventory_transactions')
            .insert({
              'inventory_id': inventoryId,
              'transaction_type': 'waste',
              'quantity': -quantity, // Negative for waste
              'notes': 'Waste: $reason${notes != null && notes.isNotEmpty ? ' - $notes' : ''}',
              'user_id': user.id,
              'restaurant_id': restaurantId,
            });
      } catch (e) {
        print('Inventory transactions table may not exist: $e');
        // Continue even if transaction recording fails
      }
      
      // 4. Refresh waste records
      await _fetchWasteRecords();
      
      // 5. Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Waste recorded successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error saving waste record: $e');
      
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error recording waste: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }
}
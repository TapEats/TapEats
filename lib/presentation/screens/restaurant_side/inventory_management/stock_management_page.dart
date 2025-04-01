import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tapeats/presentation/state_management/navbar_state.dart';
import 'package:tapeats/presentation/widgets/header_widget.dart';
import 'package:tapeats/presentation/widgets/footer_widget.dart';
import 'package:tapeats/presentation/widgets/search_bar.dart';
import 'package:tapeats/presentation/widgets/sidemenu_overlay.dart';

class StockManagementPage extends StatefulWidget {
  // Make selectedIndex optional with a default value
  final int selectedIndex;
  
  const StockManagementPage({
    super.key,
    this.selectedIndex = 10, // Default to inventory tab index - adjust this to match your app's navbar structure
  });

  @override
  State<StockManagementPage> createState() => _StockManagementPageState();
}

class _StockManagementPageState extends State<StockManagementPage> {
  final SupabaseClient _supabase = Supabase.instance.client;
  final TextEditingController _searchController = TextEditingController();
  
  bool _isLoading = true;
  List<Map<String, dynamic>> _inventoryItems = [];
  List<Map<String, dynamic>> _filteredItems = [];
  String _selectedCategory = "All";
  List<String> _categories = ["All"];
  
  @override
  void initState() {
    super.initState();
    
    // Update the navbar state with the correct index
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<NavbarState>(context, listen: false).updateIndex(widget.selectedIndex);
      _fetchInventoryItems();
    });
  }
  
  @override
  void dispose() {
    _searchController.dispose();
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

  Future<void> _fetchInventoryItems() async {
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
      
      // Fetch inventory items WITHOUT supplier info to avoid errors
      final inventoryResult = await _supabase
          .from('inventory')
          .select('''
            inventory_id,
            item_name,
            category,
            quantity,
            min_quantity,
            unit,
            price_per_unit,
            expiry_date,
            last_updated,
            supplier_id
          ''')
          .eq('restaurant_id', restaurantId);
          
      // Extract unique categories
      final categories = ["All"];
      for (var item in inventoryResult) {
        if (item['category'] != null && 
            !categories.contains(item['category'])) {
          categories.add(item['category']);
        }
      }
      
      setState(() {
        _inventoryItems = inventoryResult;
        _filteredItems = inventoryResult;
        _categories = categories;
        _isLoading = false;
      });
      
    } catch (e) {
      print('Error fetching inventory items: $e');
      setState(() => _isLoading = false);
    }
  }
  
  void _filterItems() {
    final searchText = _searchController.text.toLowerCase();
    
    setState(() {
      if (_selectedCategory == "All") {
        // Filter only by search text
        if (searchText.isEmpty) {
          _filteredItems = _inventoryItems;
        } else {
          _filteredItems = _inventoryItems.where((item) => 
              item['item_name'].toString().toLowerCase().contains(searchText)).toList();
        }
      } else {
        // Filter by category and search text
        _filteredItems = _inventoryItems.where((item) {
          final matchesCategory = item['category'] == _selectedCategory;
          final matchesSearch = searchText.isEmpty || 
              item['item_name'].toString().toLowerCase().contains(searchText);
          return matchesCategory && matchesSearch;
        }).toList();
      }
    });
  }
  
  void _selectCategory(String category) {
    setState(() {
      _selectedCategory = category;
    });
    _filterItems();
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
              headingText: "Stock Management",
              rightIcon: Iconsax.menu_1,
              onRightButtonPressed: _openSideMenu,
            ),
            
            const SizedBox(height: 20),
            
            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: CustomSearchBar(
                controller: _searchController,
                hintText: "Search inventory items...",
                onSearch: _filterItems,
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Category Filter Tabs
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: _categories.map((category) => 
                  _buildCategoryChip(category, _selectedCategory == category)
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
                    flex: 6,
                    child: Text(
                      "Item",
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
                      "Qty",
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      "Price",
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
            
            // Main content - Inventory List
            Expanded(
              child: _isLoading 
                ? const Center(child: CircularProgressIndicator(color: Color(0xFFD0F0C0)))
                : _filteredItems.isEmpty 
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      itemCount: _filteredItems.length,
                      itemBuilder: (context, index) {
                        final item = _filteredItems[index];
                        return _buildInventoryItem(item);
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
          _showAddEditItemModal(context);
        },
        child: const Icon(Iconsax.add, color: Color(0xFF222222)),
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
            Iconsax.box, 
            size: 60, 
            color: Colors.white.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            _selectedCategory != "All" 
                ? "No items found in this category" 
                : "No inventory items found",
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () {
              _showAddEditItemModal(context);
            },
            icon: const Icon(Iconsax.add, color: Color(0xFFD0F0C0)),
            label: const Text(
              "Add New Item",
              style: TextStyle(color: Color(0xFFD0F0C0)),
            ),
          ),
        ],
      ),
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
            _selectCategory(label);
          }
        },
      ),
    );
  }
  
  Widget _buildInventoryItem(Map<String, dynamic> item) {
    // Check if quantity is below minimum
    final quantity = item['quantity'] as num? ?? 0;
    final minQuantity = item['min_quantity'] as num? ?? 0;
    final isLowStock = quantity < minQuantity;
    
    // Check if expiry date is within 7 days
    bool isExpiringSoon = false;
    if (item['expiry_date'] != null) {
      try {
        final expiryDate = DateTime.parse(item['expiry_date']);
        final now = DateTime.now();
        final difference = expiryDate.difference(now).inDays;
        isExpiringSoon = difference >= 0 && difference <= 7;
      } catch (e) {
        // Handle invalid date format
      }
    }
    
    return InkWell(
      onTap: () {
        _showAddEditItemModal(context, item: item);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF222222),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isLowStock 
                ? const Color(0xFFFF6B6B) 
                : isExpiringSoon 
                    ? const Color(0xFFFFD166) 
                    : Colors.transparent,
            width: isLowStock || isExpiringSoon ? 1.0 : 0,
          ),
        ),
        child: Row(
          children: [
            // Item information
            Expanded(
              flex: 6,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        item['item_name'] ?? 'Unnamed Item',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (isLowStock)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF6B6B).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            "LOW",
                            style: TextStyle(
                              color: Color(0xFFFF6B6B),
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      if (isExpiringSoon && !isLowStock)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFD166).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            "EXPIRING",
                            style: TextStyle(
                              color: Color(0xFFFFD166),
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item['category'] ?? 'Uncategorized',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            
            // Quantity
            Expanded(
              flex: 2,
              child: Container(
                alignment: Alignment.center,
                child: RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: '${item['quantity'] ?? 0}',
                        style: TextStyle(
                          color: isLowStock 
                              ? const Color(0xFFFF6B6B) 
                              : Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      TextSpan(
                        text: ' ${item['unit'] ?? ''}',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            
            // Price
            Expanded(
              flex: 2,
              child: Text(
                item['price_per_unit'] != null ? (item['price_per_unit'] as num).toStringAsFixed(2): '—',
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
  
  void _showAddEditItemModal(BuildContext context, {Map<String, dynamic>? item}) {
    // Controllers for the form fields
    final nameController = TextEditingController(text: item?['item_name'] ?? '');
    final categoryController = TextEditingController(text: item?['category'] ?? '');
    final quantityController = TextEditingController(
        text: item?['quantity'] != null ? (item!['quantity'] as num).toString() : '');
    final minQuantityController = TextEditingController(
        text: item?['min_quantity'] != null ? (item!['min_quantity'] as num).toString() : '');
    final unitController = TextEditingController(text: item?['unit'] ?? '');
    final priceController = TextEditingController(
        text: item?['price_per_unit'] != null ? (item!['price_per_unit'] as num).toString() : '');
    
    DateTime? expiryDate;
    if (item?['expiry_date'] != null) {
      try {
        expiryDate = DateTime.parse(item!['expiry_date']);
      } catch (e) {
        // Invalid date format
      }
    }
    
    // Form key for validation
    final formKey = GlobalKey<FormState>();
    
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
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 16,
                right: 16,
                top: 16,
              ),
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Modal title
                      Center(
                        child: Text(
                          item != null ? 'Edit Inventory Item' : 'Add New Item',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Form fields
                      TextFormField(
                        controller: nameController,
                        decoration: _inputDecoration('Item Name'),
                        style: const TextStyle(color: Colors.white),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter an item name';
                          }
                          return null;
                        },
                      ),
                      
                      const SizedBox(height: 16),
                      
                      TextFormField(
                        controller: categoryController,
                        decoration: _inputDecoration('Category'),
                        style: const TextStyle(color: Colors.white),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: quantityController,
                              decoration: _inputDecoration('Quantity'),
                              keyboardType: TextInputType.number,
                              style: const TextStyle(color: Colors.white),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Required';
                                }
                                if (double.tryParse(value) == null) {
                                  return 'Invalid number';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: unitController,
                              decoration: _inputDecoration('Unit'),
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 16),
                      
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: minQuantityController,
                              decoration: _inputDecoration('Min Quantity'),
                              keyboardType: TextInputType.number,
                              style: const TextStyle(color: Colors.white),
                              validator: (value) {
                                if (value != null && value.isNotEmpty) {
                                  if (double.tryParse(value) == null) {
                                    return 'Invalid number';
                                  }
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: priceController,
                              decoration: _inputDecoration('Price Per Unit'),
                              keyboardType: TextInputType.number,
                              style: const TextStyle(color: Colors.white),
                              validator: (value) {
                                if (value != null && value.isNotEmpty) {
                                  if (double.tryParse(value) == null) {
                                    return 'Invalid number';
                                  }
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Expiry date picker
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          'Expiry Date',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 14,
                          ),
                        ),
                        subtitle: Text(
                          expiryDate != null 
                              ? '${expiryDate?.day}/${expiryDate?.month}/${expiryDate?.year}'
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
                                  initialDate: expiryDate ?? DateTime.now(),
                                  firstDate: DateTime.now(),
                                  lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
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
                                    expiryDate = pickedDate;
                                  });
                                }
                              },
                            ),
                            if (expiryDate != null)
                              IconButton(
                                icon: const Icon(
                                  Iconsax.close_circle,
                                  color: Colors.white54,
                                ),
                                onPressed: () {
                                  setState(() {
                                    expiryDate = null;
                                  });
                                },
                              ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Action buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Cancel button
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text(
                              'Cancel',
                              style: TextStyle(color: Colors.white70),
                            ),
                          ),
                          
                          // Save button
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFD0F0C0),
                              foregroundColor: const Color(0xFF222222),
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            ),
                            onPressed: () {
                              if (formKey.currentState!.validate()) {
                                // Logic to save or update inventory item
                                _saveInventoryItem(
                                  context,
                                  itemId: item?['inventory_id'],
                                  name: nameController.text,
                                  category: categoryController.text,
                                  quantity: double.tryParse(quantityController.text) ?? 0,
                                  minQuantity: double.tryParse(minQuantityController.text),
                                  unit: unitController.text,
                                  price: double.tryParse(priceController.text),
                                  expiryDate: expiryDate,
                                  supplierId: item?['supplier_id'],
                                );
                              }
                            },
                            child: Text(
                              item != null ? 'Update' : 'Add Item',
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
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
  
  Future<void> _saveInventoryItem(
    BuildContext context, {
    String? itemId,
    required String name,
    String? category,
    required double quantity,
    double? minQuantity,
    String? unit,
    double? price,
    DateTime? expiryDate,
    String? supplierId,
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
      
      if (itemId != null) {
        // Update existing item
        await _supabase
            .from('inventory')
            .update({
              'item_name': name,
              'category': category,
              'quantity': quantity,
              'min_quantity': minQuantity,
              'unit': unit,
              'price_per_unit': price,
              'expiry_date': expiryDate?.toIso8601String(),
              'last_updated': DateTime.now().toIso8601String(),
            })
            .eq('inventory_id', itemId);
      } else {
        // Create new item
        await _supabase
            .from('inventory')
            .insert({
              'item_name': name,
              'category': category,
              'quantity': quantity,
              'min_quantity': minQuantity,
              'unit': unit,
              'price_per_unit': price,
              'expiry_date': expiryDate?.toIso8601String(),
              'restaurant_id': restaurantId,
              'created_at': DateTime.now().toIso8601String(),
              'last_updated': DateTime.now().toIso8601String(),
            });
      }
      
      // Refresh inventory data
      await _fetchInventoryItems();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(itemId != null ? 'Item updated successfully' : 'Item added successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
      
    } catch (e) {
      print('Error saving inventory item: $e');
      
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving item: $e'),
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
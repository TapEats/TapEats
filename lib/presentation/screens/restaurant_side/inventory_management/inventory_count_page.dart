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

class InventoryCountPage extends StatefulWidget {
  final int selectedIndex;
  
  const InventoryCountPage({
    super.key,
    this.selectedIndex = 3, // Default to inventory tab index
  });

  @override
  State<InventoryCountPage> createState() => _InventoryCountPageState();
}

class _InventoryCountPageState extends State<InventoryCountPage> {
  final SupabaseClient _supabase = Supabase.instance.client;
  final TextEditingController _searchController = TextEditingController();
  
  bool _isLoading = true;
  List<Map<String, dynamic>> _inventoryItems = [];
  List<Map<String, dynamic>> _filteredItems = [];
  List<String> _categories = ['All'];
  String _selectedCategory = 'All';
  
  // Map to store count values
  final Map<String, double> _countValues = {};
  final Map<String, String> _countNotes = {};
  
  // Count session data
  String _countSessionId = '';
  DateTime _countDate = DateTime.now();
  String _countName = 'Inventory Count ${DateFormat('MMM d, yyyy').format(DateTime.now())}';
  bool _countInProgress = false;
  bool _showOnlyDifferences = false;
  
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
      
      // Fetch inventory items
      final inventoryResult = await _supabase
          .from('inventory')
          .select('*')
          .eq('restaurant_id', restaurantId)
          .order('category', ascending: true)
          .order('item_name', ascending: true);
          
      // Extract unique categories for filtering
      final categories = ['All'];
      for (var item in inventoryResult) {
        if (item['category'] != null && 
            !categories.contains(item['category'])) {
          categories.add(item['category']);
        }
        
        // Initialize count values with current quantities
        final id = item['inventory_id'];
        _countValues[id] = item['quantity'] ?? 0;
      }
      
      // Check if there's an ongoing count session
      try {
        final ongoingSession = await _supabase
            .from('inventory_count_sessions')
            .select('*')
            .eq('restaurant_id', restaurantId)
            .eq('status', 'in_progress')
            .order('created_at', ascending: false)
            .limit(1)
            .maybeSingle();
            
        if (ongoingSession != null) {
          // Found an ongoing session
          _countSessionId = ongoingSession['session_id'];
          _countName = ongoingSession['name'];
          _countDate = DateTime.parse(ongoingSession['count_date']);
          _countInProgress = true;
          
          // Fetch count values for this session
          final countItems = await _supabase
              .from('inventory_count_items')
              .select('*')
              .eq('session_id', _countSessionId);
              
          // Update count values and notes
          for (var item in countItems) {
            _countValues[item['inventory_id']] = item['counted_quantity'] ?? 0;
            if (item['notes'] != null && item['notes'].isNotEmpty) {
              _countNotes[item['inventory_id']] = item['notes'];
            }
          }
        }
      } catch (e) {
        print('Error checking for ongoing count session: $e');
        // Continue without session data
      }
      
      setState(() {
        _inventoryItems = inventoryResult;
        _filteredItems = _filterItems(_inventoryItems, _selectedCategory, _searchController.text);
        _categories = categories;
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching inventory items: $e');
      setState(() {
        _inventoryItems = [];
        _filteredItems = [];
        _isLoading = false;
      });
    }
  }
  
  List<Map<String, dynamic>> _filterItems(List<Map<String, dynamic>> items, String category, String searchText) {
    return items.where((item) {
      // Filter by category
      if (category != 'All' && item['category'] != category) {
        return false;
      }
      
      // Filter by search text
      if (searchText.isNotEmpty) {
        final name = item['item_name']?.toString().toLowerCase() ?? '';
        final itemCategory = item['category']?.toString().toLowerCase() ?? '';
        
        return name.contains(searchText.toLowerCase()) || 
               itemCategory.contains(searchText.toLowerCase());
      }
      
      // If showing only differences, filter items where count ≠ system quantity
      if (_showOnlyDifferences) {
        final id = item['inventory_id'];
        final systemQty = item['quantity'] ?? 0;
        final countQty = _countValues[id] ?? systemQty;
        
        // Small floating point precision issue handling
        final diff = (countQty - systemQty).abs();
        return diff > 0.001;
      }
      
      return true;
    }).toList();
  }
  
  void _selectCategory(String category) {
    setState(() {
      _selectedCategory = category;
      _filteredItems = _filterItems(_inventoryItems, category, _searchController.text);
    });
  }
  
  void _performSearch() {
    setState(() {
      _filteredItems = _filterItems(_inventoryItems, _selectedCategory, _searchController.text);
    });
  }
  
  void _toggleShowDifferences() {
    setState(() {
      _showOnlyDifferences = !_showOnlyDifferences;
      _filteredItems = _filterItems(_inventoryItems, _selectedCategory, _searchController.text);
    });
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
              headingText: "Inventory Count",
              rightIcon: Iconsax.menu_1,
              onRightButtonPressed: _openSideMenu,
            ),
            
            const SizedBox(height: 12),
            
            // Count session info
            if (_countInProgress)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF2A2A2A),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFD0F0C0), width: 1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            _countName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFD0F0C0).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            "In Progress",
                            style: TextStyle(
                              color: const Color(0xFFD0F0C0),
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Date: ${DateFormat('MMM d, yyyy').format(_countDate)}",
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 14,
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
                hintText: "Search inventory items...",
                onSearch: _performSearch,
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Categories and Show Differences Toggle
            Row(
              children: [
                // Categories horizontal scroll
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.only(left: 16.0),
                    child: Row(
                      children: _categories.map((category) => 
                        _buildCategoryChip(category, _selectedCategory == category)
                      ).toList(),
                    ),
                  ),
                ),
                
                // Show differences toggle
                if (_countInProgress)
                  Padding(
                    padding: const EdgeInsets.only(right: 16.0),
                    child: InkWell(
                      onTap: _toggleShowDifferences,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: _showOnlyDifferences 
                              ? const Color(0xFFD0F0C0).withOpacity(0.2) 
                              : const Color(0xFF222222),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _showOnlyDifferences 
                                ? const Color(0xFFD0F0C0) 
                                : Colors.transparent,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Iconsax.format_square,
                              size: 16,
                              color: _showOnlyDifferences 
                                  ? const Color(0xFFD0F0C0) 
                                  : Colors.white.withOpacity(0.7),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              "Differences",
                              style: TextStyle(
                                color: _showOnlyDifferences 
                                    ? const Color(0xFFD0F0C0) 
                                    : Colors.white.withOpacity(0.7),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            
            const SizedBox(height: 12),
            
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
                      "System",
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
                      "Count",
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 8),
            
            // Main Content - Inventory List
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
            
            // Count actions footer
            if (_countInProgress)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD0F0C0),
                    foregroundColor: const Color(0xFF222222),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    minimumSize: const Size(double.infinity, 48),
                  ),
                  onPressed: () {
                    _showCompleteCountDialog(context);
                  },
                  child: const Text(
                    "Complete Count",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD0F0C0),
                    foregroundColor: const Color(0xFF222222),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    minimumSize: const Size(double.infinity, 48),
                  ),
                  onPressed: () {
                    _showStartCountDialog(context);
                  },
                  child: const Text(
                    "Start New Count",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
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
  
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Iconsax.clipboard_text, 
            size: 64, 
            color: Colors.white.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            _showOnlyDifferences
                ? "No differences found"
                : _selectedCategory != 'All'
                    ? "No items found in this category"
                    : "No inventory items found",
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          if (!_countInProgress && _inventoryItems.isEmpty)
            TextButton.icon(
              onPressed: () {
                Navigator.pushReplacementNamed(context, '/stock');
              },
              icon: const Icon(Iconsax.add, color: Color(0xFFD0F0C0)),
              label: const Text(
                "Add Inventory Items",
                style: TextStyle(color: Color(0xFFD0F0C0)),
              ),
            ),
        ],
      ),
    );
  }
  
  Widget _buildInventoryItem(Map<String, dynamic> item) {
    final id = item['inventory_id'];
    final systemQty = item['quantity'] ?? 0;
    final countQty = _countValues[id] ?? systemQty;
    final unit = item['unit'] ?? '';
    
    // Calculate difference
    final diff = countQty - systemQty;
    final hasDifference = diff.abs() > 0.001; // Small threshold for floating point errors
    
    return GestureDetector(
      onTap: () {
        if (_countInProgress) {
          _showCountEntryDialog(context, item);
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF222222),
          borderRadius: BorderRadius.circular(10),
          border: hasDifference && _countInProgress
              ? Border.all(
                  color: diff > 0 
                      ? Colors.green.withOpacity(0.7) 
                      : Colors.red.withOpacity(0.7),
                  width: 1,
                )
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Item details
            Row(
              children: [
                // Item name and category
                Expanded(
                  flex: 6,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['item_name'] ?? 'Unnamed Item',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
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
                
                // System quantity
                Expanded(
                  flex: 2,
                  child: Text(
                    "$systemQty $unit",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                
                // Count quantity with difference indicator
                Expanded(
                  flex: 2,
                  child: Column(
                    children: [
                      Text(
                        "$countQty $unit",
                        style: TextStyle(
                          color: !_countInProgress
                              ? Colors.white
                              : hasDifference
                                  ? diff > 0
                                      ? Colors.green
                                      : Colors.red
                                  : Colors.white,
                          fontWeight: _countInProgress ? FontWeight.bold : FontWeight.normal,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      if (hasDifference && _countInProgress)
                        Text(
                          diff > 0 ? "+${diff.abs()} $unit" : "-${diff.abs()} $unit",
                          style: TextStyle(
                            color: diff > 0 ? Colors.green : Colors.red,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                    ],
                  ),
                ),
              ],
            ),
            
            // Notes if any
            if (_countNotes.containsKey(id) && _countNotes[id]!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  "Note: ${_countNotes[id]}",
                  style: TextStyle(
                    color: Colors.white.withAlpha(128),
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
  
  void _showStartCountDialog(BuildContext context) {
    final nameController = TextEditingController(text: _countName);
    DateTime selectedDate = _countDate;
    
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF222222),
              title: const Text(
                'Start New Inventory Count',
                style: TextStyle(color: Colors.white),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: 'Count Name',
                      labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                      filled: true,
                      fillColor: const Color(0xFF2A2A2A),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    style: const TextStyle(color: Colors.white),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Date picker
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      'Count Date',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                      ),
                    ),
                    subtitle: Text(
                      DateFormat('MMMM d, yyyy').format(selectedDate),
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                      ),
                    ),
                    trailing: IconButton(
                      icon: const Icon(
                        Iconsax.calendar,
                        color: Color(0xFFD0F0C0),
                      ),
                      onPressed: () async {
                        final pickedDate = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime.now().subtract(const Duration(days: 30)),
                          lastDate: DateTime.now().add(const Duration(days: 1)),
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
                            selectedDate = pickedDate;
                          });
                        }
                      },
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
                  onPressed: () {
                    Navigator.pop(context);
                    _startCountSession(
                      name: nameController.text,
                      date: selectedDate,
                    );
                  },
                  child: const Text('Start Count'),
                ),
              ],
            );
          },
        );
      },
    );
  }
  
  void _showCountEntryDialog(BuildContext context, Map<String, dynamic> item) {
    final id = item['inventory_id'];
    final systemQty = item['quantity'] ?? 0;
    final countQty = _countValues[id] ?? systemQty;
    final unit = item['unit'] ?? '';
    
    final countController = TextEditingController(text: countQty.toString());
    final noteController = TextEditingController(text: _countNotes[id] ?? '');
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF222222),
          title: Text(
            item['item_name'] ?? 'Count Item',
            style: const TextStyle(color: Colors.white),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Item details
              Text(
                "${item['category'] ?? 'Uncategorized'} • System: $systemQty $unit",
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 14,
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Count input
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: countController,
                      decoration: InputDecoration(
                        labelText: 'Counted Quantity',
                        labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                        filled: true,
                        fillColor: const Color(0xFF2A2A2A),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                        suffixText: unit,
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Quick adjust buttons
              Wrap(
                spacing: 8,
                children: [
                  // Set to system quantity
                  ActionChip(
                    label: const Text('As System'),
                    backgroundColor: const Color(0xFF333333),
                    labelStyle: const TextStyle(color: Colors.white),
                    onPressed: () {
                      countController.text = systemQty.toString();
                    },
                  ),
                  
                  // Add 1
                  ActionChip(
                    label: const Text('+1'),
                    backgroundColor: const Color(0xFF333333),
                    labelStyle: const TextStyle(color: Colors.white),
                    onPressed: () {
                      final current = double.tryParse(countController.text) ?? 0;
                      countController.text = (current + 1).toString();
                    },
                  ),
                  
                  // Subtract 1
                  ActionChip(
                    label: const Text('-1'),
                    backgroundColor: const Color(0xFF333333),
                    labelStyle: const TextStyle(color: Colors.white),
                    onPressed: () {
                      final current = double.tryParse(countController.text) ?? 0;
                      countController.text = (current - 1 >= 0 ? current - 1 : 0).toString();
                    },
                  ),
                  
                  // Set to 0
                  ActionChip(
                    label: const Text('Zero'),
                    backgroundColor: const Color(0xFF333333),
                    labelStyle: const TextStyle(color: Colors.white),
                    onPressed: () {
                      countController.text = '0';
                    },
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Notes
              TextFormField(
                controller: noteController,
                decoration: InputDecoration(
                  labelText: 'Notes (optional)',
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
              onPressed: () {
                // Save count
                final count = double.tryParse(countController.text) ?? systemQty;
                _saveCountValue(id, count, noteController.text);
                Navigator.pop(context);
              },
              child: const Text('Save Count'),
            ),
          ],
        );
      },
    );
  }
  
  void _showCompleteCountDialog(BuildContext context) {
    // Calculate metrics
    int totalItems = 0;
    int itemsCounted = 0;
    int itemsWithDifferences = 0;
    
    for (var item in _inventoryItems) {
      final id = item['inventory_id'];
      final systemQty = item['quantity'] ?? 0;
      final countQty = _countValues[id] ?? systemQty;
      
      totalItems++;
      if (_countValues.containsKey(id)) {
        itemsCounted++;
      }
      
      if ((countQty - systemQty).abs() > 0.001) {
        itemsWithDifferences++;
      }
    }
    
    // Options
    bool updateInventory = true;
    
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF222222),
              title: const Text(
                'Complete Inventory Count',
                style: TextStyle(color: Colors.white),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Count summary
                  Text(
                    "You've counted $itemsCounted out of $totalItems items.",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                  
                  const SizedBox(height: 4),
                  
                  Text(
                    "Found $itemsWithDifferences items with count differences.",
                    style: TextStyle(
                      color: itemsWithDifferences > 0 ? Colors.orange : Colors.green,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Update inventory option
                  CheckboxListTile(
                    title: const Text(
                      'Update inventory to match counts',
                      style: TextStyle(color: Colors.white, fontSize: 14),
                    ),
                    subtitle: Text(
                      'Automatically adjust inventory quantities based on count',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 12,
                      ),
                    ),
                    value: updateInventory,
                    onChanged: (value) {
                      setState(() {
                        updateInventory = value ?? true;
                      });
                    },
                    activeColor: const Color(0xFFD0F0C0),
                    checkColor: const Color(0xFF222222),
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                  
                  if (itemsWithDifferences == 0) 
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        'No differences found between system and count quantities.',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
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
                  onPressed: () {
                    Navigator.pop(context);
                    _completeCountSession(updateInventory: updateInventory);
                  },
                  child: const Text('Complete Count'),
                ),
              ],
            );
          },
        );
      },
    );
  }
  
  Future<void> _startCountSession({
    required String name,
    required DateTime date,
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
      
      // Check if inventory_count_sessions table exists, create if not
      final hasCountTables = await _createCountTablesIfNeeded();
      if (!hasCountTables) return;
      
      // Check for existing in-progress session
      final existingSession = await _supabase
          .from('inventory_count_sessions')
          .select('session_id')
          .eq('restaurant_id', restaurantId)
          .eq('status', 'in_progress')
          .maybeSingle();
          
      if (existingSession != null) {
        // Update existing session instead of creating a new one
        _countSessionId = existingSession['session_id'];
        
        await _supabase
            .from('inventory_count_sessions')
            .update({
              'name': name,
              'count_date': date.toIso8601String(),
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('session_id', _countSessionId);
      } else {
        // Create new count session
        final sessionResult = await _supabase
            .from('inventory_count_sessions')
            .insert({
              'name': name,
              'count_date': date.toIso8601String(),
              'status': 'in_progress',
              'restaurant_id': restaurantId,
              'created_by': user.id,
            })
            .select('session_id')
            .single();
            
        _countSessionId = sessionResult['session_id'];
      }
      
      // Update state
      setState(() {
        _countName = name;
        _countDate = date;
        _countInProgress = true;
        
        // Initialize count values with current quantities if not already set
        for (var item in _inventoryItems) {
          final id = item['inventory_id'];
          if (!_countValues.containsKey(id)) {
            _countValues[id] = item['quantity'] ?? 0;
          }
        }
      });
      
      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Inventory count started successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error starting count session: $e');
      
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error starting count: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }
  
  Future<bool> _createCountTablesIfNeeded() async {
    try {
      // Try to query sessions table to see if it exists
      try {
        await _supabase.from('inventory_count_sessions').select('session_id').limit(1);
        return true; // Table exists
      } catch (e) {
        print('Inventory count tables may not exist: $e');
        
        // Ask user if they want to create the tables
        if (mounted) {
          final shouldCreate = await showDialog<bool>(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              backgroundColor: const Color(0xFF222222),
              title: const Text('Create Inventory Count Tables?', style: TextStyle(color: Colors.white)),
              content: const Text(
                'The inventory count tables do not exist. Would you like to create them now?',
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
          
          if (shouldCreate != true) return false;
          
          // Create tables via RPC
          try {
            await _supabase.rpc('create_inventory_count_tables');
            return true;
          } catch (e) {
            print('Error creating inventory count tables: $e');
            
            // Show error to user
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Failed to create inventory count tables. Please contact your administrator.'),
                  backgroundColor: Colors.red,
                ),
              );
            }
            return false;
          }
        }
        return false;
      }
    } catch (e) {
      print('Error checking/creating count tables: $e');
      return false;
    }
  }
  
  Future<void> _saveCountValue(String inventoryId, double count, String notes) async {
    try {
      // Update local state
      setState(() {
        _countValues[inventoryId] = count;
        if (notes.isNotEmpty) {
          _countNotes[inventoryId] = notes;
        } else {
          _countNotes.remove(inventoryId);
        }
        
        // Update filtered items to reflect changes
        _filteredItems = _filterItems(_inventoryItems, _selectedCategory, _searchController.text);
      });
      
      // Save to database if we have a session
      if (_countSessionId.isNotEmpty) {
        try {
          // Check if item already exists in count
          final existingItem = await _supabase
              .from('inventory_count_items')
              .select('item_id')
              .eq('session_id', _countSessionId)
              .eq('inventory_id', inventoryId)
              .maybeSingle();
              
          if (existingItem != null) {
            // Update existing count
            await _supabase
                .from('inventory_count_items')
                .update({
                  'counted_quantity': count,
                  'notes': notes,
                  'updated_at': DateTime.now().toIso8601String(),
                })
                .eq('item_id', existingItem['item_id']);
          } else {
            // Create new count
            await _supabase
                .from('inventory_count_items')
                .insert({
                  'session_id': _countSessionId,
                  'inventory_id': inventoryId,
                  'counted_quantity': count,
                  'notes': notes,
                });
          }
        } catch (e) {
          print('Error saving count to database: $e');
          // Continue with local state changes even if database update fails
        }
      }
    } catch (e) {
      print('Error saving count value: $e');
    }
  }
  
  Future<void> _completeCountSession({required bool updateInventory}) async {
    setState(() => _isLoading = true);
    
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;
      
      // Update session status
      await _supabase
          .from('inventory_count_sessions')
          .update({
            'status': 'completed',
            'completed_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('session_id', _countSessionId);
          
      // If updating inventory, apply changes
      if (updateInventory) {
        for (var item in _inventoryItems) {
          final id = item['inventory_id'];
          final countQty = _countValues[id];
          
          if (countQty != null) {
            // Update inventory quantity
            await _supabase
                .from('inventory')
                .update({
                  'quantity': countQty,
                  'last_updated': DateTime.now().toIso8601String(),
                })
                .eq('inventory_id', id);
                
            // Record transaction if table exists
            try {
              final systemQty = item['quantity'] ?? 0;
              final diff = countQty - systemQty;
              
              if (diff.abs() > 0.001) {
                await _supabase
                    .from('inventory_transactions')
                    .insert({
                      'inventory_id': id,
                      'transaction_type': 'count',
                      'quantity': diff,
                      'notes': 'Inventory count adjustment from ${systemQty} to ${countQty}',
                      'user_id': user.id,
                      'reference_id': _countSessionId,
                    });
              }
            } catch (e) {
              print('Error recording inventory transaction: $e');
              // Continue even if transaction recording fails
            }
          }
        }
      }
      
      // Reset count state
      setState(() {
        _countInProgress = false;
        _countSessionId = '';
        _showOnlyDifferences = false;
      });
      
      // Refresh inventory data
      await _fetchInventoryItems();
      
      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              updateInventory 
                  ? 'Inventory count completed and quantities updated' 
                  : 'Inventory count completed'
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error completing count session: $e');
      
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error completing count: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }
}
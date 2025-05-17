import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tapeats/presentation/state_management/navbar_state.dart';
import 'package:tapeats/presentation/widgets/header_widget.dart';
import 'package:tapeats/presentation/widgets/footer_widget.dart';
import 'package:tapeats/presentation/widgets/search_bar.dart';
import 'package:tapeats/presentation/widgets/sidemenu_overlay.dart';

class RecipeCostsPage extends StatefulWidget {
  final int selectedIndex;
  
  const RecipeCostsPage({
    super.key,
    this.selectedIndex = 3, // Default to inventory tab index
  });

  @override
  State<RecipeCostsPage> createState() => _RecipeCostsPageState();
}

class _RecipeCostsPageState extends State<RecipeCostsPage> {
  final SupabaseClient _supabase = Supabase.instance.client;
  final TextEditingController _searchController = TextEditingController();
  
  bool _isLoading = true;
  List<Map<String, dynamic>> _recipes = [];
  List<Map<String, dynamic>> _filteredRecipes = [];
  final Map<String, List<Map<String, dynamic>>> _recipeIngredients = {};
  List<Map<String, dynamic>> _inventoryItems = [];
  List<Map<String, dynamic>> _menuItems = [];
  
  @override
  void initState() {
    super.initState();
    
    // Update the navbar state with the correct index
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<NavbarState>(context, listen: false).updateIndex(widget.selectedIndex);
      _checkAndCreateRecipeTables();
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
  
  Future<void> _checkAndCreateRecipeTables() async {
    try {
      // Try to query recipes table to see if it exists
      try {
        await _supabase.from('recipes').select('recipe_id').limit(1);
        return; // Table exists
      } catch (e) {
        print('Recipe tables may not exist: $e');
        
        // Ask user if they want to create the tables
        if (mounted) {
          final shouldCreate = await showDialog<bool>(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              backgroundColor: const Color(0xFF222222),
              title: const Text('Create Recipe Tables?', style: TextStyle(color: Colors.white)),
              content: const Text(
                'The recipe and recipe_ingredients tables do not exist. Would you like to create them now?',
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
          
          // Create tables via RPC
          try {
            await _supabase.rpc('create_recipe_tables');
          } catch (e) {
            print('Error creating recipe tables: $e');
            
            // Show error to user
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Failed to create recipe tables. Please contact your administrator.'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        }
      }
    } catch (e) {
      print('Error checking/creating recipe tables: $e');
    }
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    
    try {
      await Future.wait([
        _fetchRecipes(),
        _fetchInventoryItems(),
        _fetchMenuItems(),
      ]);
    } catch (e) {
      print('Error loading initial data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }
  
  Future<void> _fetchRecipes() async {
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
        // Fetch recipes with menu item details
        final recipesResult = await _supabase
            .from('recipes')
            .select('''
              recipe_id,
              name,
              yield_quantity,
              yield_unit,
              instructions,
              preparation_time,
              cooking_time,
              created_at,
              updated_at,
              menu_id (
                menu_id,
                name,
                price
              )
            ''')
            .eq('restaurant_id', restaurantId);
            
        // For each recipe, fetch its ingredients
        for (var recipe in recipesResult) {
          final recipeId = recipe['recipe_id'];
          try {
            final ingredientsResult = await _supabase
                .from('recipe_ingredients')
                .select('''
                  ingredient_id,
                  quantity,
                  unit,
                  notes,
                  inventory_id (
                    inventory_id,
                    item_name,
                    unit,
                    price_per_unit
                  )
                ''')
                .eq('recipe_id', recipeId);
                
            _recipeIngredients[recipeId] = ingredientsResult;
          } catch (e) {
            print('Error fetching recipe ingredients: $e');
            _recipeIngredients[recipeId] = [];
          }
        }
        
        setState(() {
          _recipes = recipesResult;
          _filteredRecipes = recipesResult;
        });
      } catch (e) {
        print('Error fetching recipes: $e');
        
        // Try simplified query if join fails
        try {
          final recipesResult = await _supabase
              .from('recipes')
              .select()
              .eq('restaurant_id', restaurantId);
              
          setState(() {
            _recipes = recipesResult;
            _filteredRecipes = recipesResult;
          });
        } catch (simpleError) {
          print('Error with simplified recipes query: $simpleError');
          setState(() {
            _recipes = [];
            _filteredRecipes = [];
          });
        }
      }
    } catch (e) {
      print('Error in _fetchRecipes: $e');
      setState(() {
        _recipes = [];
        _filteredRecipes = [];
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
  
  Future<void> _fetchMenuItems() async {
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
      
      // Fetch menu items
      final menuResult = await _supabase
          .from('menu')
          .select('menu_id, name, price, category')
          .eq('restaurant_id', restaurantId)
          .order('name', ascending: true);
          
      setState(() {
        _menuItems = menuResult;
      });
    } catch (e) {
      print('Error fetching menu items: $e');
    }
  }
  
  void _performSearch() {
    final searchText = _searchController.text.toLowerCase();
    
    setState(() {
      if (searchText.isEmpty) {
        _filteredRecipes = _recipes;
      } else {
        _filteredRecipes = _recipes.where((recipe) {
          // Search in recipe name
          final recipeName = recipe['name']?.toString().toLowerCase() ?? '';
          
          // Get menu item name from nested menu object if available
          String menuItemName = '';
          if (recipe['menu_id'] is Map) {
            menuItemName = recipe['menu_id']['name']?.toString().toLowerCase() ?? '';
          }
          
          return recipeName.contains(searchText) || menuItemName.contains(searchText);
        }).toList();
      }
    });
  }
  
  double _calculateRecipeCost(String recipeId) {
    final ingredients = _recipeIngredients[recipeId] ?? [];
    double totalCost = 0;
    
    for (var ingredient in ingredients) {
      double quantity = (ingredient['quantity'] as num?)?.toDouble() ?? 0;
      double unitPrice = 0;
      
      if (ingredient['inventory_id'] is Map) {
        unitPrice = (ingredient['inventory_id']['price_per_unit'] as num?)?.toDouble() ?? 0;
      }
      
      totalCost += quantity * unitPrice;
    }
    
    return totalCost;
  }
  
  double _calculateProfitMargin(String recipeId, double cost) {
    final recipe = _recipes.firstWhere(
      (r) => r['recipe_id'] == recipeId,
      orElse: () => {},
    );
    
    double price = 0;
    if (recipe.isNotEmpty && recipe['menu_id'] is Map) {
      price = (recipe['menu_id']['price'] as num?)?.toDouble() ?? 0;
    }
    
    if (price <= 0 || cost <= 0) return 0;
    
    return ((price - cost) / price) * 100;
  }
  
  String _getProfitMarginColor(double margin) {
    if (margin >= 70) return 'green';
    if (margin >= 50) return 'lime';
    if (margin >= 30) return 'yellow';
    if (margin >= 10) return 'orange';
    return 'red';
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
              headingText: "Recipe Costs",
              rightIcon: Iconsax.menu_1,
              onRightButtonPressed: _openSideMenu,
            ),
            
            const SizedBox(height: 16),
            
            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: CustomSearchBar(
                controller: _searchController,
                hintText: "Search recipes...",
                onSearch: _performSearch,
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Recipes list or empty state
            Expanded(
              child: _isLoading 
                ? const Center(child: CircularProgressIndicator(color: Color(0xFFD0F0C0)))
                : _filteredRecipes.isEmpty 
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      itemCount: _filteredRecipes.length,
                      itemBuilder: (context, index) {
                        final recipe = _filteredRecipes[index];
                        final cost = _calculateRecipeCost(recipe['recipe_id']);
                        final margin = _calculateProfitMargin(recipe['recipe_id'], cost);
                        
                        return _buildRecipeCard(recipe, cost, margin);
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
          _showAddRecipeDialog(context);
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
            Iconsax.diagram, 
            size: 64, 
            color: Colors.white.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            _searchController.text.isEmpty
                ? "No recipes found"
                : "No recipes match your search",
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () {
              _showAddRecipeDialog(context);
            },
            icon: const Icon(Iconsax.add, color: Color(0xFFD0F0C0)),
            label: const Text(
              "Add New Recipe",
              style: TextStyle(color: Color(0xFFD0F0C0)),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildRecipeCard(Map<String, dynamic> recipe, double cost, double margin) {
    // Get menu item details
    String menuItemName = '';
    double menuPrice = 0;
    
    if (recipe['menu_id'] is Map) {
      menuItemName = recipe['menu_id']['name'] ?? '';
      menuPrice = (recipe['menu_id']['price'] as num?)?.toDouble() ?? 0;
    }
    
    // Get yield info
    final yieldQty = (recipe['yield_quantity'] as num?)?.toDouble() ?? 0;
    final yieldUnit = recipe['yield_unit'] ?? '';
    
    // Calculate cost per serving
    final costPerServing = yieldQty > 0 ? cost / yieldQty : cost;
    
    // Format profit margin
    final marginColor = _getProfitMarginColor(margin);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: const Color(0xFF222222),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 0,
      child: InkWell(
        onTap: () {
          _showRecipeDetailsDialog(context, recipe);
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Recipe name and menu item
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          recipe['name'] ?? 'Unnamed Recipe',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        if (menuItemName.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              "Menu Item: $menuItemName",
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 14,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  // Yield info
                  if (yieldQty > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF333333),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        "Yield: $yieldQty $yieldUnit",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Cost and profit margin
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    // Total recipe cost
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Total Recipe Cost:",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          "\$${cost.toStringAsFixed(2)}",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // Cost per serving
                    if (yieldQty > 0)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Cost per $yieldUnit:",
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            "\$${costPerServing.toStringAsFixed(2)}",
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      
                    if (menuPrice > 0 && margin > 0) ...[
                      const SizedBox(height: 8),
                      const Divider(color: Color(0xFF333333)),
                      const SizedBox(height: 8),
                      
                      // Profit margin
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Profit Margin:",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                          _buildMarginIndicator(margin, marginColor),
                        ],
                      ),
                      
                      const SizedBox(height: 8),
                      
                      // Sales price
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Menu Price:",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            "\$${menuPrice.toStringAsFixed(2)}",
                            style: const TextStyle(
                              color: Color(0xFFD0F0C0),
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              
              const SizedBox(height: 12),
              
              // Ingredient count
              Text(
                "${(_recipeIngredients[recipe['recipe_id']] ?? []).length} Ingredients",
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildMarginIndicator(double margin, String color) {
    Color markerColor;
    String label;
    
    switch (color) {
      case 'green':
        markerColor = Colors.green;
        label = 'Excellent';
        break;
      case 'lime':
        markerColor = Colors.lime;
        label = 'Good';
        break;
      case 'yellow':
        markerColor = Colors.yellow;
        label = 'Fair';
        break;
      case 'orange':
        markerColor = Colors.orange;
        label = 'Low';
        break;
      case 'red':
        markerColor = Colors.red;
        label = 'Poor';
        break;
      default:
        markerColor = Colors.grey;
        label = 'N/A';
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: markerColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "${margin.toStringAsFixed(1)}%",
            style: TextStyle(
              color: markerColor,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            "($label)",
            style: TextStyle(
              color: markerColor,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
  
  void _showRecipeDetailsDialog(BuildContext context, Map<String, dynamic> recipe) {
    // Get recipe details
    final recipeId = recipe['recipe_id'];
    final recipeName = recipe['name'] ?? 'Unnamed Recipe';
    final ingredients = _recipeIngredients[recipeId] ?? [];
    final cost = _calculateRecipeCost(recipeId);
    
    // Get menu item details
    String menuItemName = '';
    double menuPrice = 0;
    
    if (recipe['menu_id'] is Map) {
      menuItemName = recipe['menu_id']['name'] ?? '';
      menuPrice = (recipe['menu_id']['price'] as num?)?.toDouble() ?? 0;
    }
    
    // Get yield info
    final yieldQty = (recipe['yield_quantity'] as num?)?.toDouble() ?? 0;
    final yieldUnit = recipe['yield_unit'] ?? '';
    
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: const Color(0xFF222222),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            width: double.maxFinite,
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.8,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: Color(0xFF2A2A2A),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              recipeName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            if (menuItemName.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  "Menu Item: $menuItemName",
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.7),
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white70),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                
                // Content
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Recipe details
                      if (yieldQty > 0)
                        _buildDetailRow("Yield", "$yieldQty $yieldUnit"),
                        
                      if (recipe['preparation_time'] != null)
                        _buildDetailRow("Prep Time", "${recipe['preparation_time']} minutes"),
                        
                      if (recipe['cooking_time'] != null)
                        _buildDetailRow("Cook Time", "${recipe['cooking_time']} minutes"),
                        
                      const SizedBox(height: 16),
                      
                      // Cost summary
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A1A1A),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Cost Summary",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  "Total Recipe Cost:",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  "\$${cost.toStringAsFixed(2)}",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            if (yieldQty > 0) ...[
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "Cost per $yieldUnit:",
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.7),
                                      fontSize: 14,
                                    ),
                                  ),
                                  Text(
                                    "\$${(yieldQty > 0 ? cost / yieldQty : 0).toStringAsFixed(2)}",
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.7),
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            if (menuPrice > 0) ...[
                              const SizedBox(height: 8),
                              const Divider(color: Color(0xFF333333)),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    "Menu Price:",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                    ),
                                  ),
                                  Text(
                                    "\$${menuPrice.toStringAsFixed(2)}",
                                    style: const TextStyle(
                                      color: Color(0xFFD0F0C0),
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    "Profit per Item:",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                    ),
                                  ),
                                  Text(
                                    "\$${(menuPrice - (yieldQty > 0 ? cost / yieldQty : 0)).toStringAsFixed(2)}",
                                    style: const TextStyle(
                                      color: Color(0xFFD0F0C0),
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    "Profit Margin:",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                    ),
                                  ),
                                  _buildMarginIndicator(
                                    _calculateProfitMargin(recipeId, cost),
                                    _getProfitMarginColor(_calculateProfitMargin(recipeId, cost)),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Ingredients list
                      const Text(
                        "Ingredients",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      
                      const SizedBox(height: 12),
                      
                      if (ingredients.isEmpty)
                        Text(
                          "No ingredients added yet",
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.5),
                            fontStyle: FontStyle.italic,
                          ),
                        )
                      else
                        Column(
                          children: ingredients.map((ingredient) {
                            String itemName = 'Unknown Item';
                            String unit = ingredient['unit'] ?? '';
                            double unitPrice = 0;
                            
                            if (ingredient['inventory_id'] is Map) {
                              itemName = ingredient['inventory_id']['item_name'] ?? 'Unknown Item';
                              if (unit.isEmpty) {
                                unit = ingredient['inventory_id']['unit'] ?? '';
                              }
                              unitPrice = (ingredient['inventory_id']['price_per_unit'] as num?)?.toDouble() ?? 0;
                            }
                            
                            final quantity = (ingredient['quantity'] as num?)?.toDouble() ?? 0;
                            final ingredientCost = quantity * unitPrice;
                            
                            return Container(
                              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                              margin: const EdgeInsets.only(bottom: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF2A2A2A),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 5,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          itemName,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          "$quantity $unit",
                                          style: TextStyle(
                                            color: Colors.white.withOpacity(0.7),
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    flex: 3,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          "\$${ingredientCost.toStringAsFixed(2)}",
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          "\$${unitPrice.toStringAsFixed(2)}/${ingredient['inventory_id']['unit'] ?? 'unit'}",
                                          style: TextStyle(
                                            color: Colors.white.withOpacity(0.7),
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                        
                      const SizedBox(height: 24),
                      
                      // Instructions
                      if (recipe['instructions'] != null && recipe['instructions'].toString().isNotEmpty) ...[
                        const Text(
                          "Instructions",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        
                        const SizedBox(height: 12),
                        
                        Text(
                          recipe['instructions'],
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                
                // Actions
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _showEditRecipeDialog(context, recipe);
                        },
                        icon: const Icon(Iconsax.edit, color: Color(0xFFD0F0C0), size: 16),
                        label: const Text(
                          "Edit Recipe",
                          style: TextStyle(color: Color(0xFFD0F0C0)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  void _showAddRecipeDialog(BuildContext context) {
    // Check if we have menu items and inventory
    if (_menuItems.isEmpty || _inventoryItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Iconsax.warning_2, color: Colors.white),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _menuItems.isEmpty
                      ? 'You need to add menu items before creating recipes.'
                      : 'You need to add inventory items before creating recipes.',
                ),
              ),
            ],
          ),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 5),
        ),
      );
      return;
    }
    
    // Values for the new recipe
    final nameController = TextEditingController();
    final yieldQtyController = TextEditingController(text: '1');
    final yieldUnitController = TextEditingController(text: 'serving');
    final prepTimeController = TextEditingController();
    final cookTimeController = TextEditingController();
    final instructionsController = TextEditingController();
    
    int? selectedMenuId = _menuItems[0]['menu_id'];
    
    // Ingredients list
    final ingredients = <Map<String, dynamic>>[];
    
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              backgroundColor: const Color(0xFF222222),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                width: double.maxFinite,
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.9,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: const BoxDecoration(
                        color: Color(0xFF2A2A2A),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(16),
                          topRight: Radius.circular(16),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Expanded(
                            child: Text(
                              "Add New Recipe",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.white70),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                    ),
                    
                    // Content
                    Flexible(
                      child: ListView(
                        shrinkWrap: true,
                        padding: const EdgeInsets.all(16),
                        children: [
                          // Recipe name
                          TextFormField(
                            controller: nameController,
                            decoration: _inputDecoration('Recipe Name'),
                            style: const TextStyle(color: Colors.white),
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // Menu item dropdown
                          DropdownButtonFormField<int>(
                            decoration: _inputDecoration('Menu Item'),
                            dropdownColor: const Color(0xFF333333),
                            value: selectedMenuId,
                            items: _menuItems.map((menuItem) {
                              return DropdownMenuItem<int>(
                                value: menuItem['menu_id'],
                                child: Text(
                                  menuItem['name'] ?? 'Unnamed Menu Item',
                                  style: const TextStyle(color: Colors.white),
                                ),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                selectedMenuId = value;
                              });
                            },
                            style: const TextStyle(color: Colors.white),
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // Yield
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: yieldQtyController,
                                  decoration: _inputDecoration('Yield Quantity'),
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: TextFormField(
                                  controller: yieldUnitController,
                                  decoration: _inputDecoration('Yield Unit'),
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // Prep and cook time
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: prepTimeController,
                                  decoration: _inputDecoration('Prep Time (min)'),
                                  keyboardType: TextInputType.number,
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: TextFormField(
                                  controller: cookTimeController,
                                  decoration: _inputDecoration('Cook Time (min)'),
                                  keyboardType: TextInputType.number,
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // Instructions
                          TextFormField(
                            controller: instructionsController,
                            decoration: _inputDecoration('Instructions'),
                            style: const TextStyle(color: Colors.white),
                            maxLines: 4,
                          ),
                          
                          const SizedBox(height: 24),
                          
                          // Ingredients section
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                "Ingredients",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              TextButton.icon(
                                onPressed: () {
                                  _showAddIngredientDialog(context, _inventoryItems, (item, quantity, unit) {
                                    setState(() {
                                      ingredients.add({
                                        'inventory_id': item,
                                        'quantity': quantity,
                                        'unit': unit,
                                      });
                                    });
                                  });
                                },
                                icon: const Icon(Iconsax.add, color: Color(0xFFD0F0C0), size: 16),
                                label: const Text(
                                  "Add Ingredient",
                                  style: TextStyle(color: Color(0xFFD0F0C0)),
                                ),
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 12),
                          
                          // Ingredients list
                          if (ingredients.isEmpty)
                            Text(
                              "No ingredients added yet",
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.5),
                                fontStyle: FontStyle.italic,
                              ),
                            )
                          else
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: ingredients.length,
                              itemBuilder: (context, index) {
                                final ingredient = ingredients[index];
                                final inventoryItem = ingredient['inventory_id'] as Map<String, dynamic>;
                                
                                return Container(
                                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                                  margin: const EdgeInsets.only(bottom: 8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF2A2A2A),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              inventoryItem['item_name'] ?? 'Unknown Item',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            Text(
                                              "${ingredient['quantity']} ${ingredient['unit'] ?? inventoryItem['unit'] ?? ''}",
                                              style: TextStyle(
                                                color: Colors.white.withOpacity(0.7),
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Iconsax.trash, color: Colors.red, size: 18),
                                        onPressed: () {
                                          setState(() {
                                            ingredients.removeAt(index);
                                          });
                                        },
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                        ],
                      ),
                    ),
                    
                    // Actions
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFD0F0C0),
                              foregroundColor: const Color(0xFF222222),
                            ),
                            onPressed: nameController.text.trim().isEmpty || ingredients.isEmpty
                                ? null // Disable if name is empty or no ingredients
                                : () {
                                    Navigator.pop(context);
                                    _saveRecipe(
                                      name: nameController.text.trim(),
                                      menuId: selectedMenuId,
                                      yieldQuantity: double.tryParse(yieldQtyController.text) ?? 1,
                                      yieldUnit: yieldUnitController.text.trim(),
                                      prepTime: int.tryParse(prepTimeController.text),
                                      cookTime: int.tryParse(cookTimeController.text),
                                      instructions: instructionsController.text.trim(),
                                      ingredients: ingredients,
                                    );
                                  },
                            child: const Text('Save Recipe'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
  
  void _showEditRecipeDialog(BuildContext context, Map<String, dynamic> recipe) {
    // Implement edit recipe dialog
    // This would be similar to add recipe but pre-populated with existing data
    // For now, we'll show a simple message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Edit recipe functionality will be added in a future update'),
        backgroundColor: Colors.blue,
      ),
    );
  }
  
  void _showAddIngredientDialog(
    BuildContext context,
    List<Map<String, dynamic>> inventoryItems,
    Function(Map<String, dynamic>, double, String) onIngredientAdded,
  ) {
    if (inventoryItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No inventory items available. Please add items to your inventory first.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    Map<String, dynamic>? selectedItem = inventoryItems[0];
    double quantity = 1.0;
    String unit = selectedItem['unit'] ?? '';
    
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF222222),
              title: const Text(
                'Add Ingredient',
                style: TextStyle(color: Colors.white),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Inventory item dropdown
                  DropdownButtonFormField<String>(
                    decoration: _inputDecoration('Select Item'),
                    dropdownColor: const Color(0xFF333333),
                    value: selectedItem?['inventory_id'],
                    items: inventoryItems.map((item) {
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
                        selectedItem = inventoryItems.firstWhere(
                          (item) => item['inventory_id'] == value,
                        );
                        unit = selectedItem!['unit'] ?? '';
                      });
                    },
                    style: const TextStyle(color: Colors.white),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Quantity and unit
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          initialValue: quantity.toString(),
                          decoration: _inputDecoration('Quantity'),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          style: const TextStyle(color: Colors.white),
                          onChanged: (value) {
                            quantity = double.tryParse(value) ?? 1.0;
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          initialValue: unit,
                          decoration: _inputDecoration('Unit (optional)'),
                          style: const TextStyle(color: Colors.white),
                          onChanged: (value) {
                            unit = value;
                          },
                        ),
                      ),
                    ],
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
                    onIngredientAdded(selectedItem!, quantity, unit);
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
  
  Future<void> _saveRecipe({
    required String name,
    required int? menuId,
    required double yieldQuantity,
    required String yieldUnit,
    int? prepTime,
    int? cookTime,
    String? instructions,
    required List<Map<String, dynamic>> ingredients,
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
      
      // 1. Create the recipe
      final recipeResult = await _supabase
          .from('recipes')
          .insert({
            'name': name,
            'menu_id': menuId,
            'yield_quantity': yieldQuantity,
            'yield_unit': yieldUnit,
            'preparation_time': prepTime,
            'cooking_time': cookTime,
            'instructions': instructions,
            'restaurant_id': restaurantId,
          })
          .select('recipe_id')
          .single();
          
      final recipeId = recipeResult['recipe_id'];
      
      // 2. Add recipe ingredients
      for (var ingredient in ingredients) {
        final inventoryItem = ingredient['inventory_id'] as Map<String, dynamic>;
        
        await _supabase
            .from('recipe_ingredients')
            .insert({
              'recipe_id': recipeId,
              'inventory_id': inventoryItem['inventory_id'],
              'quantity': ingredient['quantity'],
              'unit': ingredient['unit'],
            });
      }
      
      // 3. Refresh recipes data
      await _fetchRecipes();
      
      // 4. Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Recipe created successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error saving recipe: $e');
      
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating recipe: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }
}
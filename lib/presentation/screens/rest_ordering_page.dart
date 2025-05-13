import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tapeats/presentation/screens/rest_ordering_connecting_page.dart';
import 'package:tapeats/presentation/widgets/add_button.dart';
import 'package:tapeats/presentation/widgets/custom_footer_five_button_widget.dart';
import 'package:tapeats/presentation/widgets/header_widget.dart';
import 'package:tapeats/presentation/widgets/minus_button.dart';
import 'package:tapeats/presentation/widgets/plus_button.dart';
import 'package:tapeats/presentation/widgets/search_bar.dart';
import 'package:tapeats/presentation/widgets/slider_button.dart';
import 'package:tapeats/presentation/widgets/sidemenu_overlay.dart';

class RestMenuPage extends StatefulWidget {
  final int selectedIndex;

  const RestMenuPage({
    super.key,
    required this.selectedIndex,
  });

  @override
  State<RestMenuPage> createState() => _RestMenuPageState();
}

class _RestMenuPageState extends State<RestMenuPage> {
  final SupabaseClient supabase = Supabase.instance.client;
  Map<String, int> cartItems = {};
  int totalItems = 0;
  final TextEditingController _searchController = TextEditingController();
  String searchQuery = '';
  String? selectedTableId;
  String? selectedTableNumber;

  List<dynamic> menuItems = [];
  List<String> categories = [];
  String selectedCategory = '';
  String? restaurantId;

  @override
  void initState() {
    super.initState();
    _fetchUserRestaurantId();
  }

  Future<void> _fetchUserRestaurantId() async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;

      final response = await supabase
          .from('users')
          .select('restaurant_id')
          .eq('user_id', userId)
          .single();

      if (response.isNotEmpty && response['restaurant_id'] != null) {
        setState(() {
          restaurantId = response['restaurant_id'];
        });
        _fetchMenuData();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching restaurant_id: $e');
      }
    }
  }

  Future<void> _fetchMenuData() async {
    if (restaurantId == null) return;

    final response = await supabase
        .from('menu')
        .select(
            'name, price, category, rating, cooking_time, image_url, menu_id')
        .eq('restaurant_id', restaurantId!);

    if (response.isNotEmpty) {
      Set<String> uniqueCategories = {};
      setState(() {
        menuItems = response;
        for (var item in response) {
          uniqueCategories.add(item['category'].toString());
        }
        categories = uniqueCategories.toList();
      });
    }
  }

  void _selectCategory(String category) {
    setState(() {
      selectedCategory = selectedCategory == category ? '' : category;
    });
  }

  void _addItemToCart(String itemName) {
    setState(() {
      cartItems[itemName] = (cartItems[itemName] ?? 0) + 1;
      totalItems += 1;
    });
  }

  void _removeItemFromCart(String itemName) {
    setState(() {
      if (cartItems.containsKey(itemName)) {
        if (cartItems[itemName]! > 1) {
          cartItems[itemName] = cartItems[itemName]! - 1;
        } else {
          cartItems.remove(itemName);
        }
        totalItems -= 1;
      }
    });
  }

  void _openSideMenu() {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        pageBuilder: (_, __, ___) => const SideMenuOverlay(),
      ),
    );
  }

  void _onSlideToCheckout() {
    if (selectedTableId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a table first')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RestCartPage(
          cartItems: cartItems,
          totalItems: totalItems,
          restaurantId: restaurantId,
          tableId: selectedTableId,
          tableNumber: selectedTableNumber,
          selectedIndex: widget.selectedIndex,
        ),
      ),
    );
  }

  Future<void> _selectTable() async {
    if (restaurantId == null) return;

    final tablesResponse = await supabase
        .from('restaurant_tables')
        .select('table_id, table_number, is_reserved')
        .eq('restaurant_id', restaurantId!)
        .eq('is_reserved', false);

    if (tablesResponse.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No available tables')),
      );
      return;
    }

    final selectedTable = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Table'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: tablesResponse.length,
            itemBuilder: (context, index) {
              final table = tablesResponse[index];
              return ListTile(
                title: Text('Table ${table['table_number']}'),
                onTap: () => Navigator.pop(context, {
                  'table_id': table['table_id'],
                  'table_number': table['table_number'],
                }),
              );
            },
          ),
        ),
      ),
    );

    if (selectedTable != null) {
      setState(() {
        selectedTableId = selectedTable['table_id'];
        selectedTableNumber = selectedTable['table_number'].toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF151611),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            HeaderWidget(
              leftIcon: Iconsax.arrow_left_1,
              onLeftButtonPressed: () => Navigator.pop(context),
              headingText: 'Menu',
              headingIcon: Iconsax.book_saved,
              rightIcon: Iconsax.menu_1,
              onRightButtonPressed: _openSideMenu,
            ),
            const SizedBox(height: 20),

            // Table selection (restaurant-specific)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: ElevatedButton(
                onPressed: _selectTable,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF222222),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12.0),
                  child: Text(
                    selectedTableNumber != null
                        ? 'Table $selectedTableNumber'
                        : 'Select Table',
                    style: const TextStyle(
                      color: Color(0xFFEEEFEF),
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Search bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: CustomSearchBar(
                controller: _searchController,
                hintText: 'Find your cravings',
                onSearch: () {
                  setState(() {
                    searchQuery = _searchController.text;
                  });
                },
              ),
            ),
            const SizedBox(height: 20),

            // Categories
            _buildCategoryButtons(),
            const SizedBox(height: 20),

            // Menu items
            _buildMenuItems(),
            const SizedBox(height: 10),

            // Checkout slider (restaurant-specific)
            if (totalItems > 0)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: SliderButton(
                  labelText: 'Cart',
                  subText: '$totalItems items',
                  onSlideComplete: _onSlideToCheckout,
                  pageId: 'menu_cart',
                ),
              ),
            const SizedBox(height: 20),
          ],
        ),
      ),
      bottomNavigationBar: CustomFiveFooter(
        selectedIndex: widget.selectedIndex,
      ),
    );
  }

  Widget _buildCategoryButtons() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Row(
        children: [
          _buildCategoryButton('All', selectedCategory.isEmpty),
          ...categories.map((category) =>
              _buildCategoryButton(category, selectedCategory == category)),
        ],
      ),
    );
  }

  Widget _buildCategoryButton(String label, bool isSelected) {
    return Padding(
      padding: const EdgeInsets.only(right: 10.0),
      child: GestureDetector(
        onTap: () => _selectCategory(isSelected ? '' : label),
        child: Container(
          decoration: BoxDecoration(
            color:
                isSelected ? const Color(0xFF222222) : const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected
                  ? const Color(0xFFD0F0C0)
                  : const Color(0xFFEEEFEF),
              fontFamily: 'Helvetica Neue',
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItems() {
    final filteredItems = menuItems.where((item) {
      return (selectedCategory.isEmpty ||
              item['category'] == selectedCategory) &&
          (searchQuery.isEmpty ||
              item['name'].toLowerCase().contains(searchQuery.toLowerCase()));
    }).toList();

    return Expanded(
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        itemCount: filteredItems.length,
        itemBuilder: (context, index) {
          final item = filteredItems[index];
          return _buildMenuItem(
            item['name'],
            item['price'],
            item['category'],
            item['rating'],
            item['cooking_time'],
            item['image_url'],
          );
        },
      ),
    );
  }

  Widget _buildMenuItem(
    String name,
    dynamic price,
    String category,
    dynamic rating,
    String cookingTime,
    String imageUrl,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                imageUrl,
                fit: BoxFit.cover,
                height: 150,
                width: double.infinity,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      color: Color(0xFFEEEFEF),
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '\$${(price as num).toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Color(0xFFD0F0C0),
                          fontSize: 16,
                        ),
                      ),
                      _buildQuantityControls(name),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _buildRatingAndTime(
                    (rating as num).toDouble(),
                    cookingTime,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuantityControls(String itemName) {
    final quantity = cartItems[itemName] ?? 0;

    if (quantity > 0) {
      return Row(
        children: [
          MinusButton(onPressed: () => _removeItemFromCart(itemName)),
          const SizedBox(width: 5),
          Text(
            '$quantity',
            style: const TextStyle(color: Color(0xFFD0F0C0)),
          ),
          const SizedBox(width: 5),
          PlusButton(onPressed: () => _addItemToCart(itemName)),
        ],
      );
    } else {
      return AddButton(onPressed: () => _addItemToCart(itemName));
    }
  }

  Widget _buildRatingAndTime(double rating, String cookingTime) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF222222),
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Row(
            children: [
              const Icon(Iconsax.star, color: Color(0xFFEEEFEF), size: 16),
              const SizedBox(width: 5),
              Text(
                rating.toString(),
                style: const TextStyle(
                  color: Color(0xFFEEEFEF),
                  fontFamily: 'Helvetica Neue',
                  fontSize: 14,
                ),
              ),
            ],
          ),
          Container(
            width: 1,
            height: 20,
            color: const Color(0xFFEEEFEF),
          ),
          Row(
            children: [
              const Icon(Iconsax.timer, color: Color(0xFFEEEFEF), size: 16),
              const SizedBox(width: 5),
              Text(
                cookingTime,
                style: const TextStyle(
                  color: Color(0xFFEEEFEF),
                  fontFamily: 'Helvetica Neue',
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tapeats/presentation/widgets/add_button.dart';
import 'package:tapeats/presentation/widgets/footer_widget.dart';
import 'package:tapeats/presentation/widgets/header_widget.dart';
import 'package:tapeats/presentation/widgets/minus_button.dart';
import 'package:tapeats/presentation/widgets/plus_button.dart';
import 'package:tapeats/presentation/widgets/search_bar.dart';
import 'package:tapeats/presentation/widgets/slider_button.dart';
import 'package:tapeats/presentation/widgets/sidemenu_overlay.dart';

class MenuPage extends StatefulWidget {
  const MenuPage({super.key});

  @override
  State<MenuPage> createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> {
  final SupabaseClient supabase = Supabase.instance.client;
  Map<String, int> cartItems = {}; // This will store item names and their quantities
  int totalItems = 0; // Total number of items in the cart
  final TextEditingController _searchController = TextEditingController();
  String searchQuery = ''; // Stores the search input

  List<dynamic> menuItems = [];
  List<String> categories = [];
  String selectedCategory = '';

  @override
  void initState() {
    super.initState();
    _fetchMenuData();
  }

  Future<void> _fetchMenuData() async {
    final response = await supabase
        .from('menu')
        .select('name, price, category, rating, cooking_time, image_url'); // Ensure the image_url is fetched

    if (response.isNotEmpty) {
      Set<String> uniqueCategories = {};
      setState(() {
        menuItems = response;
        for (var item in response) {
          uniqueCategories.add(item['category'].toString());
        }
        categories = uniqueCategories.toList();
      });
    } else {
      if (kDebugMode) {
        print('Error fetching menu data');
      }
    }
  }

  void _selectCategory(String category) {
    setState(() {
      selectedCategory = selectedCategory == category ? '' : category; // Toggle category selection
    });
  }

  void _addItemToCart(String itemName) {
    setState(() {
      if (cartItems.containsKey(itemName)) {
        cartItems[itemName] = cartItems[itemName]! + 1;
      } else {
        cartItems[itemName] = 1;
      }
      totalItems += 1;
      if (kDebugMode) {
        print("Added $itemName, total items: $totalItems");
      }
    });
  }

  void _removeItemFromCart(String itemName) {
    setState(() {
      if (cartItems.containsKey(itemName) && cartItems[itemName]! > 0) {
        cartItems[itemName] = cartItems[itemName]! - 1;
        totalItems -= 1;
        if (cartItems[itemName] == 0) {
          cartItems.remove(itemName);
        }
      }
      if (kDebugMode) {
        print("Removed $itemName, total items: $totalItems");
      }
    });
  }

  void _openSideMenu() {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false, // Keep the background semi-transparent
        pageBuilder: (_, __, ___) => const SideMenuOverlay(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF151611),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Widget with search and cart functionality
            HeaderWidget(
              leftIcon: Iconsax.arrow_left_1,
              onLeftButtonPressed: () => Navigator.pop(context), // Back action
              headingText: 'Menu',
              headingIcon: Iconsax.book_saved,
              rightIcon: Iconsax.menu_1,
              onRightButtonPressed: _openSideMenu, // Open side menu
            ),
            const SizedBox(height: 20),

            // Search bar widget
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

            // Categories (fetched from the menu table)
            _buildCategoryButtons(),
            const SizedBox(height: 20),

            // Food Menu Scrollable Items
            _buildMenuItems(),
            const SizedBox(height: 10),

            // Slider Button widget for cart or other action
            if (totalItems > 0)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: SliderButton(
                  labelText: 'Cart',
                  subText: '$totalItems items', // Show the total item count in the cart
                ),
              ),
            const SizedBox(height: 20),

            // Footer widget at the bottom
            const CustomFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryButtons() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Row(
        children: [
          // Add a button for "All Categories" or when no category is selected
          Padding(
            padding: const EdgeInsets.only(right: 10.0),
            child: GestureDetector(
              onTap: () => _selectCategory(''), // Empty string represents all categories
              child: Container(
                decoration: BoxDecoration(
                  color: selectedCategory.isEmpty ? const Color(0xFF222222) : const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
                child: Text(
                  'All',
                  style: TextStyle(
                    color: selectedCategory.isEmpty ? const Color(0xFFD0F0C0) : const Color(0xFFEEEFEF),
                    fontFamily: 'Helvetica Neue',
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ),
          ...categories.map((category) {
            bool isSelected = selectedCategory == category;
            return Padding(
              padding: const EdgeInsets.only(right: 10.0),
              child: GestureDetector(
                onTap: () => _selectCategory(category),
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF222222) : const Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
                  child: Text(
                    category,
                    style: TextStyle(
                      color: isSelected ? const Color(0xFFD0F0C0) : const Color(0xFFEEEFEF),
                      fontFamily: 'Helvetica Neue',
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildMenuItems() {
    final filteredMenuItems = menuItems.where((item) {
      return (selectedCategory.isEmpty || item['category'] == selectedCategory) &&
          (searchQuery.isEmpty || item['name'].toLowerCase().contains(searchQuery.toLowerCase()));
    }).toList();

    return Expanded(
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        itemCount: filteredMenuItems.length,
        itemBuilder: (context, index) {
          final item = filteredMenuItems[index];
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
                      item['image_url'],
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
                          item['name'],
                          style: const TextStyle(color: Color(0xFFEEEFEF), fontSize: 18),
                        ),
                        const SizedBox(height: 5),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '\$${item['price'].toStringAsFixed(2)}',
                              style: const TextStyle(color: Color(0xFFD0F0C0), fontSize: 16),
                            ),
                            cartItems.containsKey(item['name']) && cartItems[item['name']]! > 0
                                ? Row(
                                    children: [
                                      MinusButton(onPressed: () => _removeItemFromCart(item['name'])),
                                      const SizedBox(width: 5),
                                      Text(
                                        '${cartItems[item['name']]}',
                                        style: const TextStyle(color: Color(0xFFD0F0C0)),
                                      ),
                                      const SizedBox(width: 5),
                                      PlusButton(onPressed: () => _addItemToCart(item['name'])),
                                    ],
                                  )
                                : AddButton(onPressed: () => _addItemToCart(item['name'])),
                          ],
                        ),
                        const SizedBox(height: 10),
                        _buildRatingAndTime(item['rating'] ?? 0.0, item['cooking_time'] ?? '0'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
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

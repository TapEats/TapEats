import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tapeats/presentation/screens/user_side/cart_page.dart';
import 'package:tapeats/presentation/widgets/add_button.dart';
import 'package:tapeats/presentation/widgets/header_widget.dart';
import 'package:tapeats/presentation/widgets/footer_widget.dart';
import 'package:tapeats/presentation/widgets/minus_button.dart';
import 'package:tapeats/presentation/widgets/plus_button.dart';
import 'package:tapeats/presentation/widgets/search_bar.dart';
import 'package:tapeats/presentation/widgets/sidemenu_overlay.dart';
import 'package:tapeats/presentation/widgets/slider_button.dart';

class HomePage extends StatefulWidget {
  final int selectedIndex;
  const HomePage({super.key, required this.selectedIndex});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final SupabaseClient supabase = Supabase.instance.client;
  Map<String, int> cartItems =
      {}; // This will store item names and their quantities
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

  /// Fetch menu items and manually extract distinct categories
  /// Fetch menu items and manually extract distinct categories
  Future<void> _fetchMenuData() async {
    final response = await supabase.from('menu').select(
        'name, price, category, rating, cooking_time, image_url'); // Ensure the image_url is fetched

    if (response.isNotEmpty) {
      Set<String> uniqueCategories = {};
      setState(() {
        menuItems = response;
        for (var item in response) {
          uniqueCategories.add(item['category'].toString());
        }
        categories = uniqueCategories.toList();
        if (categories.isNotEmpty) {
          selectedCategory = categories[0]; // Set the first category as default
        }
      });
    } else {
      if (kDebugMode) {
        print('Error fetching menu data');
      }
    }
  }

  void _selectCategory(String category) {
    setState(() {
      if (selectedCategory == category) {
        selectedCategory = ''; // Unselect the category
      } else {
        selectedCategory = category; // Select the new category
      }
    });
  }

  void _addItemToCart(String itemName) {
    setState(() {
      if (cartItems.containsKey(itemName)) {
        cartItems[itemName] = cartItems[itemName]! + 1;
      } else {
        cartItems[itemName] = 1;
      }
      totalItems += 1; // Update total items in the cart
      if (kDebugMode) {
        print("Added $itemName, total items: $totalItems");
      } // Debug print
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
      } // Debug print
    });
  }

  void _openSideMenu() {
    setState(() {});
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false, // Keep the background semi-transparent
        pageBuilder: (_, __, ___) => const SideMenuOverlay(),
      ),
    );
  }

  void _onSlideToCheckout() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CartPage(
          cartItems: cartItems,
          totalItems: totalItems,
        ),
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
            // Header Widget with fixed location icon
            HeaderWidget(
              leftIcon: Iconsax.user,
              onLeftButtonPressed: () {},
              headingText: 'Vadodara',
              headingIcon: Iconsax.location,
              rightIcon: Iconsax.menu_1,
              onRightButtonPressed: _openSideMenu,
            ),
            const SizedBox(height: 20),
            // "Fuel Your Flavor Adventure" Text with Image of Macarons
            _buildFlavorAdventureSection(),
            const SizedBox(height: 10),
            // Search bar widget
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: CustomSearchBar(
                controller: _searchController,
                hintText: 'Find your cravings',
                onSearch: () {
                  setState(() {
                    searchQuery =
                        _searchController.text; // Update the search query
                  });
                },
              ),
            ),
            const SizedBox(height: 10),
            // Categories (fetched from the menu table)
            _buildCategoryButtons(),
            const SizedBox(height: 10),
            // Food Menu Scrollable Items
            _buildMenuItems(),
            const SizedBox(height: 10),

            // Slider Button widget for cart or other action

            if (totalItems > 0)
              // Only show SliderButton when there are items in the cart
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: SliderButton(
                  labelText: 'Cart',
                  subText: '$totalItems items',
                  onSlideComplete: _onSlideToCheckout,
                ),
              ),

            const SizedBox(height: 20),
          ],
        ),
      ),
      bottomNavigationBar: Hero(
          tag: 'footerHero',
          child: CustomFooter(selectedIndex: widget.selectedIndex)),
    );
  }

  Widget _buildFlavorAdventureSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            flex: 4,
            child: Text(
              'Fuel Your Flavor Adventure',
              style: GoogleFonts.greatVibes(
                color: const Color(0xFFEEEFEF),
                fontSize: 48,
              ),
              textAlign: TextAlign.left,
            ),
          ),
          Expanded(
            flex: 1,
            child: Image.asset(
              'assets/images/macaroon_1.png', // Path to the macaroon image
              fit: BoxFit.contain,
              height: 100,
            ),
          ),
        ],
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
              onTap: () =>
                  _selectCategory(''), // Empty string represents all categories
              child: Container(
                decoration: BoxDecoration(
                  color: selectedCategory.isEmpty
                      ? const Color(0xFF222222)
                      : const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(10),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
                child: Text(
                  'All', // Label for "All Categories"
                  style: TextStyle(
                    color: selectedCategory.isEmpty
                        ? const Color(0xFFD0F0C0)
                        : const Color(0xFFEEEFEF),
                    fontFamily: 'Helvetica Neue',
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ),
          // Render category buttons from the fetched categories
          ...categories.map((category) {
            bool isSelected = selectedCategory == category;
            return Padding(
              padding: const EdgeInsets.only(right: 10.0),
              child: GestureDetector(
                onTap: () => _selectCategory(category),
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF222222)
                        : const Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 6.0),
                  child: Text(
                    category,
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
          }),
        ],
      ),
    );
  }

  Widget _buildMenuItems() {
    final filteredMenuItems = menuItems.where((item) {
      return (selectedCategory.isEmpty ||
              item['category'] == selectedCategory) &&
          (searchQuery.isEmpty ||
              item['name'].toLowerCase().contains(searchQuery.toLowerCase()));
    }).toList();

    return Expanded(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12.0),
        child: Row(
          children: filteredMenuItems.map((item) {
            return Padding(
              padding: const EdgeInsets.all(8.0),
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  minHeight: 210,
                  maxHeight: 250,
                ),
                child: Container(
                  width: 200,
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
                          height: 100,
                          width: double.infinity,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Text(
                          item['name'],
                          style: const TextStyle(color: Color(0xFFEEEFEF)),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '\$${item['price'].toStringAsFixed(2)}',
                              style: const TextStyle(color: Color(0xFFD0F0C0)),
                            ),
                            cartItems.containsKey(item['name']) &&
                                    cartItems[item['name']]! > 0
                                ? Row(
                                    children: [
                                      MinusButton(
                                          onPressed: () => _removeItemFromCart(
                                              item['name'])),
                                      const SizedBox(width: 5),
                                      Text(
                                        '${cartItems[item['name']]}',
                                        style: const TextStyle(
                                            color: Color(0xFFD0F0C0)),
                                      ),
                                      const SizedBox(width: 5),
                                      PlusButton(
                                          onPressed: () =>
                                              _addItemToCart(item['name'])),
                                    ],
                                  )
                                : AddButton(
                                    onPressed: () =>
                                        _addItemToCart(item['name'])),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: _buildRatingAndTime(
                          item['rating'] ?? 0.0,
                          item['cooking_time'] ?? '0',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
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
        mainAxisAlignment: MainAxisAlignment.spaceAround,
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

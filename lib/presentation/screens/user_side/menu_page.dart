import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tapeats/presentation/screens/user_side/cart_page.dart';
import 'package:tapeats/presentation/state_management/cart_state.dart';
import 'package:tapeats/presentation/state_management/favorites_state.dart';
import 'package:tapeats/presentation/widgets/add_button.dart';
import 'package:tapeats/presentation/widgets/favorite_button.dart';
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
  final TextEditingController _searchController = TextEditingController();
  String searchQuery = '';

  List<dynamic> menuItems = [];
  List<String> categories = [];
  String selectedCategory = '';

  @override
  void initState() {
    super.initState();
    _fetchMenuData();
    Provider.of<FavoritesState>(context, listen: false).initializeFavorites();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchMenuData() async {
    final response = await supabase.from('menu').select(
        'menu_id, name, price, category, rating, cooking_time, image_url');

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
      selectedCategory = selectedCategory == category
          ? ''
          : category;
    });
  }

  void _addItemToCart(String itemName) {
    Provider.of<CartState>(context, listen: false).addItem(itemName);
  }

  void _removeItemFromCart(String itemName) {
    Provider.of<CartState>(context, listen: false).removeItem(itemName);
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
    final cartState = Provider.of<CartState>(context, listen: false);
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CartPage(
          cartItems: cartState.cartItems,
          totalItems: cartState.totalItems,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    
    return Scaffold(
      backgroundColor: const Color(0xFF151611),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Widget with search and cart functionality
            HeaderWidget(
              leftIcon: Iconsax.arrow_left_1,
              onLeftButtonPressed: () => Navigator.pop(context),
              headingText: 'Menu',
              headingIcon: Iconsax.book_saved,
              rightIcon: Iconsax.menu_1,
              onRightButtonPressed: _openSideMenu,
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

            // Consumer to listen to CartState changes
            Consumer<CartState>(
              builder: (context, cartState, child) {
                return cartState.totalItems > 0
                    ? Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0),
                        child: SliderButton(
                          labelText: 'Cart',
                          subText: '${cartState.totalItems} items',
                          onSlideComplete: _onSlideToCheckout,
                          pageId: 'menu_cart',
                          width: screenWidth * 0.8,
                          height: screenHeight * 0.07,
                        ),
                      )
                    : const SizedBox.shrink();
              },
            ),
            const SizedBox(height: 20),
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
              onTap: () => _selectCategory(''),
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
                  'All',
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

    if (filteredMenuItems.isEmpty) {
      return Expanded(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Iconsax.search_normal,
                size: 48,
                color: Colors.grey.withValues(alpha: 128),
              ),
              const SizedBox(height: 16),
              Text(
                'No items found',
                style: TextStyle(
                  color: Colors.grey.withValues(alpha: 204),
                  fontSize: 18,
                ),
              ),
            ],
          ),
        ),
      );
    }

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
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 26),
                    spreadRadius: 1,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                        child: Image.network(
                          item['image_url'] ?? '',
                          fit: BoxFit.cover,
                          height: 150,
                          width: double.infinity,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              height: 150,
                              color: const Color(0xFF222222),
                              child: Center(
                                child: CircularProgressIndicator(
                                  value: loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                      : null,
                                  color: const Color(0xFFD0F0C0),
                                ),
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              height: 150,
                              color: const Color(0xFF222222),
                              child: const Center(
                                child: Icon(
                                  Iconsax.image,
                                  color: Color(0xFFEEEFEF),
                                  size: 40,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 128),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: FavoriteButton(
                            menuId: item['menu_id'],
                            size: 20,
                          ),
                        ),
                      ),
                      ],
                  ),
                  Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['name'] ?? 'Food Item',
                          style: const TextStyle(
                              color: Color(0xFFEEEFEF), fontSize: 18),
                        ),
                        const SizedBox(height: 5),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '\$${(item['price'] ?? 0).toStringAsFixed(2)}',
                              style: const TextStyle(
                                  color: Color(0xFFD0F0C0), fontSize: 16),
                            ),
                            // Use Consumer to listen to cart state changes
                            Consumer<CartState>(
                              builder: (context, cartState, child) {
                                final itemName = item['name'] ?? '';
                                return cartState.cartItems.containsKey(itemName) &&
                                        cartState.cartItems[itemName]! > 0
                                    ? Row(
                                        children: [
                                          MinusButton(
                                              onPressed: () => _removeItemFromCart(itemName)),
                                          const SizedBox(width: 5),
                                          Text(
                                            '${cartState.cartItems[itemName]}',
                                            style: const TextStyle(
                                                color: Color(0xFFD0F0C0)),
                                          ),
                                          const SizedBox(width: 5),
                                          PlusButton(
                                              onPressed: () =>
                                                  _addItemToCart(itemName)),
                                        ],
                                      )
                                    : AddButton(
                                        onPressed: () =>
                                            _addItemToCart(itemName));
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        _buildRatingAndTime(
                            item['rating'] ?? 0.0, item['cooking_time'] ?? '0'),
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

  Widget _buildRatingAndTime(dynamic rating, String cookingTime) {
    // Ensure rating is a double
    double ratingValue = 0.0;
    if (rating is double) {
      ratingValue = rating;
    } else if (rating is int) {
      ratingValue = rating.toDouble();
    } else if (rating is String) {
      ratingValue = double.tryParse(rating) ?? 0.0;
    }
    
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
              const Icon(Iconsax.star1, color: Color(0xFFFFD700), size: 16),
              const SizedBox(width: 5),
              Text(
                ratingValue.toStringAsFixed(1),
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
            color: const Color(0xFF444444),
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
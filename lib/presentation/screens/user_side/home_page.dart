import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tapeats/presentation/screens/user_side/cart_page.dart';
import 'package:tapeats/presentation/state_management/cart_state.dart';
import 'package:tapeats/presentation/state_management/slider_state.dart';
import 'package:tapeats/presentation/widgets/active_orders_carousel.dart';
import 'package:tapeats/presentation/widgets/add_button.dart';
import 'package:tapeats/presentation/widgets/header_widget.dart';
import 'package:tapeats/presentation/widgets/minus_button.dart';
import 'package:tapeats/presentation/widgets/plus_button.dart';
import 'package:tapeats/presentation/widgets/search_bar.dart';
import 'package:tapeats/presentation/widgets/sidemenu_overlay.dart';
import 'package:tapeats/presentation/widgets/slider_button.dart';
import 'package:tapeats/main.dart' show routeObserver;

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with RouteAware {
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
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context) as PageRoute);
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didPopNext() {
    super.didPopNext();
    // Reset both slider and cart states when returning to this page
    Provider.of<SliderState>(context, listen: false).resetAllSliders();
  }

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
        selectedCategory = '';
      } else {
        selectedCategory = category;
      }
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
        pageBuilder: (_, __, ___) => const RoleBasedSideMenu(),
      ),
    );
  }

  void _onSlideToCheckout() {
    final cartState = Provider.of<CartState>(context, listen: false);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CartPage(
          cartItems: cartState.cartItems, // Changed from getItems()
          totalItems: cartState.totalItems, // Changed from getTotal()
        ),
        settings: const RouteSettings(name: '/cart'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
// return LayoutBuilder(
//     builder: (context, constraints) {
//       if (kDebugMode) {
//         print('Page ID: home_cart');
//         print('Layout Constraints:');
//         print('  Max width: ${constraints.maxWidth}');
//         print('  Max height: ${constraints.maxHeight}');
//         print('  Min width: ${constraints.minWidth}');
//         print('  Min height: ${constraints.minHeight}');
//       }
    return PopScope(
      canPop: true,
      child: Scaffold(
        backgroundColor: const Color(0xFF151611),
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              HeaderWidget(
                leftIcon: Iconsax.user,
                onLeftButtonPressed: () {},
                headingText: 'Vadodara',
                headingIcon: Iconsax.location,
                rightIcon: Iconsax.menu_1,
                onRightButtonPressed: _openSideMenu,
              ),
              const SizedBox(height: 20),
              _buildFlavorAdventureSection(),
              const SizedBox(height: 10),
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
              const SizedBox(height: 10),
              _buildCategoryButtons(),
              const SizedBox(height: 10),
              _buildMenuItems(),
              const SizedBox(height: 10),
              Consumer<CartState>(
                builder: (context, cartState, child) {
                  return cartState.totalItems > 0
                      ? Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20.0),
                          child: SliderButton(
                            key: const ValueKey('home_cart_slider'),
                            labelText: 'Cart',
                            subText: '${cartState.totalItems} items',
                            onSlideComplete: _onSlideToCheckout,
                            pageId: 'home_cart',
                            width:
                                screenWidth * 0.8, // Explicitly set the width
                            height: screenHeight *
                                0.07, // Explicitly set the height
                          ),
                        )
                      : const SizedBox.shrink();
                },
              ),
              const ActiveOrdersCarousel(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
    // },
    // );
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
                            Consumer<CartState>(
                              builder: (context, cartState, child) {
                                return cartState.cartItems
                                            .containsKey(item['name']) &&
                                        cartState.cartItems[item['name']]! > 0
                                    ? Row(
                                        children: [
                                          MinusButton(
                                            onPressed: () =>
                                                _removeItemFromCart(
                                                    item['name']),
                                          ),
                                          const SizedBox(width: 5),
                                          Text(
                                            '${cartState.cartItems[item['name']]}',
                                            style: const TextStyle(
                                                color: Color(0xFFD0F0C0)),
                                          ),
                                          const SizedBox(width: 5),
                                          PlusButton(
                                            onPressed: () =>
                                                _addItemToCart(item['name']),
                                          ),
                                        ],
                                      )
                                    : AddButton(
                                        onPressed: () =>
                                            _addItemToCart(item['name']),
                                      );
                              },
                            ),
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

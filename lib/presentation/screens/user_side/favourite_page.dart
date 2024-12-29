import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tapeats/presentation/screens/user_side/cart_page.dart';
import 'package:tapeats/presentation/widgets/add_button.dart';
import 'package:tapeats/presentation/widgets/header_widget.dart';
import 'package:tapeats/presentation/widgets/minus_button.dart';
import 'package:tapeats/presentation/widgets/plus_button.dart';
import 'package:tapeats/presentation/widgets/sidemenu_overlay.dart';
import 'package:tapeats/presentation/widgets/slider_button.dart';

class FavouritesPage extends StatefulWidget {

  const FavouritesPage({super.key});

  @override
  State<FavouritesPage> createState() => _FavouritesPageState();
}

class _FavouritesPageState extends State<FavouritesPage> {
  final SupabaseClient supabase = Supabase.instance.client;
  Map<String, int> cartItems =
      {}; // This will store item names and their quantities
  int totalItems = 0; // Total number of items in the cart
  List<dynamic> favouriteItems = [];

  @override
  void initState() {
    super.initState();
    _fetchFavouritesData();
  }

  Future<void> _fetchFavouritesData() async {
    final response = await supabase.from('menu').select(
        'name, price, rating, cooking_time, image_url'); // Ensure the image_url is fetched

    if (response.isNotEmpty) {
      setState(() {
        favouriteItems = response;
      });
    } else {
      // Handle if no favourites found
    }
  }

  void _addItemToCart(String itemName) {
    setState(() {
      if (cartItems.containsKey(itemName)) {
        cartItems[itemName] = cartItems[itemName]! + 1;
      } else {
        cartItems[itemName] = 1;
      }
      totalItems += 1; // Update total items in the cart
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
            // Header Widget
            HeaderWidget(
              leftIcon: Iconsax.arrow_left_1,
              onLeftButtonPressed: () => Navigator.pop(context),
              headingText: 'Favourites',
              headingIcon: Iconsax.heart,
              rightIcon: Iconsax.menu_1,
              onRightButtonPressed: _openSideMenu,
            ),
            const SizedBox(height: 20),

            // Favourite Items List
            _buildFavouriteItems(),
            const SizedBox(height: 10),

            // Slider Button widget for cart
            if (totalItems > 0)
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
    );
  }

  Widget _buildFavouriteItems() {
    return Expanded(
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        itemCount: favouriteItems.length,
        itemBuilder: (context, index) {
          final item = favouriteItems[index];
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
                          style: const TextStyle(
                              color: Color(0xFFEEEFEF), fontSize: 18),
                        ),
                        const SizedBox(height: 5),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '\$${item['price'].toStringAsFixed(2)}',
                              style: const TextStyle(
                                  color: Color(0xFFD0F0C0), fontSize: 16),
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
                style: const TextStyle(color: Color(0xFFEEEFEF), fontSize: 14),
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
                style: const TextStyle(color: Color(0xFFEEEFEF), fontSize: 14),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

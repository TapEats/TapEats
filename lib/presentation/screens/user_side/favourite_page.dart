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
import 'package:tapeats/presentation/widgets/sidemenu_overlay.dart';
import 'package:tapeats/presentation/widgets/slider_button.dart';

class FavouritesPage extends StatefulWidget {
  const FavouritesPage({super.key});

  @override
  State<FavouritesPage> createState() => _FavouritesPageState();
}

class _FavouritesPageState extends State<FavouritesPage> {
  final SupabaseClient supabase = Supabase.instance.client;
  List<dynamic> favouriteItems = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchFavouritesData();
    Provider.of<FavoritesState>(context, listen: false).addListener(_onFavoritesChanged);
  }

  @override
  void dispose() {
    Provider.of<FavoritesState>(context, listen: false).removeListener(_onFavoritesChanged);
    super.dispose();
  }

  void _onFavoritesChanged() {
    _fetchFavouritesData();
  }

Future<void> _fetchFavouritesData() async {
  setState(() {
    isLoading = true;
  });

  try {
    // Get favorites from the provider
    final favoritesState = Provider.of<FavoritesState>(context, listen: false);
    final favoriteMenuIds = favoritesState.favoriteMenuIds;
    
    if (favoriteMenuIds.isEmpty) {
      setState(() {
        favouriteItems = [];
        isLoading = false;
      });
      return;
    }
    
    // We'll use a different approach to fetch the items
    List<dynamic> allItems = [];
    
    // This works in all versions of Supabase Flutter SDK
    for (final menuId in favoriteMenuIds) {
      try {
        final response = await supabase
            .from('menu')
            .select('menu_id, name, price, rating, cooking_time, image_url')
            .eq('menu_id', menuId);
            
        if (response.isNotEmpty) {
          allItems.addAll(response);
        }
      } catch (e) {
        debugPrint('Error fetching menu item $menuId: $e');
      }
    }

    if (mounted) {
      setState(() {
        favouriteItems = allItems;
        isLoading = false;
      });
    }
  } catch (e) {
    if (mounted) {
      setState(() {
        favouriteItems = [];
        isLoading = false;
      });
    }
    debugPrint('Error fetching favorites: $e');
  }
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
        opaque: false, // Keep the background semi-transparent
        pageBuilder: (_, __, ___) => const RoleBasedSideMenu(),
      ),
    );
  }

  void _onSlideToCheckout() {
    // Get cart state from provider
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
            // Header Widget
            HeaderWidget(
              leftIcon: Iconsax.arrow_left_1,
              onLeftButtonPressed: () => Navigator.pop(context),
              headingText: 'Favourites',
              headingIcon: Iconsax.heart5,
              rightIcon: Iconsax.menu_1,
              onRightButtonPressed: _openSideMenu,
            ),
            const SizedBox(height: 20),

            // Favourite Items List
            isLoading
                ? const Expanded(
                    child: Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFFD0F0C0),
                      ),
                    ),
                  )
                : _buildFavouriteItems(),
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
                          pageId: 'favourite_cart',
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

  Widget _buildFavouriteItems() {
    if (favouriteItems.isEmpty) {
      return Expanded(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Iconsax.heart, 
                size: 64, 
                color: Colors.grey.withValues(alpha: 128),
              ),
              const SizedBox(height: 16),
              Text(
                'No favorites yet',
                style: TextStyle(
                  color: Colors.grey.withValues(alpha: 204),
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Tap the heart icon on any food item to add it here',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey.withValues(alpha: 153),
                  fontSize: 14,
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
        itemCount: favouriteItems.length,
        itemBuilder: (context, index) {
          final item = favouriteItems[index];
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
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['name'] ?? 'Food Item',
                          style: const TextStyle(
                            color: Color(0xFFEEEFEF),
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '\$${(item['price'] ?? 0).toStringAsFixed(2)}',
                              style: const TextStyle(
                                color: Color(0xFFD0F0C0),
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Consumer<CartState>(
                              builder: (context, cartState, child) {
                                final itemName = item['name'] ?? '';
                                return cartState.cartItems.containsKey(itemName) &&
                                        cartState.cartItems[itemName]! > 0
                                    ? Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF222222),
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: Row(
                                          children: [
                                            MinusButton(
                                              onPressed: () => _removeItemFromCart(itemName),
                                            ),
                                            Container(
                                              margin: const EdgeInsets.symmetric(horizontal: 8),
                                              child: Text(
                                                '${cartState.cartItems[itemName]}',
                                                style: const TextStyle(
                                                  color: Color(0xFFD0F0C0),
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                            PlusButton(
                                              onPressed: () => _addItemToCart(itemName),
                                            ),
                                          ],
                                        ),
                                      )
                                    : AddButton(
                                        onPressed: () => _addItemToCart(itemName),
                                      );
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildRatingAndTime(
                          item['rating'] ?? 0.0,
                          item['cooking_time'] ?? '0',
                        ),
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          Container(
            width: 1, 
            height: 16,
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
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
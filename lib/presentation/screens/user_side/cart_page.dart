import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tapeats/presentation/widgets/header_widget.dart';
import 'package:tapeats/presentation/widgets/sidemenu_overlay.dart';
import 'package:tapeats/presentation/widgets/slider_button.dart';

class CartPage extends StatefulWidget {
  final Map<String, int> cartItems;
  final int totalItems;
  const CartPage({
    super.key,
    required this.cartItems,
    required this.totalItems,
  });

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  final SupabaseClient supabase = Supabase.instance.client;
  List<dynamic> detailedCartItems = [];
  double itemTotal = 0.0;
  final double gstCharges = 6.0;
  final double platformFee = 4.0;

  double get totalAmount => itemTotal + gstCharges + platformFee;

  @override
  void initState() {
    super.initState();
    _fetchCartDetails();
  }

  Future<void> _fetchCartDetails() async {
    List<dynamic> items = [];
    double total = 0.0;

    for (var item in widget.cartItems.entries) {
      final response = await supabase
          .from('menu')
          .select('name, price, rating, cooking_time, image_url')
          .eq('name',
              item.key) // Match the name of the cart item with the menu name
          .single();

      if (response.isNotEmpty) {
        final price = (response['price'] as num).toDouble();
        final quantity = item.value;
        response['quantity'] = quantity; // Add quantity to the fetched data
        items.add(response);
        total += price * quantity; // Calculate the total price
      }
    }

    setState(() {
      detailedCartItems = items;
      itemTotal = total;
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

  void _removeItemFromCart(String itemName) {
    setState(() {
      if (widget.cartItems.containsKey(itemName)) {
        int currentQuantity = widget.cartItems[itemName]!;
        if (currentQuantity > 1) {
          widget.cartItems[itemName] = currentQuantity - 1;
        } else {
          widget.cartItems.remove(itemName);
        }

        // Recalculate itemTotal and update the detailedCartItems list
        itemTotal -= detailedCartItems
            .firstWhere((item) => item['name'] == itemName)['price'];
        detailedCartItems.removeWhere((item) => item['name'] == itemName);

        _fetchCartDetails(); // Refetch details after modification
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF151611),
      body: SafeArea(
        child: Column(
          children: [
            HeaderWidget(
              leftIcon: Iconsax.arrow_left_1,
              onLeftButtonPressed: () => Navigator.pop(context),
              headingText: 'Cart',
              headingIcon: Iconsax.book_saved,
              rightIcon: Iconsax.menu_1,
              onRightButtonPressed: _openSideMenu, // Open side menu
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                itemCount: detailedCartItems.length,
                itemBuilder: (context, index) {
                  final item = detailedCartItems[index];
                  return _buildCartItem(
                    item['name'],
                    item['cooking_time'],
                    item['rating'],
                    item['quantity'],
                    (item['price'] as num).toDouble(),
                    item['image_url'],
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            _buildPromoCodeSection(),
            const SizedBox(height: 20),
            _buildPriceSummary(),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: SliderButton(
                labelText: 'Checkout',
                subText: '\$${totalAmount.toStringAsFixed(2)}',
                onSlideComplete: () {
                  // Perform checkout logic here
                  if (kDebugMode) {
                    print('Checkout completed');
                  }
                },
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildCartItem(
    String itemName,
    String cookingTime, // Treating cooking time as a string
    double rating,
    int quantity,
    double pricePerItem,
    String imageUrl,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.network(
              imageUrl,
              width: 80,
              height: 80,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      itemName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontFamily: 'Helvetica Neue',
                        color: Color(0xFFEEEFEF),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Iconsax.trash, color: Color(0xFFD0F0C0)),
                      onPressed: () {
                        _removeItemFromCart(itemName);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  '$cookingTime • ',
                  style: const TextStyle(
                    fontSize: 14,
                    fontFamily: 'Helvetica Neue',
                    color: Color(0xFF8F8F8F),
                  ),
                ),
                Row(
                  children: [
                    const Icon(Iconsax.star,
                        size: 16, color: Color(0xFFEEEFEF)),
                    const SizedBox(width: 5),
                    Text(
                      rating.toString(),
                      style: const TextStyle(
                        fontSize: 14,
                        fontFamily: 'Helvetica Neue',
                        color: Color(0xFF8F8F8F),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  '\$${(pricePerItem * quantity).toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontFamily: 'Helvetica Neue',
                    color: Color(0xFFD0F0C0),
                  ),
                ),
              ],
            ),
          ),
          Column(
            children: [
              Text(
                'x$quantity',
                style: const TextStyle(
                  fontSize: 16,
                  fontFamily: 'Helvetica Neue',
                  color: Color(0xFFD0F0C0),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPromoCodeSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          const Expanded(
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Promo Code',
                hintStyle: TextStyle(color: Color(0xFF8F8F8F)),
                border: InputBorder.none,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              // Handle promo code application
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD0F0C0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              'Apply',
              style: TextStyle(
                color: Color(0xFF1A1A1A),
                fontFamily: 'Helvetica Neue',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceSummary() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          _buildPriceRow('Item total', '\$${itemTotal.toStringAsFixed(2)}'),
          _buildPriceRow('GST and restaurant charges',
              '\$${gstCharges.toStringAsFixed(2)}'),
          _buildPriceRow('Platform fee', '\$${platformFee.toStringAsFixed(2)}'),
          const Divider(color: Color(0xFF8F8F8F)),
          _buildPriceRow('Total', '\$${totalAmount.toStringAsFixed(2)}',
              isTotal: true),
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, String amount, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 18 : 16,
              fontFamily: 'Helvetica Neue',
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: const Color(0xFFEEEFEF),
            ),
          ),
          Text(
            amount,
            style: TextStyle(
              fontSize: isTotal ? 18 : 16,
              fontFamily: 'Helvetica Neue',
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: const Color(0xFFEEEFEF),
            ),
          ),
        ],
      ),
    );
  }
}

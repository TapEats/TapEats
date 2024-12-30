import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tapeats/presentation/screens/user_side/status_page.dart';
import 'package:tapeats/presentation/state_management/cart_state.dart';
import 'package:tapeats/presentation/state_management/slider_state.dart';
import 'package:tapeats/presentation/widgets/header_widget.dart';
import 'package:tapeats/presentation/widgets/sidemenu_overlay.dart';
import 'package:tapeats/presentation/widgets/slider_button.dart';
import 'package:tapeats/services/handle_checkout.dart';

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
          .select('menu_id, name, price, rating, cooking_time, image_url, category')
          .eq('name', item.key)
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
    final cartState = Provider.of<CartState>(context, listen: false);
    cartState.removeItem(itemName);
    _fetchCartDetails(); // Refetch details after modification
  }

void _handleCheckout() {
  if (!mounted) return;
  
  _showOrderSuccessDialog();

  handleCheckout(context, widget.cartItems).then((String? orderId) {
    if (!mounted) return;
    
    if (orderId != null) {
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (!mounted) return;

        // Complete all navigation first
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => StatusPage(orderId: orderId),
          ),
        ).then((_) {
          // Reset states after navigation is complete
          if (mounted) {
            Provider.of<CartState>(context, listen: false).resetCartAfterCheckout();
            Provider.of<SliderState>(context, listen: false).resetAllSliders();
          }
        });
      });
    } else {
      if (!mounted) return;
      Navigator.of(context).pop(); // Remove dialog
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to place order')),
      );
    }
  }).catchError((error) {
    if (!mounted) return;
    Navigator.of(context).pop(); // Remove dialog
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Checkout error: $error')),
    );
  });
}

void _showOrderSuccessDialog() {
  if (!mounted) return;
  
  showDialog(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black.withAlpha(178),
    builder: (BuildContext dialogContext) => AlertDialog(
      backgroundColor: const Color(0xFF1A1A1A),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      content: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Iconsax.tick_circle,
            color: Color(0xFFD0F0C0),
            size: 60,
          ),
          SizedBox(height: 20),
          Text(
            'Order Successful!',
            style: TextStyle(
              color: Color(0xFFEEEFEF),
              fontFamily: 'Helvetica Neue',
              fontSize: 18,
            ),
          ),
          SizedBox(height: 10),
          Text(
            'Redirecting to status page...',
            style: TextStyle(
              color: Color(0xFF8F8F8F),
              fontFamily: 'Helvetica Neue',
              fontSize: 14,
            ),
          ),
        ],
      ),
    ),
  );
}

  @override
  Widget build(BuildContext context) {

  final screenWidth = MediaQuery.of(context).size.width;
  final screenHeight = MediaQuery.of(context).size.height;
  // return LayoutBuilder(
  //   builder: (context, constraints) {
  //     if (kDebugMode) {
  //       print('Page ID: cart_checkout');
  //       print('Layout Constraints:');
  //       print('  Max width: ${constraints.maxWidth}');
  //       print('  Max height: ${constraints.maxHeight}');
  //       print('  Min width: ${constraints.minWidth}');
  //       print('  Min height: ${constraints.minHeight}');
  //     }
    return Scaffold(
      backgroundColor: const Color(0xFF151611),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch, 
          children: [
              HeaderWidget(
                      leftIcon: Iconsax.arrow_left_1,
                      onLeftButtonPressed: () { 
                        // Reset only the cart page's slider position
                        Provider.of<SliderState>(context, listen: false).resetSliderPosition('cart_checkout');
                        // Also reset the home page's slider position
                        Provider.of<SliderState>(context, listen: false).resetSliderPosition('home_cart');
                        Navigator.pop(context);
                      },
                      headingText: 'Cart',
                      headingIcon: Iconsax.book_saved,
                      rightIcon: Iconsax.menu_1,
                      onRightButtonPressed: _openSideMenu,
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
Consumer<SliderState>(
  builder: (context, sliderState, child) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: SliderButton(
        labelText: 'Checkout',
        subText: '\$${totalAmount.toStringAsFixed(2)}',
        onSlideComplete: _handleCheckout,
        pageId: 'cart_checkout',
        width: screenWidth * 0.8,
        height: screenHeight * 0.07,
      ),
    );
  },
),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  // },
  // );
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
                
                Row(
                  children: [
                    Text(
                  '$cookingTime • ',
                  style: const TextStyle(
                    fontSize: 14,
                    fontFamily: 'Helvetica Neue',
                    color: Color(0xFF8F8F8F),
                  ),
                ),
                    const Icon(Iconsax.star, size: 16, color: Color(0xFFEEEFEF)),
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
          _buildPriceRow('GST and restaurant charges', '\$${gstCharges.toStringAsFixed(2)}'),
          _buildPriceRow('Platform fee', '\$${platformFee.toStringAsFixed(2)}'),
          const Divider(color: Color(0xFF8F8F8F)),
          _buildPriceRow('Total', '\$${totalAmount.toStringAsFixed(2)}', isTotal: true),
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


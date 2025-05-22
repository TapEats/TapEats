import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tapeats/presentation/screens/restaurant_side/rest_ordering_page.dart';
import 'package:tapeats/presentation/screens/user_side/status_page.dart';
import 'package:tapeats/presentation/state_management/cart_state.dart';
import 'package:tapeats/presentation/state_management/slider_state.dart';
import 'package:tapeats/presentation/widgets/header_widget.dart';
import 'package:tapeats/presentation/widgets/sidemenu_overlay.dart';
import 'package:tapeats/presentation/widgets/slider_button.dart';
import 'package:uuid/uuid.dart';

class RestCartPage extends StatefulWidget {
  final Map<String, int> cartItems;
  final int totalItems;
  final String? restaurantId;
  final String? tableId;
  final String? tableNumber;

  const RestCartPage({
    super.key,
    required this.cartItems,
    required this.totalItems,
    this.restaurantId,
    this.tableId,
    this.tableNumber,
  });

  @override
  State<RestCartPage> createState() => _RestCartPageState();
}

class _RestCartPageState extends State<RestCartPage> {
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
          .select(
              'menu_id, name, price, rating, cooking_time, image_url, category')
          .eq('name', item.key)
          .single();

      if (response.isNotEmpty) {
        final price = (response['price'] as num).toDouble();
        final quantity = item.value;
        response['quantity'] = quantity;
        items.add(response);
        total += price * quantity;
      }
    }

    setState(() {
      detailedCartItems = items;
      itemTotal = total;
    });
  }

  Future<String?> _createOrder() async {
    if (widget.restaurantId == null) {
      throw Exception('Restaurant information is missing');
    }

    try {
      // 1. Prepare order items
      final List<Map<String, dynamic>> orderItems = [];
      for (final item in detailedCartItems) {
        orderItems.add({
          'name': item['name'].toString(),
          'price': double.parse(item['price'].toString()),
          'rating': double.parse(item['rating'].toString()),
          'status': 'Received',
          'menu_id': item['menu_id'] as int,
          'category': item['category'].toString(),
          'quantity': int.parse(item['quantity'].toString()),
          'image_url': item['image_url'].toString(),
          'cooking_time': item['cooking_time'].toString(),
        });
      }

      // 2. Get user details properly
      final user = supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User authentication required');
      }

      // Get username from users table if not in auth
      final userData = await supabase
          .from('users')
          .select('username, phone_number')
          .eq('user_id', user.id)
          .maybeSingle();

      final username = userData?['username']?.toString() ??
          user.email?.split('@').first ??
          'Guest';
      final phoneNumber = userData?['phone_number']?.toString() ?? '';

      // 3. Create the order
      final orderId = const Uuid().v4();
      final now = DateTime.now().toUtc().toIso8601String();

      final orderResponse = await supabase
          .from('orders')
          .insert({
            'order_id': orderId,
            'restaurant_id': widget.restaurantId!.toString(),
            'user_id': user.id.toString(),
            'username': username,
            'user_number': phoneNumber,
            'items': orderItems,
            'total_price': totalAmount.toString(),
            'status': 'Received',
            'order_time': now,
            'update_time': now,
          })
          .select('order_id')
          .single();

      // 4. Force update restaurant table
      if (widget.tableId != null && widget.tableId!.isNotEmpty) {
        try {
          await supabase.from('restaurant_tables').update({
            'is_reserved': true,
            'order_id': orderId.toString(),
            'updated_at': now,
          }).eq('table_id', widget.tableId!.toString());

          // Verify update was successful
          final updatedTable = await supabase
              .from('restaurant_tables')
              .select('order_id')
              .eq('table_id', widget.tableId!)
              .single();

          if (updatedTable['order_id']?.toString() != orderId) {
            throw Exception('Failed to update table with order ID');
          }
        } catch (e) {
          if (kDebugMode) {
            print('Table update error: $e');
          }
          throw Exception('Failed to reserve table: ${e.toString()}');
        }
      }

      return orderId;
    } catch (e) {
      if (kDebugMode) {
        print('Order creation error: ${e.toString()}');
      }
      rethrow;
    }
  }

  void _handleCheckout() async {
    try {
      final orderId = await _createOrder();

      if (!mounted) return;

      if (orderId != null) {
        _showOrderSuccessDialog();

        Future.delayed(const Duration(seconds: 1), () {
          if (!mounted) return;

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => StatusPage(orderId: orderId),
            ),
          ).then((_) {
            if (mounted) {
              Provider.of<CartState>(context, listen: false)
                  .resetCartAfterCheckout();
              Provider.of<SliderState>(context, listen: false)
                  .resetAllSliders();
            }
          });
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  void _openSideMenu() {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        pageBuilder: (_, __, ___) => const RoleBasedSideMenu(),
      ),
    );
  }

  void _showOrderSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
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
          ],
        ),
      ),
    );
  }

  Widget _buildCartItem(
    String itemName,
    String cookingTime,
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
                        setState(() {
                          if (widget.cartItems[itemName] != null) {
                            if (widget.cartItems[itemName]! > 1) {
                              widget.cartItems[itemName] =
                                  widget.cartItems[itemName]! - 1;
                            } else {
                              widget.cartItems.remove(itemName);
                            }
                            _fetchCartDetails();
                          }
                        });
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
              onLeftButtonPressed: () {
                Provider.of<SliderState>(context, listen: false)
                    .resetSliderPosition('cart_checkout');
                Provider.of<SliderState>(context, listen: false)
                    .resetSliderPosition('home_cart');
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => RestMenuPage(
                    ),
                  ),
                );
              },
              headingText: 'Cart',
              headingIcon: Iconsax.book_saved,
              rightIcon: Iconsax.menu_1,
              onRightButtonPressed: _openSideMenu,
            ),
            const SizedBox(height: 20),
            if (widget.tableNumber != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Text(
                  'Table ${widget.tableNumber}',
                  style: const TextStyle(
                    color: Color(0xFFEEEFEF),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            const SizedBox(height: 10),
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
            _buildPriceSummary(),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: SliderButton(
                labelText: 'Checkout',
                subText: '\$${totalAmount.toStringAsFixed(2)}',
                onSlideComplete: _handleCheckout,
                pageId: 'cart_checkout',
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

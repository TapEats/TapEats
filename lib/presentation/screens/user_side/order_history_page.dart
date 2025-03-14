import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tapeats/presentation/screens/user_side/cart_page.dart';
import 'package:tapeats/presentation/state_management/cart_state.dart';
import 'package:tapeats/presentation/state_management/slider_state.dart';
import 'package:tapeats/presentation/widgets/header_widget.dart';
import 'package:tapeats/presentation/widgets/sidemenu_overlay.dart';
import 'package:tapeats/presentation/widgets/slider_button.dart';
import 'package:tapeats/presentation/widgets/order_detail_widget.dart';

class OrderHistoryPage extends StatefulWidget {
  const OrderHistoryPage({
    super.key,
  });

  @override
  State<OrderHistoryPage> createState() => _OrderHistoryPageState();
}

class _OrderHistoryPageState extends State<OrderHistoryPage> {
  final SupabaseClient supabase = Supabase.instance.client;
  List<Map<String, dynamic>> orderHistoryItems = [];
  String? userPhoneNumber;

  @override
  void initState() {
    super.initState();
    _initializeUserData();
  }

  void _openSideMenu() {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        pageBuilder: (_, __, ___) => const SideMenuOverlay(),
      ),
    );
  }

  Future<void> _initializeUserData() async {
    await _getUserPhoneNumber();
    if (userPhoneNumber != null) {
      await _fetchOrderHistory();
    }
  }

  Future<void> _getUserPhoneNumber() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      // Try to get phone number from session metadata first
      final session = supabase.auth.currentSession;
      if (session?.user.phone != null) {
        setState(() {
          userPhoneNumber = session!.user.phone;
        });
        return;
      }

      // Fallback to users table if not in session
      final response = await supabase
          .from('users')
          .select('phone_number')
          .eq('user_id', user.id)
          .single();

      if (response.isNotEmpty) {
        setState(() {
          userPhoneNumber = response['phone_number'] as String;
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching user phone number: $e');
      }
    }
  }

  Future<void> _fetchOrderHistory() async {
    try {
      if (userPhoneNumber == null) return;

      // Fetch only orders with status "Served"
      final response = await supabase
          .from('orders')
          .select()
          .eq('user_number', userPhoneNumber as Object)
          .eq('status', 'Served')
          .order('order_time', ascending: false);

      if (response.isNotEmpty) {
        setState(() {
          orderHistoryItems = List<Map<String, dynamic>>.from(response);
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching order history: $e');
      }
    }
  }

  // Logic to handle reordering and adding to cart
  void _reorder(Map<String, dynamic> order) {
    final items = List<Map<String, dynamic>>.from(order['items'] as List<dynamic>);
    final cartState = Provider.of<CartState>(context, listen: false);

    // Add items from the selected order to the cart
    for (var item in items) {
      final itemName = item['name'] as String;
      final quantity = item['quantity'] as int;
      
      // Add items to cart using CartState provider
      for (var i = 0; i < quantity; i++) {
        cartState.addItem(itemName);
      }
    }

    // Redirect to the cart page after reordering
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
          children: [
            HeaderWidget(
              leftIcon: Iconsax.arrow_left_1,
              onLeftButtonPressed: () => Navigator.pop(context),
              headingText: 'Order History',
              headingIcon: Iconsax.calendar,
              rightIcon: Iconsax.menu_1,
              onRightButtonPressed: _openSideMenu,
            ),
            const SizedBox(height: 20),
            Expanded(
              child: orderHistoryItems.isEmpty
                  ? const Center(
                      child: Text(
                        'No orders found',
                        style: TextStyle(
                          color: Color(0xFFEEEFEF),
                          fontSize: 16,
                          fontFamily: 'Helvetica Neue',
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      itemCount: orderHistoryItems.length,
                      itemBuilder: (context, index) {
                        final order = orderHistoryItems[index];
                        final items = List<Map<String, dynamic>>.from(
                            order['items'] as List<dynamic>);

                        return OrderDetailWidget(
                          orderId: order['order_id'].toString(),
                          userName: order['username'] ?? "Customer",
                          items: items,
                          orderTime: DateTime.parse(order['order_time']),
                          status: order['status'],
                          onReorder: () => _reorder(order),
                          showReorderButton: true,
                        );
                      },
                    ),
            ),
            
            // Consumer to listen to CartState changes
            Consumer<CartState>(
              builder: (context, cartState, child) {
                return cartState.totalItems > 0
                    ? Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A1A1A),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Cart Items (${cartState.totalItems})',
                                  style: const TextStyle(
                                    color: Color(0xFFEEEFEF),
                                    fontSize: 18,
                                    fontFamily: 'Helvetica Neue',
                                  ),
                                ),
                                // Note: Price calculation would need actual item price data
                                // which isn't available in the cart state alone
                                const Text(
                                  'View in cart',
                                  style: TextStyle(
                                    color: Color(0xFFD0F0C0),
                                    fontSize: 18,
                                    fontFamily: 'Helvetica Neue',
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 15),
                            SliderButton(
                              labelText: 'Swipe to Cart',
                              subText: '${cartState.totalItems} items',
                              onSlideComplete: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => CartPage(
                                      cartItems: cartState.cartItems,
                                      totalItems: cartState.totalItems,
                                    ),
                                  ),
                                );
                              },
                              pageId: 'history_cart',
                              width: screenWidth * 0.8,
                              height: screenHeight * 0.07,
                            ),
                          ],
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
}
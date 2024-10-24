import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tapeats/presentation/screens/user_side/cart_page.dart';
import 'package:tapeats/presentation/widgets/header_widget.dart';
import 'package:tapeats/presentation/widgets/slider_button.dart';
import 'package:tapeats/presentation/widgets/add_button.dart';
import 'package:tapeats/presentation/widgets/plus_button.dart';
import 'package:tapeats/presentation/widgets/minus_button.dart';

class OrderHistoryPage extends StatefulWidget {
  final Map<String, int> cartItems;
  final int totalItems;
  const OrderHistoryPage({
    super.key,
    required this.cartItems,
    required this.totalItems,
  });

  @override
  State<OrderHistoryPage> createState() => _OrderHistoryPageState();
}

class _OrderHistoryPageState extends State<OrderHistoryPage> {
  final SupabaseClient supabase = Supabase.instance.client;
  List<Map<String, dynamic>> orderHistoryItems = [];
  Map<String, int> cartItems = {};
  int totalItems = 0;
  String? userPhoneNumber;

  @override
  void initState() {
    super.initState();
    cartItems = Map.from(widget.cartItems);
    totalItems = widget.totalItems;
    _initializeUserData();
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

  void _addItemToCart(Map<String, dynamic> item) {
    setState(() {
      final itemName = item['name'] as String;
      if (cartItems.containsKey(itemName)) {
        cartItems[itemName] = cartItems[itemName]! + 1;
      } else {
        cartItems[itemName] = 1;
      }
      totalItems += 1;
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
              headingText: 'Order History',
              headingIcon: Iconsax.calendar,
              rightIcon: Iconsax.menu_1,
              onRightButtonPressed: () {},
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

                        return _buildOrderCard(order, items);
                      },
                    ),
            ),
            if (totalItems > 0)
              Container(
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
                          'Cart Items ($totalItems)',
                          style: const TextStyle(
                            color: Color(0xFFEEEFEF),
                            fontSize: 18,
                            fontFamily: 'Helvetica Neue',
                          ),
                        ),
                        Text(
                          '\$${_calculateTotalPrice().toStringAsFixed(2)}',
                          style: const TextStyle(
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
                      subText: '$totalItems items',
                      onSlideComplete: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CartPage(
                              cartItems: cartItems,
                              totalItems: totalItems,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderCard(
    Map<String, dynamic> order,
    List<Map<String, dynamic>> items,
  ) {
    final DateTime orderTime = DateTime.parse(order['order_time']);

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Order ID: ${order['order_id'].toString().substring(0, 8)}',
                    style: const TextStyle(
                      color: Color(0xFF8F8F8F),
                      fontSize: 14,
                      fontFamily: 'Helvetica Neue',
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${orderTime.hour}:${orderTime.minute.toString().padLeft(2, '0')}, ${orderTime.day} ${_getMonth(orderTime.month)} ${orderTime.year}',
                    style: const TextStyle(
                      color: Color(0xFF8F8F8F),
                      fontSize: 12,
                      fontFamily: 'Helvetica Neue',
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF2A2A2A),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  order['status'],
                  style: const TextStyle(
                    color: Color(0xFFD0F0C0),
                    fontSize: 14,
                    fontFamily: 'Helvetica Neue',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          ...items.map((item) => _buildOrderItem(item)),
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total',
                style: TextStyle(
                  color: Color(0xFFEEEFEF),
                  fontSize: 16,
                  fontFamily: 'Helvetica Neue',
                ),
              ),
              Text(
                '\$${order['total_price'].toStringAsFixed(2)}',
                style: const TextStyle(
                  color: Color(0xFFD0F0C0),
                  fontSize: 16,
                  fontFamily: 'Helvetica Neue',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getMonth(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return months[month - 1];
  }

  Widget _buildOrderItem(Map<String, dynamic> item) {
    final itemInCart = cartItems[item['name']] ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.network(
              item['image_url'],
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
                Text(
                  item['name'],
                  style: const TextStyle(
                    fontSize: 16,
                    fontFamily: 'Helvetica Neue',
                    color: Color(0xFFEEEFEF),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '${item['cooking_time']} mins • ⭐ ${item['rating']}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontFamily: 'Helvetica Neue',
                    color: Color(0xFF8F8F8F),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '\$${item['price'].toStringAsFixed(2)} × ${item['quantity']}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontFamily: 'Helvetica Neue',
                    color: Color(0xFFD0F0C0),
                  ),
                ),
              ],
            ),
          ),
          if (itemInCart > 0)
            Row(
              children: [
                MinusButton(
                  onPressed: () => _removeItemFromCart(item['name']),
                ),
                const SizedBox(width: 10),
                Text(
                  itemInCart.toString(),
                  style: const TextStyle(
                    color: Color(0xFFEEEFEF),
                    fontSize: 16,
                    fontFamily: 'Helvetica Neue',
                  ),
                ),
                const SizedBox(width: 10),
                PlusButton(
                  onPressed: () => _addItemToCart(item),
                ),
              ],
            )
          else
            AddButton(onPressed: () => _addItemToCart(item)),
        ],
      ),
    );
  }

  double _calculateTotalPrice() {
    double total = 0;
    for (final order in orderHistoryItems) {
      final items =
          List<Map<String, dynamic>>.from(order['items'] as List<dynamic>);

      for (final item in items) {
        if (cartItems.containsKey(item['name'])) {
          total += (item['price'] as num) * cartItems[item['name']]!;
        }
      }
    }
    return total;
  }
}

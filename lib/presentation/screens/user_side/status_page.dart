import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tapeats/presentation/state_management/slider_state.dart';
import 'package:tapeats/presentation/widgets/header_widget.dart';
import 'package:tapeats/presentation/widgets/sidemenu_overlay.dart';
import 'package:carousel_slider/carousel_slider.dart';

class StatusPage extends StatefulWidget {
  final String orderId;
  const StatusPage({super.key, required this.orderId});

  @override
  State<StatusPage> createState() => _StatusPageState();
}

class _StatusPageState extends State<StatusPage> {
  final SupabaseClient supabase = Supabase.instance.client;
  List<Map<String, dynamic>> allOrders = [];
  List<dynamic> orderedItems = [];
  String orderStatus = '';
  double itemTotal = 0.0;
  final double gstCharges = 6.0;
  final double platformFee = 4.0;
  int _currentOrderIndex = 0;

  double get totalAmount => itemTotal + gstCharges + platformFee;

  @override
  void initState() {
    super.initState();
    _fetchAllOrders();
  }

  Future<void> _fetchAllOrders() async {
    try {
      final userPhoneNumber = supabase.auth.currentUser?.phone;
      if (userPhoneNumber == null) return;

      final response = await supabase
          .from('orders')
          .select()
          .eq('user_number', userPhoneNumber)
          .or('status.eq.Received,status.eq.Accepted,status.eq.Cooking,status.eq.Ready')
          .order('order_time', ascending: false);

      if (response.isNotEmpty) {
        setState(() {
          allOrders = List<Map<String, dynamic>>.from(response);
          // Find the index of the current order
          _currentOrderIndex = allOrders.indexWhere((order) => order['order_id'] == widget.orderId);
          if (_currentOrderIndex != -1) {
            _updateOrderDetails(allOrders[_currentOrderIndex]);
          }
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching orders: $e');
      }
    }
  }

  void _updateOrderDetails(Map<String, dynamic> order) {
    setState(() {
      orderedItems = order['items'] ?? [];
      itemTotal = (order['total_price'] as num).toDouble();
      orderStatus = order['status'];
    });
  }

  void _openSideMenu() {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        pageBuilder: (_, __, ___) => const RoleBasedSideMenu(),
      ),
    );
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
              onLeftButtonPressed: () {
                final sliderState = Provider.of<SliderState>(context, listen: false);
                sliderState.setSliderState('cart_checkout', false);
                sliderState.setSliderState('home_cart', false);
                Navigator.popUntil(context, (route) => route.isFirst);
              },
              headingText: 'Order Status',
              headingIcon: Iconsax.clock,
              rightIcon: Iconsax.menu_1,
              onRightButtonPressed: _openSideMenu,
            ),
            if (allOrders.length > 1) _buildOrderSelector(),
            const SizedBox(height: 20),
            _buildOrderInfoSection(),
            const SizedBox(height: 20),
            _buildOrderedItems(),
            const SizedBox(height: 20),
            _buildPriceSummary(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderSelector() {
    return Container(
      height: 60,
      margin: const EdgeInsets.only(top: 20),
      child: CarouselSlider.builder(
        itemCount: allOrders.length,
        options: CarouselOptions(
          height: 60,
          viewportFraction: 0.8,
          enableInfiniteScroll: allOrders.length > 1,
          enlargeCenterPage: true,
          initialPage: _currentOrderIndex,
          onPageChanged: (index, reason) {
            setState(() {
              _currentOrderIndex = index;
              _updateOrderDetails(allOrders[index]);
            });
          },
        ),
        itemBuilder: (context, index, realIndex) {
          final order = allOrders[index];
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: _currentOrderIndex == index 
                  ? const Color(0xFF222222)
                  : const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _currentOrderIndex == index 
                    ? const Color(0xFFD0F0C0)
                    : const Color(0xFF222222),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Order #${order['order_id'].toString().substring(0, 8)}',
                  style: TextStyle(
                    color: _currentOrderIndex == index 
                        ? const Color(0xFFD0F0C0)
                        : const Color(0xFFEEEFEF),
                    fontSize: 16,
                    fontFamily: 'Helvetica Neue',
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _currentOrderIndex == index 
                        ? const Color(0xFF1A1A1A)
                        : const Color(0xFF222222),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    order['status'],
                    style: const TextStyle(
                      color: Color(0xFF8F8F8F),
                      fontSize: 12,
                      fontFamily: 'Helvetica Neue',
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildOrderInfoSection() {
    return Container(
      padding: const EdgeInsets.all(15),
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Iconsax.call, color: Color(0xFFD0F0C0)),
                  SizedBox(width: 10),
                  Icon(Iconsax.message, color: Color(0xFFD0F0C0)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Order ID: #${widget.orderId}',
            style: const TextStyle(
              color: Color(0xFF8F8F8F),
              fontFamily: 'Helvetica Neue',
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 20),
          _buildStatusTracker(),
        ],
      ),
    );
  }

  Widget _buildStatusTracker() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _StatusStep(
          icon: Iconsax.box,
          label: 'Received',
          time: '12:00pm',
          isActive: orderStatus == 'Received' || orderStatus == 'Accepted' || orderStatus == 'Cooking' || orderStatus == 'Ready',
        ),
        _StatusStep(
          icon: Iconsax.tick_circle,
          label: 'Accepted',
          time: '12:01pm',
          isActive: orderStatus == 'Accepted' || orderStatus == 'Cooking' || orderStatus == 'Ready',
        ),
        _StatusStep(
          icon: Iconsax.timer,
          label: 'Cooking',
          time: '12:02pm',
          isActive: orderStatus == 'Cooking' || orderStatus == 'Ready',
        ),
        _StatusStep(
          icon: Iconsax.timer,
          label: 'Ready!',
          time: '12:04pm',
          isActive: orderStatus == 'Ready',
        ),
      ],
    );
  }

  Widget _buildOrderedItems() {
    return Expanded(
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        itemCount: orderedItems.length,
        itemBuilder: (context, index) {
          final item = orderedItems[index];
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
                Text(
                  itemName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontFamily: 'Helvetica Neue',
                    color: Color(0xFFEEEFEF),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '$cookingTime • ⭐ $rating',
                  style: const TextStyle(
                    fontSize: 14,
                    fontFamily: 'Helvetica Neue',
                    color: Color(0xFF8F8F8F),
                  ),
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
      margin: const EdgeInsets.symmetric(horizontal: 20),
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
    return
        Padding(
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

class _StatusStep extends StatelessWidget {
  final IconData icon;
  final String label;
  final String time;
  final bool isActive;

  const _StatusStep({
    required this.icon,
    required this.label,
    required this.time,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CircleAvatar(
          backgroundColor: isActive ? const Color(0xFFD0F0C0) : const Color(0xFF1A1A1A),
          child: Icon(
            icon,
            color: isActive ? const Color(0xFF1A1A1A) : const Color(0xFFD0F0C0),
          ),
        ),
        const SizedBox(height: 5),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Helvetica Neue',
            fontSize: 14,
            color: Color(0xFFEEEFEF),
          ),
        ),
        Text(
          time,
          style: const TextStyle(
            fontFamily: 'Helvetica Neue',
            fontSize: 12,
            color: Color(0xFF8F8F8F),
          ),
        ),
      ],
    );
  }
}


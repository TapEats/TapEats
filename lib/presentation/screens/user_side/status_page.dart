import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tapeats/presentation/state_management/slider_state.dart';
import 'package:tapeats/presentation/widgets/header_widget.dart';
import 'package:tapeats/presentation/widgets/sidemenu_overlay.dart';

class StatusPage extends StatefulWidget {
  final String orderId; // Order ID to fetch details
  const StatusPage({super.key, required this.orderId});

  @override
  State<StatusPage> createState() => _StatusPageState();
}

class _StatusPageState extends State<StatusPage> {
  final SupabaseClient supabase = Supabase.instance.client;
  List<dynamic> orderedItems = [];
  String orderStatus = '';
  double itemTotal = 0.0;
  final double gstCharges = 6.0;
  final double platformFee = 4.0;

  double get totalAmount => itemTotal + gstCharges + platformFee;

  @override
  void initState() {
    super.initState();
    _fetchOrderDetails();
  }

  Future<void> _fetchOrderDetails() async {
    try {
      // Fetch the order details from Supabase using the order ID
      final response = await supabase
          .from('orders')
          .select('items, total_price, status')
          .eq('order_id', widget.orderId)
          .single();

      if (response.isNotEmpty) {
        setState(() {
          orderedItems = response['items'] ?? [];
          itemTotal = (response['total_price'] as num).toDouble();
          orderStatus = response['status'];
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching order details: $e');
      }
    }
  }

  void _openSideMenu() {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        pageBuilder: (_, __, ___) => const SideMenuOverlay(),
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
            // Header Widget
            HeaderWidget(
  leftIcon: Iconsax.arrow_left_1,
  onLeftButtonPressed: () {
    final sliderState = Provider.of<SliderState>(context, listen: false);
    // Reset both sliders
    sliderState.setSliderState('cart_checkout', false);
    sliderState.setSliderState('home_cart', false);
    
    // Navigate back to home page, removing cart page from stack
    Navigator.popUntil(context, (route) => route.isFirst);
  },
  headingText: 'Order Status',
  headingIcon: Iconsax.clock,
  rightIcon: Iconsax.menu_1,
  onRightButtonPressed: _openSideMenu,
),
            const SizedBox(height: 20),

            // Order Info and Status Tracker
            _buildOrderInfoSection(),

            const SizedBox(height: 20),

            // Food Items Ordered
            _buildOrderedItems(),

            const SizedBox(height: 20),

            // Price Summary
            _buildPriceSummary(),
          ],
        ),
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


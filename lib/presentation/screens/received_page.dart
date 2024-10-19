import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tapeats/presentation/widgets/custom_footer_five_button_widget.dart';
import 'package:tapeats/presentation/widgets/header_widget.dart';
import 'package:tapeats/presentation/widgets/restaurant_order_detail_widget.dart';

class ReceivedOrdersPage extends StatefulWidget {
  final int selectedIndex;
  const ReceivedOrdersPage({super.key, required this.selectedIndex});

  @override
  State<ReceivedOrdersPage> createState() => _ReceivedOrdersPageState();
}

class _ReceivedOrdersPageState extends State<ReceivedOrdersPage> {
  final SupabaseClient supabase = Supabase.instance.client;

  Future<List<dynamic>> _fetchOrders() async {
    final response = await supabase
        .from('orders')
        .select(
            'username, order_id, order_time, items, total_price, user_number, status')
        .eq('status', "received");

    if (kDebugMode) {
      print('Response data: $response');
    }

    if (response.isEmpty) {
      if (kDebugMode) {
        print('Error fetching orders: $response');
      }
      return [];
    }

    return response as List<dynamic>;
  }

  void _updateOrderStatus(String orderId, String status) async {
    await supabase
        .from('orders')
        .update({'status': status}).eq('order_id', orderId);
    setState(() {}); // Refresh the UI after updating
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF222222),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        flexibleSpace: HeaderWidget(
          leftIcon: Icons.arrow_back,
          onLeftButtonPressed: () => Navigator.pop(context),
          headingText: "Received Orders",
          rightIcon: Icons.settings,
          onRightButtonPressed: () {},
        ),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _fetchOrders(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error: ${snapshot.error}',
                style: const TextStyle(color: Colors.red),
              ),
            );
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                'No received orders',
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          final orders = snapshot.data!;

          return ListView.builder(
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];
              final List<dynamic> items = order['items'];

              return OrderDetailWidget(
                username: order['username'],
                orderId: order['order_id'],
                orderTime: order['order_time'],
                items: items,
                totalPrice: order['total_price'],
                userNumber: order['user_number'],
                onCallPressed: () {
                  // Call user logic (e.g., initiate a phone call)
                },
                onMessagePressed: () {
                  // Message user logic (e.g., open SMS)
                },
                onCancelPressed: () =>
                    _updateOrderStatus(order['order_id'], 'cancelled'),
                onAcceptPressed: () =>
                    _updateOrderStatus(order['order_id'], 'accepted'),
              );
            },
          );
        },
      ),

      bottomNavigationBar:
          const CustomFiveFooter(selectedIndex: 1), // Your footer widget
    );
  }
}

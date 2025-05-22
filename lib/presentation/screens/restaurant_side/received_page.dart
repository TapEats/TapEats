import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tapeats/presentation/widgets/header_widget.dart';
import 'package:tapeats/presentation/widgets/order_detail_widget.dart';

class ReceivedOrdersPage extends StatefulWidget {
  const ReceivedOrdersPage({super.key});

  @override
  State<ReceivedOrdersPage> createState() => _ReceivedOrdersPageState();
}

class _ReceivedOrdersPageState extends State<ReceivedOrdersPage> {
  final SupabaseClient supabase = Supabase.instance.client;
  final List<String> _visibleStatuses = ['Received', 'Accepted', 'Cooking'];

  Future<void> _updateOrderStatus(String orderId, String status) async {
    try {
      await supabase
          .from('orders')
          .update({'status': status}).eq('order_id', orderId);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Status updated to $status'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 1),
        ),
      );
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update status: $error'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Stream<List<Map<String, dynamic>>> _getOrdersStream() {
    return supabase.from('orders').stream(primaryKey: ['order_id']).map(
        (orders) => orders
            .where((order) => _visibleStatuses.contains(order['status']))
            .toList());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF151611),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: HeaderWidget(
                leftIcon: Iconsax.arrow_left_1,
                onLeftButtonPressed: () => Navigator.pop(context),
                headingText: "Received Orders",
                rightIcon: Iconsax.menu_1,
                onRightButtonPressed: () {},
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 20)),
            SliverFillRemaining(
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: _getOrdersStream(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFFD0F0C0),
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Error: ${snapshot.error}',
                        style: const TextStyle(color: Color(0xFFD0F0C0)),
                      ),
                    );
                  }

                  final orders = snapshot.data ?? [];
                  if (orders.isEmpty) {
                    return const Center(
                      child: Text(
                        'No orders available',
                        style: TextStyle(color: Color(0xFFD0F0C0)),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: orders.length,
                    itemBuilder: (context, index) {
                      final order = orders[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: OrderDetailWidget(
                          key: ValueKey(order['order_id']),
                          orderId: order['order_id'],
                          userName: order['username'],
                          items:
                              List<Map<String, dynamic>>.from(order['items']),
                          orderTime: DateTime.parse(order['order_time']),
                          status: order['status'],
                          isRestaurantSide: true,
                          currentPage: 'received_page.dart',
                          onStatusChanged: (newStatus) async {
                            await _updateOrderStatus(
                                order['order_id'], newStatus);
                          },
                          onCallPressed: () => debugPrint(
                              "Call pressed for ${order['user_number']}"),
                          onWhatsAppPressed: () => debugPrint(
                              "WhatsApp pressed for ${order['user_number']}"),
                          onCancel: () => _updateOrderStatus(
                              order['order_id'], 'Cancelled'),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

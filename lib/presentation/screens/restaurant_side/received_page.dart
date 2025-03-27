import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tapeats/presentation/state_management/navbar_state.dart';
import 'package:tapeats/presentation/widgets/footer_widget.dart';
import 'package:tapeats/presentation/widgets/header_widget.dart';
import 'package:tapeats/presentation/widgets/order_detail_widget.dart';

class ReceivedOrdersPage extends StatefulWidget {
  final int selectedIndex;
  const ReceivedOrdersPage({super.key, required this.selectedIndex});

  @override
  State<ReceivedOrdersPage> createState() => _ReceivedOrdersPageState();
}

class _ReceivedOrdersPageState extends State<ReceivedOrdersPage> {
  final SupabaseClient supabase = Supabase.instance.client;

  Future<void> _fetchOrders() async {
    try {
      // Fetching order details from the database
      final response = await supabase
          .from('orders')
          .select(
              'username, order_id, order_time, items, total_price, user_number, status')
          .eq('status', "Received");

      if (kDebugMode) {
        print('Response: $response');
      }

      // If no orders are found
      if (response.isEmpty) {
        if (kDebugMode) {
          print('No orders with "Received" status');
        }
        setState(() {
        });
        return;
      }

      // Update the state with fetched orders
      setState(() {
      });
    } catch (error) {
      if (kDebugMode) {
        print('Error fetching orders: $error');
      }
      // Ensure the state is cleared if an error occurs
      setState(() {
      });
    }
  }

  Future<void> _updateOrderStatus(String orderId, String status) async {
    try {
      final response = await supabase
          .from('orders')
          .update({'status': status}).eq('order_id', orderId);

      if (response.isNotEmpty) {
        if (kDebugMode) {
          print('Order status updated to $status');
        }

        // Refresh orders after updating the status
        _fetchOrders();
      } else {
        if (kDebugMode) {
          print('Error: Order status update failed.');
        }
      }
    } catch (error) {
      if (kDebugMode) {
        print('Error updating order status: $error');
      }
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final navbarState = Provider.of<NavbarState>(context, listen: false);
      navbarState.updateIndex(widget.selectedIndex);
    });
    supabase.from('orders').stream(primaryKey: ['order_id']).listen((event) {
      _fetchOrders();
    });
    // Subscribe to the 'orders' table for changes related to 'Received' orders
  }

  @override
  void dispose() {
    // Unsubscribe when the page is disposed
    // supabase.removeSubscription(_subscription);
    // supabase.removeChannel(_su)
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xFF151611), // Background color for the scaffold

      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // HeaderWidget added as the first sliver
            SliverToBoxAdapter(
              child: HeaderWidget(
                leftIcon: Iconsax.arrow_left_1,
                onLeftButtonPressed: () => Navigator.pop(context),
                headingText: "Received Orders",
                rightIcon: Iconsax.menu_1,
                onRightButtonPressed: () {},
              ),
            ),
            const SliverToBoxAdapter(
              child: SizedBox(height: 20),
            ),
            SliverFillRemaining(
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: supabase
                    .from('orders')
                    .stream(primaryKey: ['order_id'])
                    .eq('status', 'Received')
                    .map((orders) => orders.map((order) => order).toList()),
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
                      final List<Map<String, dynamic>> items =
                          List<Map<String, dynamic>>.from(order['items']);
                      final DateTime orderTime =
                          DateTime.parse(order['order_time']);

                      return OrderDetailWidget(
                        orderId: order['order_id'],
                        userName: order['username'],
                        items: items,
                        orderTime: orderTime,
                        status: order['status'],
                        onCallPressed: () {
                          if (kDebugMode) {
                            print(
                                "Call pressed for user: ${order['user_number']}");
                          }
                        },
                        onWhatsAppPressed: () {
                          if (kDebugMode) {
                            print(
                                "WhatsApp pressed for user: ${order['user_number']}");
                          }
                        },
                        onAccept: () {
                          _updateOrderStatus(order['order_id'], 'Accepted');
                        },
                        onCancel: () {
                          _updateOrderStatus(order['order_id'], 'Cancelled');
                        },
                        isRestaurantSide: true,
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    extendBody: true, // Important for curved navigation bar
      bottomNavigationBar: const DynamicFooter(), // Using DynamicFooter instead
    );
  }
}

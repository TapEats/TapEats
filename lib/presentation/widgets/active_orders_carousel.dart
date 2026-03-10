import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tapeats/presentation/screens/user_side/status_page.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:intl/intl.dart';

class ActiveOrdersCarousel extends StatefulWidget {
  const ActiveOrdersCarousel({super.key});

  @override
  State<ActiveOrdersCarousel> createState() => _ActiveOrdersCarouselState();
}

class _ActiveOrdersCarouselState extends State<ActiveOrdersCarousel> {
  final SupabaseClient supabase = Supabase.instance.client;
  List<Map<String, dynamic>> activeOrders = [];
  int _currentIndex = 0;
  bool _isLoading = true;
  String? _error;
  Timer? _refreshTimer;
  StreamSubscription? _ordersSubscription;

  @override
  void initState() {
    super.initState();
    _initializeOrdersStream();
    _fetchActiveOrders();
    // Refresh every 30 seconds
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _fetchActiveOrders();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _ordersSubscription?.cancel();
    super.dispose();
  }

  void _initializeOrdersStream() {
    final userPhoneNumber = supabase.auth.currentUser?.phone;
    if (userPhoneNumber == null) return;

    _ordersSubscription = supabase
        .from('orders')
        .stream(primaryKey: ['order_id'])
        .eq('user_number', userPhoneNumber)
        .listen((List<Map<String, dynamic>> data) {
      if (mounted) {
        _fetchActiveOrders();
      }
    });
  }

  Future<void> _fetchActiveOrders() async {
    if (kDebugMode) {
      print('Fetching active orders...');
    }

    if (!mounted) return; // Add this line
    
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final userPhoneNumber = supabase.auth.currentUser?.phone;
    
    if (userPhoneNumber == null) {
      if (!mounted) return; // Add this check
      setState(() {
        _isLoading = false;
        _error = 'No user phone number found';
      });
      return;
    }

    try {
      final response = await supabase
          .from('orders')
          .select('''
            order_id,
            status,
            order_time,
            total_price,
            items
          ''')
          .eq('user_number', userPhoneNumber)
          .or('status.eq.Received,status.eq.Accepted,status.eq.Cooking,status.eq.Ready')
          .order('order_time', ascending: false);

      if (kDebugMode) {
        print('Supabase response: $response');
      }

      if (!mounted) return; // Add this check
      
      if (response.isNotEmpty) {
        setState(() {
          activeOrders = List<Map<String, dynamic>>.from(response);
          _isLoading = false;
        });
      } else {
        setState(() {
          activeOrders = [];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching orders: $e');
      }
      if (!mounted) return; // Add this check
      setState(() {
        _isLoading = false;
        _error = 'Error loading orders: $e';
      });
    }
  }

  String _getOrderSummary(List<dynamic> items) {
    if (items.isEmpty) return 'No items';
    
    // Get the first item and its quantity
    final firstItem = items[0];
    String summary = '${firstItem['quantity']}x ${firstItem['name']}';
    
    // If there are more items, add a summary
    if (items.length > 1) {
      summary += ' +${items.length - 1} more';
    }
    
    return summary;
  }

  String _formatDateTime(String dateTimeString) {
    final dateTime = DateTime.parse(dateTimeString);
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return DateFormat('MMM d, h:mm a').format(dateTime);
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'received':
        return Colors.blue;
      case 'accepted':
        return Colors.orange;
      case 'cooking':
        return Colors.yellow;
      case 'ready':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: CircularProgressIndicator(
            color: Color(0xFFD0F0C0),
          ),
        ),
      );
    }

    if (_error != null || activeOrders.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Column(
        children: [
          CarouselSlider.builder(
            itemCount: activeOrders.length,
            options: CarouselOptions(
              height: 140,
              viewportFraction: 0.93,
              enableInfiniteScroll: activeOrders.length > 1,
              enlargeCenterPage: true,
              onPageChanged: (index, reason) {
                setState(() {
                  _currentIndex = index;
                });
              },
            ),
            itemBuilder: (context, index, realIndex) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 5.0),
                child: _buildOrderCard(activeOrders[index]),
              );
            },
          ),
          if (activeOrders.length > 1) ...[
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: activeOrders.asMap().entries.map((entry) {
                return Container(
                  width: 8.0,
                  height: 8.0,
                  margin: const EdgeInsets.symmetric(horizontal: 4.0),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _currentIndex == entry.key
                        ? const Color(0xFFD0F0C0)
                        : const Color(0xFF222222),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    final List<dynamic> items = List<dynamic>.from(order['items'] ?? []);
    final status = order['status'] ?? 'Unknown';
    final orderTime = order['order_time'] ?? DateTime.now().toIso8601String();
    final totalPrice = order['total_price']?.toDouble() ?? 0.0;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: _getStatusColor(status).withAlpha(77),
          width: 2,
        ),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _getStatusColor(status),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        status,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Color(0xFFEEEFEF),
                          fontWeight: FontWeight.w400,
                          fontFamily: 'Helvetica Neue',
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  _getOrderSummary(items),
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFFEEEFEF),
                    fontWeight: FontWeight.w300,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  _formatDateTime(orderTime),
                  style: TextStyle(
                    fontSize: 11,
                    color: const Color(0xFFEEEFEF).withAlpha(179),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '\$${totalPrice.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: Color(0xFFD0F0C0),
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => StatusPage(
                        orderId: order['order_id'],
                      ),
                    ),
                  ).then((_) => _fetchActiveOrders());
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD0F0C0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  minimumSize: const Size(0, 32),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'View',
                      style: TextStyle(
                        color: Color(0xFF151611),
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Helvetica Neue',
                      ),
                    ),
                    const SizedBox(width: 4),
                    Image.asset(
                      'assets/images/cookthecook.gif',
                      width: 18,
                      height: 18,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
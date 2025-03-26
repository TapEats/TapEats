import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:iconsax/iconsax.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class OrderDetailWidget extends StatefulWidget {
  final String orderId;
  final String userName;
  final List<Map<String, dynamic>> items;
  final DateTime orderTime;
  final String status;
  final bool isRestaurantSide;
  final String currentPage;
  final VoidCallback? onCancel;
  final VoidCallback? onReorder;
  final VoidCallback? onCallPressed;
  final VoidCallback? onWhatsAppPressed;
  final Function(String)? onStatusChanged;

  const OrderDetailWidget({
    super.key,
    required this.orderId,
    required this.userName,
    required this.items,
    required this.orderTime,
    required this.status,
    required this.isRestaurantSide,
    required this.currentPage,
    this.onCancel,
    this.onReorder,
    this.onCallPressed,
    this.onWhatsAppPressed,
    this.onStatusChanged,
  });

  @override
  State<OrderDetailWidget> createState() => _OrderDetailWidgetState();
}

class _OrderDetailWidgetState extends State<OrderDetailWidget> {
  late String orderStatus;
  final supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    orderStatus = widget.status;
  }

  void updateOrderStatus(String newStatus) async {
    try {
      await supabase
          .from('orders')
          .update({'status': newStatus}).eq('order_id', widget.orderId);

      setState(() => orderStatus = newStatus);
      widget.onStatusChanged?.call(newStatus);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update status: $e')),
      );
    }
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

  Widget _buildStatusTracker() {
    final statuses = ['Received', 'Accepted', 'Cooking', 'Ready'];
    final statusTimes = {
      'Received': '12:00pm',
      'Accepted': '12:01pm',
      'Cooking': '12:02pm',
      'Ready': '12:04pm',
    };

    return Column(
      children: [
        const SizedBox(height: 15),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: statuses.map((status) {
            final isActive = status == orderStatus;
            final isCompleted =
                statuses.indexOf(status) < statuses.indexOf(orderStatus);
            final isEnabled = isCompleted ||
                statuses.indexOf(status) <= statuses.indexOf(orderStatus) + 1;

            return GestureDetector(
              onTap: isEnabled ? () => updateOrderStatus(status) : null,
              child: Column(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: isActive || isCompleted
                          ? const Color(
                              0xFFD0F0C0) // Light background for active/completed
                          : const Color(
                              0xFF151611), // Dark background for inactive
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: SvgPicture.asset(
                        'assets/icons/$status.svg',
                        color: isActive || isCompleted
                            ? const Color(
                                0xFF151611) // Dark icon for active/completed
                            : const Color(
                                0xFFD0F0C0), // Light icon for inactive
                        width: 24,
                        height: 24,
                      ),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    status,
                    style: TextStyle(
                      color: isActive || isCompleted
                          ? const Color(
                              0xFFD0F0C0) // Light text for active/completed
                          : const Color(
                              0xFFD0F0C0), // Light text for inactive too
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    statusTimes[status] ?? '',
                    style: const TextStyle(
                      color: Color(0xFFD0F0C0), // Always light color for time
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
        if (orderStatus != 'Ready' &&
            orderStatus != 'Cancelled' &&
            widget.isRestaurantSide)
          Padding(
            padding: const EdgeInsets.only(top: 20),
            child: ElevatedButton(
              onPressed: () {
                updateOrderStatus('Cancelled');
                widget.onCancel?.call();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD0F0C0), // Light background
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
              child: const Text(
                'Cancel Order',
                style: TextStyle(color: Color(0xFF151611)), // Dark text
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(51),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Order header information
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Order ID: #${widget.orderId}',
                      style: const TextStyle(
                        color: Color(0xFFEEEFEF),
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'User Name: ${widget.userName}',
                      style: const TextStyle(
                        color: Color(0xFFEEEFEF),
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '${widget.orderTime.hour}:${widget.orderTime.minute.toString().padLeft(2, '0')}, ${widget.orderTime.day} ${_getMonth(widget.orderTime.month)} ${widget.orderTime.year}',
                      style: const TextStyle(
                        color: Color(0xFFEEEFEF),
                        fontSize: 12,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: const Color(0xFF222222),
                    child: IconButton(
                      icon: const Icon(Iconsax.call, color: Color(0xFFD0F0C0)),
                      onPressed: widget.onCallPressed,
                    ),
                  ),
                  const SizedBox(width: 10),
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: const Color(0xFF222222),
                    child: IconButton(
                      icon: const Icon(Iconsax.sms, color: Color(0xFFD0F0C0)),
                      onPressed: widget.onWhatsAppPressed,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Order items list
          SizedBox(
            height: widget.items.length * 100 > 150
                ? 150
                : widget.items.length * 100,
            child: ListView.builder(
              itemCount: widget.items.length,
              itemBuilder: (context, index) {
                final item = widget.items[index];
                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 5),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF222222),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(
                          item['image_url'],
                          width: 70,
                          height: 70,
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
                                color: Color(0xFFEEEFEF),
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Row(
                              children: [
                                const Icon(Iconsax.timer,
                                    color: Color(0xFFEEEFEF), size: 14),
                                const SizedBox(width: 5),
                                Text(
                                  '${item['cooking_time']}',
                                  style: const TextStyle(
                                    color: Color(0xFFEEEFEF),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w300,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                const Icon(Iconsax.star,
                                    color: Color(0xFFEEEFEF), size: 14),
                                const SizedBox(width: 5),
                                Text(
                                  '${item['rating']}',
                                  style: const TextStyle(
                                    color: Color(0xFFEEEFEF),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w300,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 5),
                            Text(
                              '\$${item['price'].toStringAsFixed(2)} • Qty: ${item['quantity']}',
                              style: const TextStyle(
                                color: Color(0xFFEEEFEF),
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // Status tracker for restaurant side
          if (widget.isRestaurantSide) _buildStatusTracker(),

          const SizedBox(height: 15),

          // Total and action buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total: \$${_calculateTotal()}',
                style: const TextStyle(
                  color: Color(0xFFEEEFEF),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (!widget.isRestaurantSide)
                ElevatedButton(
                  onPressed: widget.onReorder,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD0F0C0),
                    shape: const CircleBorder(),
                    padding: const EdgeInsets.all(8),
                  ),
                  child: const Icon(Iconsax.repeat,
                      size: 24, color: Color(0xFF151611)),
                ),
              if (widget.isRestaurantSide && orderStatus == 'Ready')
                ElevatedButton(
                  onPressed: () => widget.onStatusChanged?.call('Completed'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD0F0C0),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                  ),
                  child: const Text(
                    'Complete Order',
                    style: TextStyle(color: Color(0xFF151611)),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  double _calculateTotal() {
    double total = 0;
    for (var item in widget.items) {
      total += (item['price'] as num) * (item['quantity'] as num);
    }
    return total + 8 + 4; // Adding GST and platform fee
  }
}

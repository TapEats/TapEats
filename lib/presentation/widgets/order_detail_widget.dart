import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

class OrderDetailWidget extends StatelessWidget {
  final String orderId;
  final String userName;
  final List<Map<String, dynamic>> items;
  final DateTime orderTime;
  final String status;
  final bool isRestaurantSide;
  final VoidCallback? onAccept;
  final VoidCallback? onCancel;
  final VoidCallback? onReorder;
  final VoidCallback? onCallPressed;
  final VoidCallback? onWhatsAppPressed;

  const OrderDetailWidget({
    super.key,
    required this.orderId,
    required this.userName,
    required this.items,
    required this.orderTime,
    required this.status,
    required this.isRestaurantSide,
    this.onAccept,
    this.onCancel,
    this.onReorder,
    this.onCallPressed,
    this.onWhatsAppPressed,
  });

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
          // Top Row with Order Details
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Left part with Username and Order Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Order ID: #$orderId',
                      style: const TextStyle(
                        color: Color(0xFFEEEFEF),
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'User Name: $userName',
                      style: const TextStyle(
                        color: Color(0xFFEEEFEF),
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '${orderTime.hour}:${orderTime.minute.toString().padLeft(2, '0')}, ${orderTime.day} ${_getMonth(orderTime.month)} ${orderTime.year}',
                      style: const TextStyle(
                        color: Color(0xFFEEEFEF),
                        fontSize: 12,
                        fontWeight: FontWeight.w300,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // Right part with icons
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: const Color(0xFF222222),
                    child: IconButton(
                      icon: const Icon(Iconsax.call, color: Color(0xFFD0F0C0)),
                      onPressed: onCallPressed,
                    ),
                  ),
                  const SizedBox(width: 10),
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: const Color(0xFF222222),
                    child: IconButton(
                      icon: const Icon(Iconsax.sms, color: Color(0xFFD0F0C0)),
                      onPressed: onWhatsAppPressed,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Scrollable Order Items
          SizedBox(
            height: items.length * 100 > 150 ? 150 : items.length * 100,
            child: ListView.builder(
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
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

          const SizedBox(height: 15),

          // Action Buttons Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Total on the left
              Text(
                'Total: \$${_calculateTotal()}',
                style: const TextStyle(
                  color: Color(0xFFEEEFEF),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              // Spacer to separate Total and Buttons
              const Spacer(),
              // Buttons on the right
              if (isRestaurantSide) ...[
                ElevatedButton(
                  onPressed: onAccept,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD0F0C0),
                    shape: const CircleBorder(),
                    padding: const EdgeInsets.all(8),
                  ),
                  child: const Icon(Iconsax.tick_circle,
                      size: 24, color: Color(0xFF151611)),
                ),
                const SizedBox(width: 5), // Spacing between buttons
                ElevatedButton(
                  onPressed: onCancel,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF151611),
                    shape: const CircleBorder(),
                    padding: const EdgeInsets.all(8),
                  ),
                  child: const Icon(Iconsax.close_circle,
                      size: 24, color: Color(0xFFD0F0C0)),
                ),
              ] else ...[
                ElevatedButton(
                  onPressed: onReorder,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD0F0C0),
                    shape: const CircleBorder(),
                    padding: const EdgeInsets.all(8),
                  ),
                  child: const Icon(Iconsax.repeat,
                      size: 24, color: Color(0xFF151611)),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  double _calculateTotal() {
    double total = 0;
    for (var item in items) {
      total += (item['price'] as num) * (item['quantity'] as num);
    }
    return total + 8 + 4; // Adding GST and platform fee
  }
}

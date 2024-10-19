import 'package:flutter/material.dart';

class OrderDetailWidget extends StatelessWidget {
  final String username;
  final String orderId;
  final String orderTime;
  final List<dynamic> items; // Items list
  final int totalPrice;
  final int userNumber;
  final VoidCallback onCallPressed;
  final VoidCallback onMessagePressed;
  final VoidCallback onCancelPressed;
  final VoidCallback onAcceptPressed;

  const OrderDetailWidget({
    super.key,
    required this.username,
    required this.orderId,
    required this.orderTime,
    required this.items,
    required this.totalPrice,
    required this.userNumber,
    required this.onCallPressed,
    required this.onMessagePressed,
    required this.onCancelPressed,
    required this.onAcceptPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF333333),
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order Details
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  username,
                  style: const TextStyle(color: Colors.white, fontSize: 18),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.phone, color: Colors.greenAccent),
                      onPressed: onCallPressed, // Call user logic
                    ),
                    IconButton(
                      icon:
                          const Icon(Icons.message, color: Colors.greenAccent),
                      onPressed: onMessagePressed, // Message user logic
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 5),
            Text(
              'Order ID: $orderId',
              style: const TextStyle(color: Colors.grey),
            ),
            Text(
              'Order Time: $orderTime',
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 10),

            // List of Items
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                return ListTile(
                  leading: Image.network(
                    item['image_url'],
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                  ),
                  title: Text(item['name'],
                      style: const TextStyle(color: Colors.white)),
                  subtitle: Text(
                    '${item['cooking_time']} min • ${item['rating']} ★',
                    style: const TextStyle(color: Colors.grey),
                  ),
                  trailing: Text('\$${item['price']} x ${item['quantity']}',
                      style: const TextStyle(color: Colors.white)),
                );
              },
            ),

            const SizedBox(height: 10),
            Text(
              'Total: \$$totalPrice',
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
            const SizedBox(height: 10),

            // Accept and Cancel Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  onPressed: onCancelPressed,
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style:
                      ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  onPressed: onAcceptPressed,
                  child: const Text('Accept'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

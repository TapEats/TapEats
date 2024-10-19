import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart'; // For generating UUID if needed

Future<String?> handleCheckout(BuildContext context, Map<String, int> cartItems) async {
  final supabase = Supabase.instance.client;

  try {
    // 1. Fetch current user details (assumes user is logged in and has an id)
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('User is not logged in.');
    }

    final userResponse = await supabase
        .from('users')
        .select('username, phone_number')
        .eq('user_id', userId as Object)
        .single();

    if (userResponse.isEmpty) {
      throw Exception('Error fetching user details.');
    }

    final userName = userResponse['username'];
    final phoneNumber = userResponse['phone_number'];

    // 2. Fetch item details and calculate total price
    double totalPrice = 0.0;
    List<Map<String, dynamic>> orderItems = [];

    for (var entry in cartItems.entries) {
      final response = await supabase
          .from('menu')
          .select('menu_id, name, price, category, rating, cooking_time, image_url')
          .eq('name', entry.key)
          .single();

      if (response.isEmpty) {
        throw Exception('Error fetching menu item.');
      }

      final menuItem = response;
      final quantity = entry.value;
      final price = (menuItem['price'] as num) * quantity;

      // Adding the items to order items list in required format
      orderItems.add({
        "menu_id": menuItem['menu_id'],
        "name": menuItem['name'],
        "price": menuItem['price'],
        "category": menuItem['category'],
        "rating": menuItem['rating'],
        "cooking_time": menuItem['cooking_time'],
        "image_url": menuItem['image_url'],
        "quantity": quantity,
        "status": "Received" // Initial status
      });

      totalPrice += price;
    }

    // 3. Insert the order into the 'orders' table
    final orderId = const Uuid().v4(); // Generating UUID for order ID
    final orderTime = DateTime.now().toUtc().toIso8601String();

    await supabase.from('orders').insert({
      "order_id": orderId,
      "username": userName,
      "user_number": phoneNumber,
      "order_time": orderTime,
      "items": orderItems, // Insert as JSONB
      "total_price": totalPrice,
      "status": "Received" // Initial order status
    });

    // Successfully inserted the order
    if (kDebugMode) {
      print("Order placed successfully!");
    }

    // Return the order ID to use in the cart page
    return orderId;

  } catch (e) {
    if (kDebugMode) {
      print('Checkout failed: $e');
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Checkout failed: $e')),
    );
    return null;
  }
}

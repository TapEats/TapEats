import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

Future<String?> handleCheckout(BuildContext context, Map<String, int> cartItems) async {
  final supabase = Supabase.instance.client;

  try {
    // 1. Fetch current user details
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) {
      if (!context.mounted) return null;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User is not logged in.')),
      );
      return null;
    }

    final userResponse = await supabase
        .from('users')
        .select('username, phone_number')
        .eq('user_id', userId as Object)
        .single();

    if (userResponse.isEmpty) {
      if (!context.mounted) return null;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error fetching user details.')),
      );
      return null;
    }

    final userName = userResponse['username'];
    final phoneNumber = userResponse['phone_number'];

    // 2. Fetch item details and calculate total price
    double totalPrice = 0.0;
    List<Map<String, dynamic>> orderItems = [];

    for (var entry in cartItems.entries) {
      try {
        final response = await supabase
            .from('menu')
            .select('menu_id, name, price, category, rating, cooking_time, image_url')
            .eq('name', entry.key)
            .single();

        if (response.isEmpty) {
          if (!context.mounted) return null;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error fetching menu item: ${entry.key}')),
          );
          return null;
        }

        final menuItem = response;
        final quantity = entry.value;
        final price = (menuItem['price'] as num) * quantity;

        orderItems.add({
          "menu_id": menuItem['menu_id'],
          "name": menuItem['name'],
          "price": menuItem['price'],
          "category": menuItem['category'],
          "rating": menuItem['rating'],
          "cooking_time": menuItem['cooking_time'],
          "image_url": menuItem['image_url'],
          "quantity": quantity,
          "status": "Received"
        });

        totalPrice += price;
      } catch (e) {
        if (!context.mounted) return null;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error processing item ${entry.key}: $e')),
        );
        return null;
      }
    }

    // 3. Insert the order
    final orderId = const Uuid().v4();
    final orderTime = DateTime.now().toUtc().toIso8601String();

    await supabase.from('orders').insert({
      "order_id": orderId,
      "username": userName,
      "user_number": phoneNumber,
      "order_time": orderTime,
      "items": orderItems,
      "total_price": totalPrice,
      "status": "Received"
    });

    if (kDebugMode) {
      print("Order placed successfully!");
    }

    return orderId;

  } catch (e) {
    if (kDebugMode) {
      print('Checkout failed: $e');
    }
    if (!context.mounted) return null;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Checkout failed: $e')),
    );
    return null;
  }
}
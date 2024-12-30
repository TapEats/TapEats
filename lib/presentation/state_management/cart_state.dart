import 'package:flutter/foundation.dart';

class CartState extends ChangeNotifier {
  Map<String, int> cartItems = {};
  int totalItems = 0;

  void addItem(String itemName) {
    if (cartItems.containsKey(itemName)) {
      cartItems[itemName] = cartItems[itemName]! + 1;
    } else {
      cartItems[itemName] = 1;
    }
    totalItems += 1;
    notifyListeners();
  }

  void removeItem(String itemName) {
    if (cartItems.containsKey(itemName) && cartItems[itemName]! > 0) {
      cartItems[itemName] = cartItems[itemName]! - 1;
      totalItems -= 1;
      if (cartItems[itemName] == 0) {
        cartItems.remove(itemName);
      }
      notifyListeners();
    }
  }

  // Call this only after successful checkout
  void resetCartAfterCheckout() {
    cartItems.clear();
    totalItems = 0;
    notifyListeners();
  }
}
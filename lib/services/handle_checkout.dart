import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

// EXACT copy of your working RazorpayService but adapted for orders
class OrderRazorpayService {
  final Razorpay _razorpay = Razorpay();
  final SupabaseClient _supabase = Supabase.instance.client;
  
  // Singleton pattern - EXACT same as your working code
  static final OrderRazorpayService _instance = OrderRazorpayService._internal();
  factory OrderRazorpayService() => _instance;
  OrderRazorpayService._internal();
  
  // Get keys from environment variables - EXACT same as your working code
  String get _keyId => dotenv.env['RAZORPAY_KEY_ID'] ?? '';
  String get _keySecret => dotenv.env['RAZORPAY_KEY_SECRET'] ?? '';
  
  // Success and error callbacks - EXACT same as your working code
  Function(String paymentId, String orderId)? onPaymentSuccess;
  Function(String code, String message)? onPaymentError;
  
  void initialize() {
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }
  
  void dispose() {
    _razorpay.clear();
  }
  
  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    try {
      // Call the success callback if defined - EXACT same as your working code
      if (onPaymentSuccess != null) {
        onPaymentSuccess!(response.paymentId!, response.orderId!);
      }
    } catch (e) {
      print('Error in handlePaymentSuccess: $e');
    }
  }
  
  void _handlePaymentError(PaymentFailureResponse response) {
    try {
      // Call the error callback if defined - EXACT same as your working code
      if (onPaymentError != null) {
        onPaymentError!(response.code.toString(), response.message ?? 'Payment failed');
      }
    } catch (e) {
      print('Error in handlePaymentError: $e');
    }
  }
  
  void _handleExternalWallet(ExternalWalletResponse response) {
    print('External wallet selected: ${response.walletName}');
  }
  
  // Using EXACT same pattern as your processSubscriptionPayment but for orders
  Future<void> processOrderPayment({
    required double amount,
    required String customerName,
    required String customerEmail,
    required String customerPhone,
    required String orderId,
    required BuildContext context,
    required Function(String orderId, String paymentId) onSuccess,
    required Function(String message) onError,
  }) async {
    try {
      // Validate Razorpay keys - EXACT same as your working code
      if (_keyId.isEmpty || _keySecret.isEmpty) {
        throw Exception('Razorpay keys not configured. Please check your .env file.');
      }
      
      // Get user details - EXACT same pattern as your working code
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }
      
      // Get user profile for details - EXACT same as your working code
      final userData = await _supabase
          .from('users')
          .select('username, phone_number, email')
          .eq('user_id', user.id)
          .single();
      
      // Set callbacks - EXACT same pattern as your working code
      onPaymentSuccess = (paymentId, razorpayOrderId) async {
        try {
          print('Order payment success - calling success callback');
          // Call the success callback
          onSuccess(orderId, paymentId);
        } catch (e) {
          print('Error in order payment success: $e');
          onError('Error processing successful payment: $e');
        }
      };
      
      onPaymentError = (code, message) {
        print('Payment error: $code - $message');
        onError(message);
      };
      
      // Generate order ID - EXACT same format as your working code
      final String razorpayOrderId = 'order_${DateTime.now().millisecondsSinceEpoch}';
      
      // Configure payment options - EXACT same structure as your working code
      var options = {
        'key': _keyId,
        'amount': (amount * 100).toString(), // EXACT same format as your working code
        'name': 'TapEats',
        'description': 'Food Order Payment for ${userData['username']}',
        'order_id': razorpayOrderId,
        'prefill': {
          'contact': userData['phone_number'] ?? '',
          'email': userData['email'] ?? user.email,
          'name': userData['username'] ?? 'User',
        },
        'notes': {
          'order_id': orderId,
          'user_id': user.id,
          'customer_name': userData['username'],
          'amount': amount.toString(),
        },
        'theme': {
          'color': '#151611',
        },
      };
      
      // Open Razorpay checkout - EXACT same as your working code
      _razorpay.open(options);
    } catch (e) {
      print('Error processing payment: $e');
      onError('Error processing payment: $e');
    }
  }
}

// Updated checkout function using EXACT same pattern as your subscription flow
Future<String?> handleCheckout(BuildContext context, Map<String, int> cartItems) async {
  final supabase = Supabase.instance.client;
  final paymentService = OrderRazorpayService();

  try {
    print('🛒 Starting checkout process...');

    // Initialize payment service
    paymentService.initialize();

    // 1. Get user details
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('Please log in to continue');
    }

    final userResponse = await supabase
        .from('users')
        .select('username, phone_number, email')
        .eq('user_id', userId)
        .single();

    final userName = (userResponse['username'] ?? '').toString().trim();
    final phoneNumber = (userResponse['phone_number'] ?? '').toString().trim();
    final userEmail = (userResponse['email'] ?? supabase.auth.currentUser?.email ?? '').toString().trim();

    if (userName.isEmpty || phoneNumber.isEmpty || userEmail.isEmpty) {
      throw Exception('Please complete your profile before ordering');
    }

    print('👤 User: $userName ($userEmail, $phoneNumber)');

    // 2. Calculate order total
    double itemTotal = 0.0;
    List<Map<String, dynamic>> orderItems = [];

    for (var entry in cartItems.entries) {
      final response = await supabase
          .from('menu')
          .select('menu_id, name, price, category, rating, cooking_time, image_url')
          .eq('name', entry.key)
          .single();

      if (response.isEmpty) {
        throw Exception('Menu item not found: ${entry.key}');
      }

      final quantity = entry.value;
      final price = (response['price'] as num).toDouble() * quantity;

      orderItems.add({
        "menu_id": response['menu_id'].toString(),
        "name": response['name'].toString(),
        "price": (response['price'] as num).toDouble(),
        "category": response['category'].toString(),
        "rating": (response['rating'] as num?)?.toDouble() ?? 0.0,
        "cooking_time": response['cooking_time'].toString(),
        "image_url": response['image_url'].toString(),
        "quantity": quantity,
        "status": "Received"
      });

      itemTotal += price;
    }

    const double gstCharges = 6.0;
    const double platformFee = 4.0;
    final double totalAmount = itemTotal + gstCharges + platformFee;

    if (totalAmount <= 0) {
      throw Exception('Invalid order amount');
    }

    print('💰 Total: ₹${totalAmount.toStringAsFixed(2)}');

    // 3. Generate order ID
    final orderId = const Uuid().v4();

    // 4. Create a flag to track payment completion
    bool paymentCompleted = false;
    String? resultOrderId;

    // 5. Process payment using EXACT same pattern as your subscription
    await paymentService.processOrderPayment(
      amount: totalAmount,
      customerName: userName,
      customerEmail: userEmail,
      customerPhone: phoneNumber,
      orderId: orderId,
      context: context,
      onSuccess: (orderIdResult, paymentId) async {
        try {
          print('✅ Payment successful! Creating order...');

          // Create order in database
          final orderTime = DateTime.now().toUtc().toIso8601String();
          
          await supabase.from('orders').insert({
            "order_id": orderId,
            "username": userName,
            "user_number": phoneNumber,
            "user_email": userEmail,
            "order_time": orderTime,
            "items": orderItems,
            "item_total": itemTotal,
            "gst_charges": gstCharges,
            "platform_fee": platformFee,
            "total_price": totalAmount,
            "payment_id": paymentId,
            "payment_method": "razorpay",
            "payment_status": "completed",
            "status": "Received"
          });

          // Store payment record
          await supabase.from('payments').insert({
            "payment_id": paymentId,
            "order_id": orderId,
            "user_id": userId,
            "amount": totalAmount,
            "currency": "INR",
            "payment_method": "razorpay",
            "razorpay_payment_id": paymentId,
            "status": "success",
            "created_at": orderTime,
          });

          print('🎉 Order created successfully!');
          print('📝 Order ID: $orderId');
          print('💳 Payment ID: $paymentId');

          paymentCompleted = true;
          resultOrderId = orderId;
        } catch (e) {
          print('💥 Error creating order: $e');
          paymentCompleted = true;
          resultOrderId = null;
        }
      },
      onError: (message) {
        print('❌ Payment failed: $message');
        paymentCompleted = true;
        resultOrderId = null;
      },
    );

    // Wait for payment completion (similar to your subscription pattern)
    int attempts = 0;
    while (!paymentCompleted && attempts < 120) { // 2 minutes timeout
      await Future.delayed(const Duration(seconds: 1));
      attempts++;
    }

    return resultOrderId;

  } catch (e) {
    print('💥 Checkout failed: $e');
    
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Checkout failed: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
    return null;
  }
}

// Initialize and dispose functions
void initializePaymentService() {
  OrderRazorpayService().initialize();
}

void disposePaymentService() {
  OrderRazorpayService().dispose();
}
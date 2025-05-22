import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tapeats/services/subscription_service.dart';

class RazorpayService {
  final Razorpay _razorpay = Razorpay();
  final SupabaseClient _supabase = Supabase.instance.client;
  
  // Singleton pattern
  static final RazorpayService _instance = RazorpayService._internal();
  factory RazorpayService() => _instance;
  RazorpayService._internal();
  
  // Get keys from environment variables
  String get _keyId => dotenv.env['RAZORPAY_KEY_ID'] ?? '';
  String get _keySecret => dotenv.env['RAZORPAY_KEY_SECRET'] ?? '';
  
  // Success and error callbacks
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
      // Call the success callback if defined
      if (onPaymentSuccess != null) {
        onPaymentSuccess!(response.paymentId!, response.orderId!);
      }
    } catch (e) {
      print('Error in handlePaymentSuccess: $e');
    }
  }
  
  void _handlePaymentError(PaymentFailureResponse response) {
    try {
      // Call the error callback if defined
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
  
  Future<void> processSubscriptionPayment({
    required String planId,
    required String restaurantId,
    required BuildContext context,
    required Function(String planId, String paymentId) onSuccess,
    required Function(String message) onError,
  }) async {
    try {
      // Validate Razorpay keys
      if (_keyId.isEmpty || _keySecret.isEmpty) {
        throw Exception('Razorpay keys not configured. Please check your .env file.');
      }
      
      // Get the plan details
      final planDetails = SubscriptionService().getPlanDetails(planId);
      
      // Get user details
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }
      
      // Get user profile for details
      final userData = await _supabase
          .from('users')
          .select('username, phone_number, email')
          .eq('user_id', user.id)
          .single();
      
      // Get restaurant details
      final restaurantData = await _supabase
          .from('restaurants')
          .select('name, branch')
          .eq('restaurant_id', restaurantId)
          .single();
      
      // Set callbacks
      onPaymentSuccess = (paymentId, orderId) async {
        try {
          // Calculate subscription expiry (1 month from now)
          final now = DateTime.now();
          final expiryDate = DateTime(now.year, now.month + 1, now.day);
          
          // Update restaurant subscription in your existing table structure
          await _supabase.from('restaurants').update({
            'subscription_type': planId.toLowerCase(), // Convert 'basic' to match your enum
            'subscription_valid_till': expiryDate.toIso8601String().split('T')[0], // Date only
          }).eq('restaurant_id', restaurantId);
          
          // If you still want to track subscription history, create a subscription_history table
          await _supabase.from('subscription_history').insert({
            'restaurant_id': restaurantId,
            'user_id': user.id,
            'plan_id': planId,
            'payment_id': paymentId,
            'amount': planDetails?['price'],
            'currency': 'INR',
            'payment_method': 'razorpay',
            'status': 'success',
            'subscription_start': now.toIso8601String(),
            'subscription_end': expiryDate.toIso8601String(),
            'created_at': now.toIso8601String(),
          });
          
          // Call the success callback
          onSuccess(planId, paymentId);
        } catch (e) {
          print('Error updating subscription after payment: $e');
          onError('Error updating subscription: $e');
        }
      };
      
      onPaymentError = (code, message) {
        print('Payment error: $code - $message');
        
        // Record failed transaction
        _supabase.from('subscription_history').insert({
          'restaurant_id': restaurantId,
          'user_id': user.id,
          'plan_id': planId,
          'amount': planDetails?['price'],
          'currency': 'INR',
          'payment_id': 'failed_${DateTime.now().millisecondsSinceEpoch}',
          'payment_method': 'razorpay',
          'status': 'failed',
          'error_message': message,
          'created_at': DateTime.now().toIso8601String(),
        });
        
        onError(message);
      };
      
      // Generate order ID
      final String orderId = 'order_${DateTime.now().millisecondsSinceEpoch}';
      
      // Configure payment options
      var options = {
        'key': _keyId,
        'amount': (planDetails?['price'] * 100).toString(), // Amount in paisa
        'name': 'TapEats',
        'description': '${planDetails?['name']} Plan Subscription for ${restaurantData['name']}',
        'order_id': orderId,
        'prefill': {
          'contact': userData['phone_number'] ?? '',
          'email': userData['email'] ?? user.email,
          'name': userData['username'] ?? 'User',
        },
        'notes': {
          'plan_id': planId,
          'user_id': user.id,
          'restaurant_id': restaurantId,
          'restaurant_name': restaurantData['name'],
          'branch': restaurantData['branch'],
        },
        'theme': {
          'color': '#151611',
        },
      };
      
      // Open Razorpay checkout
      _razorpay.open(options);
    } catch (e) {
      print('Error processing payment: $e');
      onError('Error processing payment: $e');
    }
  }
  
  // Get current subscription status for a restaurant
  Future<Map<String, dynamic>?> getRestaurantSubscription(String restaurantId) async {
    try {
      final subscription = await _supabase
          .from('restaurants')
          .select('subscription_type, subscription_valid_till')
          .eq('restaurant_id', restaurantId)
          .single();
      
      if (subscription != null) {
        final validTill = DateTime.parse(subscription['subscription_valid_till']);
        final isActive = validTill.isAfter(DateTime.now());
        
        return {
          'plan_id': subscription['subscription_type'],
          'expiry_date': validTill,
          'is_active': isActive,
          'days_remaining': isActive ? validTill.difference(DateTime.now()).inDays : 0,
        };
      }
      
      return null;
    } catch (e) {
      print('Error getting restaurant subscription: $e');
      return null;
    }
  }
  
  // Generate invoice for subscription payment
  Future<String?> generateInvoice(String paymentId) async {
    try {
      // Get transaction details from subscription_history
      final transaction = await _supabase
          .from('subscription_history')
          .select('''
            *,
            restaurants:restaurant_id(name, branch),
            users:user_id(username, email, phone_number)
          ''')
          .eq('payment_id', paymentId)
          .eq('status', 'success')
          .single();
      
      if (transaction == null) {
        return null;
      }
      
      // Generate invoice number
      final now = DateTime.now();
      final invoiceNumber = 'INV${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}${now.millisecondsSinceEpoch.toString().substring(8)}';
      
      // Create invoice record (you might want to create an invoices table)
      await _supabase.from('invoices').insert({
        'invoice_number': invoiceNumber,
        'payment_id': paymentId,
        'restaurant_id': transaction['restaurant_id'],
        'user_id': transaction['user_id'],
        'plan_id': transaction['plan_id'],
        'amount': transaction['amount'],
        'currency': transaction['currency'],
        'business_name': transaction['restaurants']['name'],
        'branch': transaction['restaurants']['branch'],
        'customer_name': transaction['users']['username'],
        'customer_email': transaction['users']['email'],
        'customer_phone': transaction['users']['phone_number'],
        'created_at': now.toIso8601String(),
      });
      
      return invoiceNumber;
    } catch (e) {
      print('Error generating invoice: $e');
      return null;
    }
  }
}
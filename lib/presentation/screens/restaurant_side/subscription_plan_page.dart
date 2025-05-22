import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tapeats/presentation/widgets/header_widget.dart';
import 'package:tapeats/presentation/widgets/sidemenu_overlay.dart';
import 'package:tapeats/services/notification_service.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class SubscriptionPlansPage extends StatefulWidget {
  const SubscriptionPlansPage({super.key});

  @override
  State<SubscriptionPlansPage> createState() => _SubscriptionPlansPageState();
}

class _SubscriptionPlansPageState extends State<SubscriptionPlansPage> {
  final SupabaseClient _supabase = Supabase.instance.client;
  late Razorpay _razorpay;
  bool _isLoading = false;
  String? _currentPlan;
  DateTime? _expiryDate;
  String? _currentRestaurantId;
  bool _isActive = false;
  
  // Store current subscription attempt details
  Map<String, dynamic>? _currentSubscriptionAttempt;
  
  // Subscription Plan Data
  final List<Map<String, dynamic>> _plans = [
    {
      'id': 'basic',
      'name': 'Basic',
      'price': 999, // ₹999 per month
      'priceDisplay': '₹999',
      'period': 'month',
      'color': Colors.green,
      'features': [
        '100 orders per month',
        'Basic analytics',
        'Menu management',
        'Single restaurant',
        'Email support',
      ],
    },
    {
      'id': 'standard',
      'name': 'Standard',
      'price': 1999, // ₹1,999 per month
      'priceDisplay': '₹1,999',
      'period': 'month',
      'color': Colors.blue,
      'isPopular': true,
      'features': [
        'Unlimited orders',
        'Advanced analytics',
        'Menu management',
        'Table management',
        'Multiple staff accounts',
        'Inventory tracking',
        'Priority email support',
      ],
    },
    {
      'id': 'premium',
      'name': 'Premium',
      'price': 4999, // ₹4,999 per month
      'priceDisplay': '₹4,999',
      'period': 'month',
      'color': Colors.purple,
      'features': [
        'Everything in Standard',
        'Multi-branch support',
        'Custom branding',
        'Advanced inventory management',
        'API access',
        'Dedicated account manager',
        '24/7 phone support',
      ],
    },
  ];

  @override
  void initState() {
    super.initState();
    _initializeRazorpay();
    _loadCurrentSubscription();
  }

  void _initializeRazorpay() {
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  Future<void> _loadCurrentSubscription() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }

      // Get user's restaurant ID first
      final userRestaurant = await _supabase
          .from('restaurants')
          .select('restaurant_id, subscription_type, subscription_valid_till')
          .eq('owner_id', user.id)
          .maybeSingle();

      if (userRestaurant != null) {
        final String restaurantId = userRestaurant['restaurant_id'].toString();
        final String? subscriptionType = userRestaurant['subscription_type'];
        final String? validTillStr = userRestaurant['subscription_valid_till'];

        DateTime? validTill;
        bool isActive = false;

        if (validTillStr != null && validTillStr.isNotEmpty) {
          try {
            // Handle both date-only and datetime formats
            if (validTillStr.contains('T')) {
              validTill = DateTime.parse(validTillStr);
            } else {
              validTill = DateTime.parse('${validTillStr}T23:59:59');
            }
            isActive = validTill.isAfter(DateTime.now());
          } catch (e) {
            print('Error parsing date: $e');
          }
        }

        if (mounted) {
          setState(() {
            _currentRestaurantId = restaurantId;
            _currentPlan = (subscriptionType != null && isActive) ? subscriptionType : null;
            _expiryDate = isActive ? validTill : null;
            _isActive = isActive;
          });
        }

        print('Loaded subscription: $_currentPlan, Active: $isActive, Expiry: $_expiryDate');
      } else {
        print('No restaurant found for user');
        if (mounted) {
          setState(() {
            _currentRestaurantId = null;
            _currentPlan = null;
            _expiryDate = null;
            _isActive = false;
          });
        }
      }
    } catch (e) {
      print('Error loading subscription: $e');
      _showSnackBar('Error loading subscription data: $e', Colors.red);
      if (mounted) {
        setState(() {
          _currentRestaurantId = null;
          _currentPlan = null;
          _expiryDate = null;
          _isActive = false;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _openSideMenu() {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        pageBuilder: (_, __, ___) => const RoleBasedSideMenu(),
      ),
    );
  }

  void _navigateToNotifications() {
    // Implementation for navigation to notifications page
  }

  void _subscribeToPlan(String planId) async {
    if (_currentRestaurantId == null) {
      _showSnackBar('Restaurant not found. Please contact support.', Colors.red);
      return;
    }

    final selectedPlan = _plans.firstWhere((plan) => plan['id'] == planId);
    
    setState(() {
      _isLoading = true;
    });

    try {
      // Validate Razorpay configuration first
      final razorpayKeyId = dotenv.env['RAZORPAY_KEY_ID'];
      print('🔧 Razorpay Key ID: ${razorpayKeyId?.substring(0, 10)}...');
      
      if (razorpayKeyId == null || razorpayKeyId.isEmpty) {
        throw Exception('Razorpay Key ID not configured. Please check your .env file.');
      }

      if (!razorpayKeyId.startsWith('rzp_')) {
        throw Exception('Invalid Razorpay Key ID format. Should start with rzp_');
      }

      // Get user details for prefill
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }

      print('👤 Getting user data...');
      // Get user data with better error handling
      Map<String, dynamic> userData = {
        'username': 'Restaurant Owner',
        'phone_number': '9999999999',
        'email': user.email ?? 'user@tapeats.com',
      };

      try {
        final userResponse = await _supabase
            .from('users')
            .select('username, phone_number, email')
            .eq('user_id', user.id)
            .maybeSingle();
        
        if (userResponse != null) {
          userData = userResponse;
        }
      } catch (e) {
        print('⚠️ Could not fetch user data, using defaults: $e');
      }

      // Store subscription attempt details
      _currentSubscriptionAttempt = {
        'plan_id': planId,
        'plan_name': selectedPlan['name'],
        'amount': selectedPlan['price'],
        'restaurant_id': _currentRestaurantId!,
        'user_id': user.id,
      };

      // Configure payment options with simple, clean structure
      final amountInPaisa = (selectedPlan['price'] as int) * 100;
      
      var options = {
        'key': razorpayKeyId,
        'amount': amountInPaisa,
        'name': 'TapEats',
        'description': '${selectedPlan['name']} Plan',
        'currency': 'INR',
        'prefill': {
          'contact': _cleanPhoneNumber(userData['phone_number']?.toString()),
          'email': userData['email']?.toString() ?? user.email ?? 'user@tapeats.com',
          'name': userData['username']?.toString() ?? 'Restaurant Owner',
        },
        'theme': {
          'color': '#151611',
        },
      };

      print('💳 Payment Configuration:');
      print('   Amount: ₹${selectedPlan['price']} ($amountInPaisa paisa)');
      print('   Plan: ${selectedPlan['name']}');
      
      // Add a small delay to ensure UI is ready
      await Future.delayed(const Duration(milliseconds: 500));
      
      print('🚀 Opening Razorpay checkout...');
      
      // Try to open Razorpay with timeout
      try {
        _razorpay.open(options);
        print('✅ Razorpay checkout opened successfully');
        
        // Set a timeout to reset loading if payment doesn't start
        Future.delayed(const Duration(seconds: 10), () {
          if (mounted && _isLoading) {
            print('⏰ Payment timeout - resetting loading state');
            setState(() {
              _isLoading = false;
            });
            _showSnackBar('Payment interface took too long to load. Please try again.', Colors.orange);
          }
        });
        
      } catch (razorpayError) {
        print('❌ Razorpay open failed: $razorpayError');
        throw Exception('Failed to open payment interface: $razorpayError');
      }
      
    } catch (e) {
      print('❌ Subscription error: $e');
      setState(() {
        _isLoading = false;
      });
      _currentSubscriptionAttempt = null;
      _showSnackBar('Error: $e', Colors.red);
    }
  }

  String _cleanPhoneNumber(String? phone) {
    if (phone == null || phone.isEmpty) return '9999999999';
    
    // Remove all non-digit characters
    String cleaned = phone.replaceAll(RegExp(r'[^\d]'), '');
    
    // If starts with +91, remove it
    if (cleaned.startsWith('91') && cleaned.length > 10) {
      cleaned = cleaned.substring(2);
    }
    
    // Ensure it's 10 digits
    if (cleaned.length != 10) {
      return '9999999999';
    }
    
    return cleaned;
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    print('Payment Success - Payment ID: ${response.paymentId}');
    
    if (_currentSubscriptionAttempt == null) {
      _showSnackBar('Payment successful but subscription data missing. Please contact support.', Colors.orange);
      setState(() {
        _isLoading = false;
      });
      return;
    }
    
    try {
      final planId = _currentSubscriptionAttempt!['plan_id'] as String;
      final amount = _currentSubscriptionAttempt!['amount'] as int;
      final restaurantId = _currentSubscriptionAttempt!['restaurant_id'] as String;
      final userId = _currentSubscriptionAttempt!['user_id'] as String;
      
      // Calculate subscription expiry (1 month from now)
      final now = DateTime.now();
      final expiryDate = DateTime(now.year, now.month + 1, now.day, 23, 59, 59);
      
      print('Updating subscription: Restaurant ID: $restaurantId, Plan: $planId, Expiry: $expiryDate');
      
      // Update restaurant subscription
      await _supabase.from('restaurants').update({
        'subscription_type': planId,
        'subscription_valid_till': expiryDate.toIso8601String(),
        'updated_at': now.toIso8601String(),
      }).eq('restaurant_id', restaurantId);
      
      // Record transaction history
      await _supabase.from('subscription_history').insert({
        'restaurant_id': restaurantId,
        'user_id': userId,
        'plan_id': planId,
        'payment_id': response.paymentId!,
        'amount': amount,
        'currency': 'INR',
        'payment_method': 'razorpay',
        'status': 'success',
        'subscription_start': now.toIso8601String(),
        'subscription_end': expiryDate.toIso8601String(),
        'created_at': now.toIso8601String(),
        'razorpay_signature': response.signature,
      });
      
      // Clear subscription attempt
      _currentSubscriptionAttempt = null;
      
      // Wait a bit for database updates to propagate
      await Future.delayed(const Duration(seconds: 1));
      
      // Refresh subscription data
      await _loadCurrentSubscription();
      
      // Show success message
      _showSnackBar('🎉 Subscription activated successfully!', Colors.green);
      
    } catch (e) {
      print('Error updating subscription after payment: $e');
      _showSnackBar('Payment successful but failed to activate subscription. Payment ID: ${response.paymentId}. Please contact support.', Colors.orange);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    print('💥 Payment Error: Code ${response.code} - ${response.message}');
    
    // Always reset loading state on error
    setState(() {
      _isLoading = false;
    });
    
    // Record failed payment attempt
    if (_currentSubscriptionAttempt != null) {
      _recordFailedPayment(response);
    }
    
    String errorMessage = 'Payment failed';
    switch (response.code) {
      case 0:
        errorMessage = 'Payment was cancelled';
        break;
      case 1:
        errorMessage = 'Payment failed. Please check your payment details and try again.';
        break;
      case 2:
        errorMessage = 'Network error. Please check your internet connection.';
        break;
      case 3:
        errorMessage = 'Payment gateway error. Please try again.';
        break;
      default:
        errorMessage = response.message ?? 'Payment failed. Please try again.';
    }
    
    _showSnackBar(errorMessage, Colors.red);
    
    // Clear subscription attempt
    _currentSubscriptionAttempt = null;
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    print('🏦 External wallet selected: ${response.walletName}');
    // Reset loading state when external wallet is selected
    setState(() {
      _isLoading = false;
    });
    _showSnackBar('Redirecting to ${response.walletName}...', Colors.blue);
  }

  Future<void> _recordFailedPayment(PaymentFailureResponse response) async {
    if (_currentSubscriptionAttempt == null) return;
    
    try {
      await _supabase.from('subscription_history').insert({
        'restaurant_id': _currentSubscriptionAttempt!['restaurant_id'],
        'user_id': _currentSubscriptionAttempt!['user_id'],
        'plan_id': _currentSubscriptionAttempt!['plan_id'],
        'payment_id': 'failed_${DateTime.now().millisecondsSinceEpoch}',
        'amount': _currentSubscriptionAttempt!['amount'],
        'currency': 'INR',
        'payment_method': 'razorpay',
        'status': 'failed',
        'error_message': '${response.code}: ${response.message}',
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Error recording failed payment: $e');
    }
  }


  void _showSnackBar(String message, Color color) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: color,
          duration: const Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final notificationService = Provider.of<NotificationService>(context);
    
    return Scaffold(
      backgroundColor: const Color(0xFF151611),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            HeaderWidget(
              leftIcon: Iconsax.notification,
              onLeftButtonPressed: _navigateToNotifications,
              headingText: "Subscription",
              headingIcon: Iconsax.money,
              rightIcon: Iconsax.menu_1,
              onRightButtonPressed: _openSideMenu,
              notificationCount: notificationService.unreadCount,
            ),
            
            // Loading indicator
            if (_isLoading)
              const LinearProgressIndicator(
                backgroundColor: Color(0xFF222222),
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFD0F0C0)),
              ),
            
            // Subscription content
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadCurrentSubscription,
                color: const Color(0xFFD0F0C0),
                backgroundColor: const Color(0xFF222222),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Text(
                        'Choose Your Plan',
                        style: GoogleFonts.lato(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Select the best plan for your restaurant',
                        style: GoogleFonts.lato(
                          fontSize: 16,
                          color: Colors.grey[400],
                        ),
                      ),
                      
                      // Current subscription info
                      if (_currentPlan != null && _isActive) ...[
                        const SizedBox(height: 20),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF222222),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFFD0F0C0),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Iconsax.tick_circle,
                                    color: Color(0xFFD0F0C0),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Active Subscription',
                                    style: GoogleFonts.lato(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '${_currentPlan![0].toUpperCase()}${_currentPlan!.substring(1)} Plan',
                                    style: GoogleFonts.lato(
                                      fontSize: 16,
                                      color: Colors.white,
                                    ),
                                  ),
                                  if (_expiryDate != null)
                                    Text(
                                      'Expires: ${_expiryDate!.day}/${_expiryDate!.month}/${_expiryDate!.year}',
                                      style: GoogleFonts.lato(
                                        fontSize: 14,
                                        color: Colors.grey[400],
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ] else ...[
                        const SizedBox(height: 20),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF222222),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.orange,
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Iconsax.warning_2,
                                color: Colors.orange,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'No Active Subscription',
                                  style: GoogleFonts.lato(
                                    fontSize: 16,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      
                      const SizedBox(height: 24),
                      
                      // Subscription plans
                      ..._plans.map((plan) => _buildPlanCard(
                        plan: plan,
                        isCurrentPlan: _currentPlan == plan['id'] && _isActive,
                      )),
                      
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildPlanCard({
    required Map<String, dynamic> plan,
    bool isCurrentPlan = false,
  }) {
    final Color planColor = plan['color'] as Color;
    final bool isPopular = plan.containsKey('isPopular') && plan['isPopular'] == true;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCurrentPlan ? const Color(0xFFD0F0C0) : Colors.transparent,
          width: isCurrentPlan ? 2 : 0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            offset: const Offset(0, 4),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        children: [
          // Popular badge
          if (isPopular)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                color: planColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(14),
                  topRight: Radius.circular(14),
                ),
              ),
              child: Text(
                'MOST POPULAR',
                textAlign: TextAlign.center,
                style: GoogleFonts.lato(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Plan name and price
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          plan['name'] as String,
                          style: GoogleFonts.lato(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: planColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'per ${plan['period']}',
                          style: GoogleFonts.lato(
                            fontSize: 14,
                            color: Colors.grey[400],
                          ),
                        ),
                      ],
                    ),
                    Text(
                      plan['priceDisplay'] as String,
                      style: GoogleFonts.lato(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 20),
                const Divider(color: Color(0xFF222222), height: 1),
                const SizedBox(height: 20),
                
                // Features
                ...List.generate(
                  (plan['features'] as List).length,
                  (index) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        const Icon(
                          Iconsax.tick_square,
                          color: Color(0xFFD0F0C0),
                          size: 18,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            plan['features'][index] as String,
                            style: GoogleFonts.lato(
                              fontSize: 14,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Action button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: (isCurrentPlan || _isLoading) 
                        ? null 
                        : () => _subscribeToPlan(plan['id'] as String),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isCurrentPlan ? Colors.grey : const Color(0xFFD0F0C0),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      disabledBackgroundColor: Colors.grey,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                            ),
                          )
                        : Text(
                            isCurrentPlan ? 'Active Plan' : 'Subscribe',
                            style: GoogleFonts.lato(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
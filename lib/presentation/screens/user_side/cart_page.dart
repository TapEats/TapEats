import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tapeats/presentation/screens/user_side/status_page.dart';
import 'package:tapeats/presentation/state_management/cart_state.dart';
import 'package:tapeats/presentation/state_management/slider_state.dart';
import 'package:tapeats/presentation/widgets/header_widget.dart';
import 'package:tapeats/presentation/widgets/sidemenu_overlay.dart';
import 'package:tapeats/presentation/widgets/slider_button.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:uuid/uuid.dart';

class CartPage extends StatefulWidget {
  final Map<String, int> cartItems;
  final int totalItems;

  const CartPage({
    super.key,
    required this.cartItems,
    required this.totalItems,
  });

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  final SupabaseClient supabase = Supabase.instance.client;
  late Razorpay _razorpay;
  
  List<dynamic> detailedCartItems = [];
  double itemTotal = 0.0;
  final double gstCharges = 6.0;
  final double platformFee = 4.0;
  
  bool _isProcessingPayment = false;
  
  // Store current order details for payment processing
  Map<String, dynamic>? _currentOrderAttempt;
  List<Map<String, dynamic>>? _orderItems;

  double get totalAmount => itemTotal + gstCharges + platformFee;

  @override
  void initState() {
    super.initState();
    _initializeRazorpay();
    _fetchCartDetails();
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

  Future<void> _fetchCartDetails() async {
    List<dynamic> items = [];
    double total = 0.0;

    for (var item in widget.cartItems.entries) {
      final response = await supabase
          .from('menu')
          .select('menu_id, name, price, rating, cooking_time, image_url, category')
          .eq('name', item.key)
          .single();

      if (response.isNotEmpty) {
        final price = (response['price'] as num).toDouble();
        final quantity = item.value;
        response['quantity'] = quantity;
        items.add(response);
        total += price * quantity;
      }
    }

    setState(() {
      detailedCartItems = items;
      itemTotal = total;
    });
  }

  void _handleCheckout() async {
    if (_isProcessingPayment) return;
    
    // Validate cart
    if (widget.cartItems.isEmpty) {
      _showSnackBar('Cart is empty', Colors.red);
      return;
    }

    if (totalAmount <= 0) {
      _showSnackBar('Invalid order amount', Colors.red);
      return;
    }

    setState(() {
      _isProcessingPayment = true;
    });

    try {
      // Validate Razorpay configuration
      final razorpayKeyId = dotenv.env['RAZORPAY_KEY_ID'];
      if (razorpayKeyId == null || razorpayKeyId.isEmpty) {
        throw Exception('Razorpay Key ID not configured');
      }

      // Get user details
      final user = supabase.auth.currentUser;
      if (user == null) {
        throw Exception('Please log in to continue');
      }

      // Get user data
      final userData = await supabase
          .from('users')
          .select('username, phone_number, email')
          .eq('user_id', user.id)
          .single();

      final userName = userData['username']?.toString() ?? 'User';
      final phoneNumber = userData['phone_number']?.toString() ?? '9999999999';
      final userEmail = userData['email']?.toString() ?? user.email ?? 'user@tapeats.com';

      // Prepare order items
      _orderItems = [];
      for (var entry in widget.cartItems.entries) {
        final menuItem = detailedCartItems.firstWhere(
          (item) => item['name'] == entry.key,
          orElse: () => null,
        );
        
        if (menuItem != null) {
          _orderItems!.add({
            "menu_id": menuItem['menu_id'].toString(),
            "name": menuItem['name'].toString(),
            "price": (menuItem['price'] as num).toDouble(),
            "category": menuItem['category'].toString(),
            "rating": (menuItem['rating'] as num?)?.toDouble() ?? 0.0,
            "cooking_time": menuItem['cooking_time'].toString(),
            "image_url": menuItem['image_url'].toString(),
            "quantity": entry.value,
            "status": "Received"
          });
        }
      }

      // Generate order ID
      final orderId = const Uuid().v4();

      // Store order attempt details
      _currentOrderAttempt = {
        'order_id': orderId,
        'user_id': user.id,
        'user_name': userName,
        'phone_number': phoneNumber,
        'user_email': userEmail,
        'item_total': itemTotal,
        'total_amount': totalAmount,
      };

      // Configure payment options
      var options = {
        'key': razorpayKeyId,
        'amount': (totalAmount * 100).toInt(), // Amount in paisa
        'name': 'TapEats',
        'description': 'Food Order Payment',
        'prefill': {
          'contact': _cleanPhoneNumber(phoneNumber),
          'email': userEmail,
          'name': userName,
        },
        'theme': {
          'color': '#151611',
        },
      };

      print('Opening Razorpay with amount: ₹$totalAmount');
      
      // Open Razorpay checkout
      _razorpay.open(options);
      
    } catch (e) {
      print('Error in checkout: $e');
      setState(() {
        _isProcessingPayment = false;
      });
      _currentOrderAttempt = null;
      _orderItems = null;
      _showSnackBar('Error: ${e.toString()}', Colors.red);
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
    
    if (_currentOrderAttempt == null || _orderItems == null) {
      _showSnackBar('Payment successful but order data missing. Please contact support.', Colors.orange);
      setState(() {
        _isProcessingPayment = false;
      });
      return;
    }
    
    try {
      final orderId = _currentOrderAttempt!['order_id'];
      final orderTime = DateTime.now().toUtc().toIso8601String();
      
      // Create order in database
      await supabase.from('orders').insert({
        "order_id": orderId,
        "username": _currentOrderAttempt!['user_name'],
        "user_number": _currentOrderAttempt!['phone_number'],
        "user_email": _currentOrderAttempt!['user_email'],
        "order_time": orderTime,
        "items": _orderItems,
        "item_total": _currentOrderAttempt!['item_total'],
        "gst_charges": gstCharges,
        "platform_fee": platformFee,
        "total_price": _currentOrderAttempt!['total_amount'],
        "payment_id": response.paymentId,
        "payment_method": "razorpay",
        "payment_status": "completed",
        "status": "Received"
      });

      // Store payment record
      await supabase.from('payments').insert({
        "payment_id": response.paymentId,
        "order_id": orderId,
        "user_id": _currentOrderAttempt!['user_id'],
        "amount": _currentOrderAttempt!['total_amount'],
        "currency": "INR",
        "payment_method": "razorpay",
        "razorpay_payment_id": response.paymentId,
        "razorpay_signature": response.signature,
        "status": "success",
        "created_at": orderTime,
      });

      print('Order created successfully! Order ID: $orderId');

      // Clear cart and navigate
      if (mounted) {
        Provider.of<CartState>(context, listen: false).resetCartAfterCheckout();
        Provider.of<SliderState>(context, listen: false).resetAllSliders();
        
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => StatusPage(orderId: orderId),
          ),
        );
      }
      
    } catch (e) {
      print('Error creating order: $e');
      _showSnackBar('Payment successful but failed to create order. Payment ID: ${response.paymentId}', Colors.orange);
    } finally {
      setState(() {
        _isProcessingPayment = false;
      });
      _currentOrderAttempt = null;
      _orderItems = null;
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    print('Payment Error: Code ${response.code} - ${response.message}');
    
    setState(() {
      _isProcessingPayment = false;
    });
    
    String errorMessage = 'Payment failed';
    switch (response.code) {
      case Razorpay.PAYMENT_CANCELLED:
        errorMessage = 'Payment was cancelled';
        break;
      case Razorpay.NETWORK_ERROR:
        errorMessage = 'Network error. Please check your internet connection.';
        break;
      default:
        errorMessage = response.message ?? 'Payment failed. Please try again.';
    }
    
    _showSnackBar(errorMessage, Colors.red);
    
    _currentOrderAttempt = null;
    _orderItems = null;
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    print('External wallet selected: ${response.walletName}');
    _showSnackBar('Redirecting to ${response.walletName}...', Colors.blue);
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

  void _openSideMenu() {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        pageBuilder: (_, __, ___) => const RoleBasedSideMenu(),
      ),
    );
  }

  void _removeItemFromCart(String itemName) {
    final cartState = Provider.of<CartState>(context, listen: false);
    cartState.removeItem(itemName);
    _fetchCartDetails();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: const Color(0xFF151611),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch, 
          children: [
            HeaderWidget(
              leftIcon: Iconsax.arrow_left_1,
              onLeftButtonPressed: () { 
                if (_isProcessingPayment) {
                  _showSnackBar('Please wait for payment to complete', Colors.orange);
                  return;
                }
                
                Provider.of<SliderState>(context, listen: false).resetSliderPosition('cart_checkout');
                Provider.of<SliderState>(context, listen: false).resetSliderPosition('home_cart');
                Navigator.pop(context);
              },
              headingText: 'Cart',
              headingIcon: Iconsax.book_saved,
              rightIcon: Iconsax.menu_1,
              onRightButtonPressed: _openSideMenu,
            ),

            // Loading indicator
            if (_isProcessingPayment)
              const LinearProgressIndicator(
                backgroundColor: Color(0xFF222222),
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFD0F0C0)),
              ),

            const SizedBox(height: 20),
            
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                itemCount: detailedCartItems.length,
                itemBuilder: (context, index) {
                  final item = detailedCartItems[index];
                  return _buildCartItem(
                    item['name'],
                    item['cooking_time'],
                    item['rating'],
                    item['quantity'],
                    (item['price'] as num).toDouble(),
                    item['image_url'],
                  );
                },
              ),
            ),
            
            const SizedBox(height: 20),
            _buildPromoCodeSection(),
            const SizedBox(height: 20),
            _buildPriceSummary(),
            const SizedBox(height: 20),
            
            Consumer<SliderState>(
              builder: (context, sliderState, child) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: SliderButton(
                    labelText: _isProcessingPayment ? 'Processing...' : 'Pay Now',
                    subText: '₹${totalAmount.toStringAsFixed(2)}',
                    onSlideComplete: _isProcessingPayment ? () {} : _handleCheckout,
                    pageId: 'cart_checkout',
                    width: screenWidth * 0.8,
                    height: screenHeight * 0.07,
                  ),
                );
              },
            ),
            
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildCartItem(
    String itemName,
    String cookingTime,
    double rating,
    int quantity,
    double pricePerItem,
    String imageUrl,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.network(
              imageUrl,
              width: 80,
              height: 80,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 80,
                  height: 80,
                  color: const Color(0xFF222222),
                  child: const Icon(
                    Iconsax.image,
                    color: Color(0xFF8F8F8F),
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        itemName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontFamily: 'Helvetica Neue',
                          color: Color(0xFFEEEFEF),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Iconsax.trash, color: Color(0xFFD0F0C0)),
                      onPressed: _isProcessingPayment ? null : () {
                        _removeItemFromCart(itemName);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                
                Row(
                  children: [
                    Text(
                      '$cookingTime • ',
                      style: const TextStyle(
                        fontSize: 14,
                        fontFamily: 'Helvetica Neue',
                        color: Color(0xFF8F8F8F),
                      ),
                    ),
                    const Icon(Iconsax.star, size: 16, color: Color(0xFFEEEFEF)),
                    const SizedBox(width: 5),
                    Text(
                      rating.toString(),
                      style: const TextStyle(
                        fontSize: 14,
                        fontFamily: 'Helvetica Neue',
                        color: Color(0xFF8F8F8F),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  '₹${(pricePerItem * quantity).toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontFamily: 'Helvetica Neue',
                    color: Color(0xFFD0F0C0),
                  ),
                ),
              ],
            ),
          ),
          Column(
            children: [
              Text(
                'x$quantity',
                style: const TextStyle(
                  fontSize: 16,
                  fontFamily: 'Helvetica Neue',
                  color: Color(0xFFD0F0C0),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPromoCodeSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Row(
          children: [
            const Expanded(
              child: TextField(
                style: TextStyle(color: Color(0xFFEEEFEF)),
                decoration: InputDecoration(
                  hintText: 'Promo Code',
                  hintStyle: TextStyle(color: Color(0xFF8F8F8F)),
                  border: InputBorder.none,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: _isProcessingPayment ? null : () {
                // Handle promo code
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD0F0C0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Apply',
                style: TextStyle(
                  color: Color(0xFF1A1A1A),
                  fontFamily: 'Helvetica Neue',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceSummary() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          children: [
            _buildPriceRow('Item total', '₹${itemTotal.toStringAsFixed(2)}'),
            _buildPriceRow('GST and restaurant charges', '₹${gstCharges.toStringAsFixed(2)}'),
            _buildPriceRow('Platform fee', '₹${platformFee.toStringAsFixed(2)}'),
            const Divider(color: Color(0xFF8F8F8F)),
            _buildPriceRow('Total', '₹${totalAmount.toStringAsFixed(2)}', isTotal: true),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceRow(String label, String amount, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 18 : 16,
              fontFamily: 'Helvetica Neue',
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: const Color(0xFFEEEFEF),
            ),
          ),
          Text(
            amount,
            style: TextStyle(
              fontSize: isTotal ? 18 : 16,
              fontFamily: 'Helvetica Neue',
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: const Color(0xFFEEEFEF),
            ),
          ),
        ],
      ),
    );
  }
}
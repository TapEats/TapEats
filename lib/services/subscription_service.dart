import 'package:supabase_flutter/supabase_flutter.dart';

class SubscriptionService {
  final SupabaseClient _supabase = Supabase.instance.client;
  
  // Singleton pattern
  static final SubscriptionService _instance = SubscriptionService._internal();
  factory SubscriptionService() => _instance;
  SubscriptionService._internal();
  
  // Plan definitions
  static const Map<String, Map<String, dynamic>> _planDefinitions = {
    'basic': {
      'name': 'Basic',
      'price': 999,
      'priceDisplay': '₹999',
      'features': [
        '100 orders per month',
        'Basic analytics',
        'Menu management',
        'Single restaurant',
        'Email support',
      ],
    },
    'standard': {
      'name': 'Standard',
      'price': 1999,
      'priceDisplay': '₹1,999',
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
    'premium': {
      'name': 'Premium',
      'price': 4999,
      'priceDisplay': '₹4,999',
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
  };
  
  // Get plan details by ID
  Map<String, dynamic>? getPlanDetails(String planId) {
    return _planDefinitions[planId];
  }
  
  // Get all plans
  List<Map<String, dynamic>> getAllPlans() {
    return _planDefinitions.entries.map((entry) {
      return {
        'id': entry.key,
        ...entry.value,
      };
    }).toList();
  }
  
  // Get restaurant ID for current user
  Future<String?> getRestaurantIdForUser(String userId) async {
    try {
      final result = await _supabase
          .from('restaurants')
          .select('restaurant_id')
          .eq('owner_id', userId)
          .maybeSingle();
      
      return result?['restaurant_id']?.toString();
    } catch (e) {
      print('Error getting restaurant ID: $e');
      return null;
    }
  }
  
  // Get current subscription for a restaurant
  Future<Map<String, dynamic>?> getCurrentSubscription(String restaurantId) async {
    try {
      print('🔍 Getting subscription for restaurant: $restaurantId');
      
      // Direct query instead of stored procedure
      final result = await _supabase
          .from('restaurants')
          .select('subscription_type, subscription_valid_till')
          .eq('restaurant_id', restaurantId)
          .maybeSingle();
      
      print('📊 Raw restaurant data: $result');
      
      if (result == null) {
        print('❌ No restaurant found with ID: $restaurantId');
        return null;
      }
      
      final subscriptionType = result['subscription_type'] as String?;
      final validTillStr = result['subscription_valid_till'] as String?;
      
      print('📅 Subscription type: $subscriptionType');
      print('📅 Valid till string: $validTillStr');
      
      // Parse the expiry date
      DateTime? expiryDate;
      bool isActive = false;
      int daysRemaining = 0;
      
      if (validTillStr != null && validTillStr.isNotEmpty) {
        try {
          // Handle both date-only and datetime formats
          if (validTillStr.contains('T')) {
            expiryDate = DateTime.parse(validTillStr);
          } else {
            // Assume date-only format, set to end of day
            expiryDate = DateTime.parse('${validTillStr}T23:59:59');
          }
          
          final now = DateTime.now();
          isActive = expiryDate.isAfter(now);
          daysRemaining = isActive ? expiryDate.difference(now).inDays : 0;
          
          print('📅 Parsed expiry date: $expiryDate');
          print('⏰ Current time: $now');
          print('✅ Is active: $isActive');
          print('📊 Days remaining: $daysRemaining');
          
        } catch (e) {
          print('❌ Error parsing date: $e');
          expiryDate = null;
          isActive = false;
          daysRemaining = 0;
        }
      }
      
      // Only return subscription data if we have a valid subscription type and it's active
      if (subscriptionType != null && subscriptionType.isNotEmpty && isActive) {
        final subscriptionData = {
          'plan_id': subscriptionType,
          'is_active': isActive,
          'expiry_date': expiryDate,
          'days_remaining': daysRemaining,
        };
        
        print('🎉 Active subscription found: $subscriptionData');
        return subscriptionData;
      } else {
        print('⚠️ No active subscription - Type: $subscriptionType, Active: $isActive');
        return null;
      }
      
    } catch (e) {
      print('❌ Error getting subscription status: $e');
      return null;
    }
  }
  
  // Get subscription details (alias for getCurrentSubscription for backward compatibility)
  Future<Map<String, dynamic>?> getSubscriptionDetails(String restaurantId) async {
    return getCurrentSubscription(restaurantId);
  }
  
  // Update subscription after successful payment
  Future<bool> updateSubscription({
    required String restaurantId,
    required String userId,
    required String planId,
    required String paymentId,
    String? orderId,
  }) async {
    try {
      final planDetails = getPlanDetails(planId);
      if (planDetails == null) {
        throw Exception('Invalid plan ID: $planId');
      }
      
      // Calculate subscription expiry (1 month from now)
      final now = DateTime.now();
      final expiryDate = DateTime(now.year, now.month + 1, now.day, 23, 59, 59);
      
      print('🔄 Updating subscription:');
      print('   Restaurant ID: $restaurantId');
      print('   Plan ID: $planId');
      print('   Expiry Date: $expiryDate');
      
      // Direct update instead of stored procedure
      await _supabase.from('restaurants').update({
        'subscription_type': planId,
        'subscription_valid_till': expiryDate.toIso8601String(),
        'updated_at': now.toIso8601String(),
      }).eq('restaurant_id', restaurantId);
      
      // Record subscription history (with error handling)
      try {
        await _supabase.from('subscription_history').insert({
          'restaurant_id': restaurantId,
          'user_id': userId,
          'plan_id': planId,
          'payment_id': paymentId,
          'order_id': orderId,
          'amount': planDetails['price'],
          'currency': 'INR',
          'payment_method': 'razorpay',
          'status': 'success',
          'subscription_start': now.toIso8601String(),
          'subscription_end': expiryDate.toIso8601String(),
          'created_at': now.toIso8601String(),
        });
      } catch (historyError) {
        print('⚠️ Could not record subscription history: $historyError');
        // Don't fail the entire operation if history recording fails
      }
      
      print('✅ Subscription updated successfully');
      return true;
    } catch (e) {
      print('❌ Error updating subscription: $e');
      return false;
    }
  }
  
  // Record failed payment
  Future<void> recordFailedPayment({
    required String restaurantId,
    required String userId,
    required String planId,
    required String errorMessage,
    String? orderId,
  }) async {
    try {
      final planDetails = getPlanDetails(planId);
      if (planDetails == null) return;
      
      await _supabase.from('subscription_history').insert({
        'restaurant_id': restaurantId,
        'user_id': userId,
        'plan_id': planId,
        'payment_id': 'failed_${DateTime.now().millisecondsSinceEpoch}',
        'order_id': orderId,
        'amount': planDetails['price'],
        'currency': 'INR',
        'payment_method': 'razorpay',
        'status': 'failed',
        'error_message': errorMessage,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Error recording failed payment: $e');
    }
  }
  
  // Get subscription history for a restaurant
  Future<List<Map<String, dynamic>>> getSubscriptionHistory(String restaurantId) async {
    try {
      final result = await _supabase
          .from('subscription_history')
          .select('*')
          .eq('restaurant_id', restaurantId)
          .order('created_at', ascending: false);
      
      return List<Map<String, dynamic>>.from(result);
    } catch (e) {
      print('Error getting subscription history: $e');
      return [];
    }
  }
  
  // Check feature access based on subscription
  Future<bool> hasFeatureAccess(String restaurantId, String feature) async {
    try {
      final subscription = await getCurrentSubscription(restaurantId);
      if (subscription == null || !(subscription['is_active'] as bool)) {
        return false; // No access if no active subscription
      }
      
      final planId = subscription['plan_id'] as String?;
      return hasFeatureAccessSync(planId, feature);
    } catch (e) {
      print('Error checking feature access: $e');
      return false;
    }
  }
  
  // Synchronous version for immediate checks (requires planId)
  bool hasFeatureAccessSync(String? planId, String feature) {
    if (planId == null) return false;
    
    final planDetails = getPlanDetails(planId);
    if (planDetails == null) return false;
    
    // Define feature mappings
    switch (feature) {
      case 'unlimited_orders':
        return planId == 'standard' || planId == 'premium';
      case 'advanced_analytics':
        return planId == 'standard' || planId == 'premium';
      case 'table_management':
        return planId == 'standard' || planId == 'premium';
      case 'multiple_staff':
        return planId == 'standard' || planId == 'premium';
      case 'inventory_tracking':
        return planId == 'standard' || planId == 'premium';
      case 'multi_branch':
        return planId == 'premium';
      case 'custom_branding':
        return planId == 'premium';
      case 'api_access':
        return planId == 'premium';
      default:
        return true; // Basic features available to all active subscriptions
    }
  }
  
  // Check if subscription is expiring soon
  Future<bool> isSubscriptionExpiringSoon(String restaurantId, {int warningDays = 7}) async {
    try {
      final subscription = await getCurrentSubscription(restaurantId);
      if (subscription == null || !(subscription['is_active'] as bool)) {
        return false;
      }
      
      final expiryDate = subscription['expiry_date'] as DateTime?;
      if (expiryDate == null) return false;
      
      final daysRemaining = daysUntilExpiry(expiryDate);
      return daysRemaining <= warningDays && daysRemaining > 0;
    } catch (e) {
      print('Error checking if subscription is expiring soon: $e');
      return false;
    }
  }
  
  // Calculate days until expiry
  int daysUntilExpiry(DateTime? expiryDate) {
    if (expiryDate == null) return 0;
    final now = DateTime.now();
    if (expiryDate.isBefore(now)) return 0;
    return expiryDate.difference(now).inDays;
  }
  
  // Check if subscription is active
  bool isSubscriptionActive(DateTime? expiryDate) {
    if (expiryDate == null) return false;
    return expiryDate.isAfter(DateTime.now());
  }
  
  // Generate subscription summary for display
  Map<String, dynamic> getSubscriptionSummary(String? planId, DateTime? expiryDate) {
    final isActive = isSubscriptionActive(expiryDate);
    final daysRemaining = daysUntilExpiry(expiryDate);
    final planDetails = planId != null ? getPlanDetails(planId) : null;
    
    return {
      'has_subscription': isActive,
      'plan_id': planId,
      'plan_name': planDetails?['name'] ?? 'No Plan',
      'plan_price': planDetails?['priceDisplay'] ?? '₹0',
      'is_active': isActive,
      'expiry_date': expiryDate,
      'days_remaining': daysRemaining,
      'status': isActive 
        ? (daysRemaining <= 7 ? 'expiring_soon' : 'active')
        : 'expired',
    };
  }
}
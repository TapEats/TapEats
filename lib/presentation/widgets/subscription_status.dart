import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tapeats/services/subscription_service.dart';

class SubscriptionStatusWidget extends StatefulWidget {
  final bool showExpanded;
  final VoidCallback? onTap;
  
  const SubscriptionStatusWidget({
    super.key,
    this.showExpanded = false,
    this.onTap,
  });

  @override
  State<SubscriptionStatusWidget> createState() => _SubscriptionStatusWidgetState();
}

class _SubscriptionStatusWidgetState extends State<SubscriptionStatusWidget> {
  final SupabaseClient _supabase = Supabase.instance.client;
  final SubscriptionService _subscriptionService = SubscriptionService();
  
  Map<String, dynamic>? _subscriptionSummary;
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _loadSubscriptionStatus();
  }
  
  Future<void> _loadSubscriptionStatus() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;
      
      final restaurantId = await _subscriptionService.getRestaurantIdForUser(user.id);
      if (restaurantId == null) {
        setState(() {
          _subscriptionSummary = _subscriptionService.getSubscriptionSummary(null, null);
        });
        return;
      }
      
      final subscription = await _subscriptionService.getCurrentSubscription(restaurantId);
      
      setState(() {
        _subscriptionSummary = _subscriptionService.getSubscriptionSummary(
          subscription?['plan_id'],
          subscription?['expiry_date'],
        );
      });
    } catch (e) {
      print('Error loading subscription status: $e');
      setState(() {
        _subscriptionSummary = _subscriptionService.getSubscriptionSummary(null, null);
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF222222),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFD0F0C0)),
              ),
            ),
            SizedBox(width: 12),
            Text(
              'Loading subscription...',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
      );
    }
    
    if (_subscriptionSummary == null) {
      return const SizedBox.shrink();
    }
    
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF222222),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _getBorderColor(),
            width: 1,
          ),
        ),
        child: widget.showExpanded ? _buildExpandedView() : _buildCompactView(),
      ),
    );
  }
  
  Color _getBorderColor() {
    final status = _subscriptionSummary!['status'] as String;
    switch (status) {
      case 'active':
        return const Color(0xFFD0F0C0);
      case 'expiring_soon':
        return Colors.orange;
      case 'expired':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
  
  IconData _getStatusIcon() {
    final status = _subscriptionSummary!['status'] as String;
    switch (status) {
      case 'active':
        return Iconsax.tick_circle;
      case 'expiring_soon':
        return Iconsax.warning_2;
      case 'expired':
        return Iconsax.close_circle;
      default:
        return Iconsax.info_circle;
    }
  }
  
  Color _getStatusColor() {
    final status = _subscriptionSummary!['status'] as String;
    switch (status) {
      case 'active':
        return const Color(0xFFD0F0C0);
      case 'expiring_soon':
        return Colors.orange;
      case 'expired':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
  
  String _getStatusText() {
    final status = _subscriptionSummary!['status'] as String;
    final hasSubscription = _subscriptionSummary!['has_subscription'] as bool;
    
    if (!hasSubscription) {
      return 'No Active Plan';
    }
    
    switch (status) {
      case 'active':
        return '${_subscriptionSummary!['plan_name']} Plan';
      case 'expiring_soon':
        final daysRemaining = _subscriptionSummary!['days_remaining'] as int;
        return '${_subscriptionSummary!['plan_name']} Plan (${daysRemaining}d left)';
      case 'expired':
        return 'Plan Expired';
      default:
        return 'Unknown Status';
    }
  }
  
  Widget _buildCompactView() {
    return Row(
      children: [
        Icon(
          _getStatusIcon(),
          color: _getStatusColor(),
          size: 20,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            _getStatusText(),
            style: GoogleFonts.lato(
              fontSize: 14,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        if (_subscriptionSummary!['has_subscription'] as bool) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _getStatusColor().withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _subscriptionSummary!['plan_price'] as String,
              style: GoogleFonts.lato(
                fontSize: 12,
                color: _getStatusColor(),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ] else ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFD0F0C0),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Subscribe',
              style: GoogleFonts.lato(
                fontSize: 12,
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
        if (widget.onTap != null) ...[
          const SizedBox(width: 8),
          Icon(
            Iconsax.arrow_right_3,
            color: Colors.grey[400],
            size: 16,
          ),
        ],
      ],
    );
  }
  
  Widget _buildExpandedView() {
    final hasSubscription = _subscriptionSummary!['has_subscription'] as bool;
    final expiryDate = _subscriptionSummary!['expiry_date'] as DateTime?;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              _getStatusIcon(),
              color: _getStatusColor(),
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                hasSubscription ? 'Your Subscription' : 'Subscription Required',
                style: GoogleFonts.lato(
                  fontSize: 18,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        
        if (hasSubscription) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _subscriptionSummary!['plan_name'] as String,
                style: GoogleFonts.lato(
                  fontSize: 16,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                _subscriptionSummary!['plan_price'] as String,
                style: GoogleFonts.lato(
                  fontSize: 16,
                  color: _getStatusColor(),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          
          if (expiryDate != null) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Expires on',
                  style: GoogleFonts.lato(
                    fontSize: 14,
                    color: Colors.grey[400],
                  ),
                ),
                Text(
                  '${expiryDate.day}/${expiryDate.month}/${expiryDate.year}',
                  style: GoogleFonts.lato(
                    fontSize: 14,
                    color: Colors.grey[400],
                  ),
                ),
              ],
            ),
          ],
          
          // Progress bar for days remaining
          if (_subscriptionSummary!['days_remaining'] as int > 0) ...[
            const SizedBox(height: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Days remaining',
                      style: GoogleFonts.lato(
                        fontSize: 12,
                        color: Colors.grey[400],
                      ),
                    ),
                    Text(
                      '${_subscriptionSummary!['days_remaining']} days',
                      style: GoogleFonts.lato(
                        fontSize: 12,
                        color: _getStatusColor(),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (_subscriptionSummary!['days_remaining'] as int) / 30.0,
                    minHeight: 6,
                    backgroundColor: Colors.grey[700],
                    valueColor: AlwaysStoppedAnimation<Color>(_getStatusColor()),
                  ),
                ),
              ],
            ),
          ],
        ] else ...[
          Text(
            'Subscribe to a plan to unlock all features and start accepting orders.',
            style: GoogleFonts.lato(
              fontSize: 14,
              color: Colors.grey[400],
            ),
          ),
        ],
        
        if (widget.onTap != null) ...[
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: widget.onTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD0F0C0),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                hasSubscription ? 'Manage Subscription' : 'Choose Plan',
                style: GoogleFonts.lato(
                  fontSize: 14,
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
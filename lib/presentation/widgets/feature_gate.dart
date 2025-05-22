import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tapeats/services/subscription_service.dart';

class FeatureGate extends StatelessWidget {
  final String feature;
  final Widget child;
  final Widget? fallback;
  final VoidCallback? onUpgrade;
  
  const FeatureGate({
    super.key,
    required this.feature,
    required this.child,
    this.fallback,
    this.onUpgrade,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _checkFeatureAccess(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              color: Color(0xFFD0F0C0),
            ),
          );
        }
        
        final hasAccess = snapshot.data ?? false;
        
        if (hasAccess) {
          return child;
        }
        
        return fallback ?? _buildUpgradePrompt(context);
      },
    );
  }
  
  Future<bool> _checkFeatureAccess() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return false;
      
      final subscriptionService = SubscriptionService();
      final restaurantId = await subscriptionService.getRestaurantIdForUser(user.id);
      if (restaurantId == null) return false;
      
      return await subscriptionService.hasFeatureAccess(restaurantId, feature);
    } catch (e) {
      print('Error checking feature access: $e');
      return false;
    }
  }
  
  Widget _buildUpgradePrompt(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF222222),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              Iconsax.lock,
              color: Colors.orange,
              size: 48,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Premium Feature',
            style: GoogleFonts.lato(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'This feature requires a premium subscription plan.',
            style: GoogleFonts.lato(
              fontSize: 16,
              color: Colors.grey[400],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: onUpgrade ?? () {
              Navigator.pushNamed(context, '/subscription');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD0F0C0),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Upgrade to Premium',
              style: GoogleFonts.lato(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Simplified version for quick checks
class SimpleFeatureGate extends StatefulWidget {
  final String feature;
  final Widget child;
  final Widget? fallback;
  
  const SimpleFeatureGate({
    super.key,
    required this.feature,
    required this.child,
    this.fallback,
  });

  @override
  State<SimpleFeatureGate> createState() => _SimpleFeatureGateState();
}

class _SimpleFeatureGateState extends State<SimpleFeatureGate> {
  bool _hasAccess = false;
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _checkAccess();
  }
  
  Future<void> _checkAccess() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        setState(() {
          _hasAccess = false;
          _isLoading = false;
        });
        return;
      }
      
      final subscriptionService = SubscriptionService();
      final restaurantId = await subscriptionService.getRestaurantIdForUser(user.id);
      if (restaurantId == null) {
        setState(() {
          _hasAccess = false;
          _isLoading = false;
        });
        return;
      }
      
      final hasAccess = await subscriptionService.hasFeatureAccess(restaurantId, widget.feature);
      setState(() {
        _hasAccess = hasAccess;
        _isLoading = false;
      });
    } catch (e) {
      print('Error checking feature access: $e');
      setState(() {
        _hasAccess = false;
        _isLoading = false;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFFD0F0C0),
        ),
      );
    }
    
    if (_hasAccess) {
      return widget.child;
    }
    
    return widget.fallback ?? const SizedBox.shrink();
  }
}
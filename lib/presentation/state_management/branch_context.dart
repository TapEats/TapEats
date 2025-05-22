import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class BranchContext extends ChangeNotifier {
  String? _selectedBranchId;
  Map<String, dynamic>? _selectedBranchData;
  final List<Map<String, dynamic>> _branches = [];
  
  String? get selectedBranchId => _selectedBranchId;
  Map<String, dynamic>? get selectedBranchData => _selectedBranchData;
  List<Map<String, dynamic>> get branches => _branches;
  
  Future<void> loadBranches() async {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;
    
    if (user != null) {
      try {
        // Get restaurant ID
        final restaurantData = await supabase
            .from('restaurants')
            .select('id')
            .eq('owner_id', user.id)
            .maybeSingle();
            
        if (restaurantData != null) {
          final mainRestaurantId = restaurantData['id'];
          
          // Get branches
          final branchesData = await supabase
              .from('restaurant_branches')
              .select('*')
              .eq('main_restaurant_id', mainRestaurantId)
              .order('created_at', ascending: false);
          
          _branches.clear();
          _branches.addAll(List<Map<String, dynamic>>.from(branchesData));
          
          // Set default branch if none selected
          if (_selectedBranchId == null && _branches.isNotEmpty) {
            selectBranch(_branches[0]['id']);
          }
          
          notifyListeners();
        }
      } catch (e) {
        print('Error loading branches: $e');
      }
    }
  }
  
  void selectBranch(String branchId) {
    _selectedBranchId = branchId;
    _selectedBranchData = _branches.firstWhere(
      (branch) => branch['id'] == branchId,
      orElse: () => {},
    );
    notifyListeners();
  }
  
  // Add method to create a new branch
  Future<void> createBranch({
    required String name,
    required String address,
    required String phone,
  }) async {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;
    
    if (user != null) {
      try {
        // Get restaurant ID
        final restaurantData = await supabase
            .from('restaurants')
            .select('id')
            .eq('owner_id', user.id)
            .maybeSingle();
            
        if (restaurantData != null) {
          final mainRestaurantId = restaurantData['id'];
          
          // Create branch
          await supabase.from('restaurant_branches').insert({
            'main_restaurant_id': mainRestaurantId,
            'name': name,
            'address': address,
            'phone': phone,
            'status': 'active',
          });
          
          // Reload branches
          await loadBranches();
        }
      } catch (e) {
        print('Error creating branch: $e');
        rethrow;
      }
    }
  }
}
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FavoritesState extends ChangeNotifier {
  final SupabaseClient supabase = Supabase.instance.client;
  
  // Set to store favorite menu IDs
  final Set<int> _favoriteMenuIds = {};
  bool _isLoading = false;
  
  // Getters
  Set<int> get favoriteMenuIds => _favoriteMenuIds;
  bool get isLoading => _isLoading;
  
  // Check if an item is favorited
  bool isFavorite(int menuId) {
    return _favoriteMenuIds.contains(menuId);
  }
  
  // Initialize favorites data from Supabase
  Future<void> initializeFavorites() async {
    if (_isLoading) return;
    
    try {
      _isLoading = true;
      
      // Get current user
      final user = supabase.auth.currentUser;
      if (user == null) {
        _isLoading = false;
        return;
      }
      
      // Fetch favorites from Supabase
      final response = await supabase
          .from('favorite_foods')
          .select('menu_id')
          .eq('user_id', user.id);
      
      // Clear existing favorites
      _favoriteMenuIds.clear();
      
      // Add fetched items to the local set
      if (response.isNotEmpty) {
        for (var record in response) {
          if (record['menu_id'] != null) {
            _favoriteMenuIds.add(record['menu_id']);
          }
        }
      }
      
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching favorites: $e');
      }
    } finally {
      _isLoading = false;
    }
  }
  
  // Toggle favorite status of an item
  Future<void> toggleFavorite(int menuId) async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;
      
      if (_favoriteMenuIds.contains(menuId)) {
        // Remove from local state first for instant UI feedback
        _favoriteMenuIds.remove(menuId);
        notifyListeners();
        
        // Then remove from database
        await supabase
            .from('favorite_foods')
            .delete()
            .match({
              'user_id': user.id,
              'menu_id': menuId
            });
      } else {
        // Add to local state first for instant UI feedback
        _favoriteMenuIds.add(menuId);
        notifyListeners();
        
        // Then add to database
        await supabase.from('favorite_foods').insert({
          'user_id': user.id,
          'menu_id': menuId,
        });
      }
    } catch (e) {
      // Revert local state if operation failed
      if (_favoriteMenuIds.contains(menuId)) {
        _favoriteMenuIds.remove(menuId);
      } else {
        _favoriteMenuIds.add(menuId);
      }
      
      if (kDebugMode) {
        print('Error toggling favorite: $e');
      }
      
      notifyListeners();
    }
  }
}
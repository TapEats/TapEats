import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tapeats/presentation/screens/rest_edit_add_menu.dart';
import 'package:tapeats/presentation/widgets/custom_footer_five_button_widget.dart';

class MenuManagementScreen extends StatefulWidget {
  final int selectedIndex;

  const MenuManagementScreen({
    super.key,
    required this.selectedIndex,
  });

  @override
  State<MenuManagementScreen> createState() => _MenuManagementScreenState();
}

class _MenuManagementScreenState extends State<MenuManagementScreen> {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> menuItems = [];
  bool isLoading = true;
  String? restaurantId;
  String? currentUserId;

  @override
  void initState() {
    super.initState();
    _fetchCurrentUserAndMenu();
  }

  Future<void> _fetchCurrentUserAndMenu() async {
    try {
      final session = supabase.auth.currentSession;
      if (session == null) {
        setState(() => isLoading = false);
        return;
      }

      currentUserId = session.user.id;
      if (currentUserId == null) {
        setState(() => isLoading = false);
        return;
      }

      final userData = await supabase
          .from('users')
          .select()
          .eq('user_id', currentUserId!)
          .single();

      if (userData['role'] == 'restaurant_owner') {
        restaurantId = userData['restaurant_id'];
        if (restaurantId != null) {
          await _fetchRestaurantMenu(restaurantId!);
        }
      }

      setState(() => isLoading = false);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching data: $e')),
      );
      setState(() => isLoading = false);
    }
  }

  Future<void> _fetchRestaurantMenu(String restaurantId) async {
    try {
      final data = await supabase
          .from('menu')
          .select()
          .eq('restaurant_id', restaurantId);

      setState(() {
        menuItems = List<Map<String, dynamic>>.from(data);
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching menu: $e')),
      );
    }
  }

  void _addNewItem() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditMenuItemScreen(
          restaurantId: restaurantId!,
          onSave: (newItem) async {
            try {
              final response =
                  await supabase.from('menu').insert(newItem).select().single();

              setState(() {
                menuItems.add(Map<String, dynamic>.from(response));
              });
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error adding item: $e')),
              );
            }
          },
        ),
      ),
    );
  }

  void _editItem(int index) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditMenuItemScreen(
          restaurantId: restaurantId!,
          item: menuItems[index],
          onSave: (updatedItem) async {
            try {
              await supabase
                  .from('menu')
                  .update(updatedItem)
                  .eq('menu_id', updatedItem['menu_id']);

              setState(() {
                menuItems[index] = updatedItem;
              });
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error updating item: $e')),
              );
            }
          },
        ),
      ),
    );
  }

  Future<void> _deleteItem(int index) async {
    final itemId = menuItems[index]['menu_id'];
    try {
      await supabase.from('menu').delete().eq('menu_id', itemId);
      setState(() {
        menuItems.removeAt(index);
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting item: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Menu'),
        actions: [
          if (restaurantId != null)
            IconButton(
              icon: const Icon(Iconsax.add),
              onPressed: _addNewItem,
            ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : restaurantId == null
              ? const Center(
                  child: Text(
                    'You are not associated with any restaurant',
                    style: TextStyle(color: Colors.white),
                  ),
                )
              : menuItems.isEmpty
                  ? const Center(
                      child: Text(
                        'No menu items found',
                        style: TextStyle(color: Colors.white),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: menuItems.length,
                      itemBuilder: (context, index) {
                        final item = menuItems[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF222222),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(16),
                            leading: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                item['image_url'],
                                width: 60,
                                height: 60,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    const Icon(Iconsax.gallery,
                                        size: 60, color: Colors.grey),
                              ),
                            ),
                            title: Text(
                              item['name'],
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Iconsax.timer,
                                        size: 14, color: Colors.grey),
                                    const SizedBox(width: 4),
                                    Text(
                                      item['cooking_time'],
                                      style: const TextStyle(
                                          color: Colors.grey, fontSize: 12),
                                    ),
                                    const SizedBox(width: 12),
                                    const Icon(Iconsax.star,
                                        size: 14, color: Colors.grey),
                                    const SizedBox(width: 4),
                                    Text(
                                      item['rating'].toString(),
                                      style: const TextStyle(
                                          color: Colors.grey, fontSize: 12),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '\$${item['price'].toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Iconsax.edit,
                                      color: Colors.white),
                                  onPressed: () => _editItem(index),
                                ),
                                IconButton(
                                  icon: const Icon(Iconsax.trash,
                                      color: Colors.red),
                                  onPressed: () => _deleteItem(index),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
      bottomNavigationBar: CustomFiveFooter(
        selectedIndex: widget.selectedIndex,
      ),
    );
  }
}

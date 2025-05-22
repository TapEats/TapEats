import 'dart:io';

import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tapeats/presentation/widgets/header_widget.dart';
import 'package:tapeats/services/food_image_service.dart';

class MenuManagementScreen extends StatefulWidget {

  const MenuManagementScreen({
    super.key,
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
  File? _selectedFoodImage;
  String? _currentFoodImageUrl;
  bool _isImageLoading = false;
  final _foodImageService = FoodImageService();
  bool isEditing = false;

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

      final userData = await supabase
          .from('users')
          .select()
          .eq('user_id', currentUserId as Object)
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
        SnackBar(
          content: Text('Error fetching data: $e'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() => isLoading = false);
    }
  }

  Future<void> _handleImageUpload() async {
    if (!isEditing) return;

    setState(() => _isImageLoading = true);
    try {
      final imageFile = await _foodImageService.pickImage();
      if (imageFile == null) return;

      setState(() {
        _selectedFoodImage = imageFile;
        _currentFoodImageUrl = null;
      });
    } finally {
      setState(() => _isImageLoading = false);
    }
  }

  void _removeImage() {
    setState(() {
      _selectedFoodImage = null;
      _currentFoodImageUrl = null;
    });
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
        SnackBar(
          content: Text('Error fetching menu: $e'),
          backgroundColor: Colors.red,
        ),
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
                SnackBar(
                  content: Text('Error adding item: $e'),
                  backgroundColor: Colors.red,
                ),
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
                SnackBar(
                  content: Text('Error updating item: $e'),
                  backgroundColor: Colors.red,
                ),
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
        SnackBar(
          content: Text('Error deleting item: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF151611),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: HeaderWidget(
                leftIcon: Iconsax.arrow_left_1,
                onLeftButtonPressed: () => Navigator.pop(context),
                headingText: "Menu Management",
                rightIcon: Iconsax.add,
                onRightButtonPressed:
                    restaurantId != null ? () => _addNewItem() : () {},
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 20)),
            SliverFillRemaining(
              child: isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFFD0F0C0),
                      ),
                    )
                  : restaurantId == null
                      ? Center(
                          child: Text(
                            'You are not associated with any restaurant',
                            style: TextStyle(color: Color(0xFFD0F0C0)),
                          ),
                        )
                      : menuItems.isEmpty
                          ? Center(
                              child: Text(
                                'No menu items found',
                                style: TextStyle(color: Color(0xFFD0F0C0)),
                              ),
                            )
                          : Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              child: ListView.builder(
                                itemCount: menuItems.length,
                                itemBuilder: (context, index) {
                                  final item = menuItems[index];
                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 16),
                                    padding: const EdgeInsets.all(15),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF1A1A1A),
                                      borderRadius: BorderRadius.circular(15),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withAlpha(51),
                                          blurRadius: 10,
                                          spreadRadius: 2,
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        // New Image Section
                                        if (item['image_url'] != null &&
                                            item['image_url'].isNotEmpty)
                                          ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            child: Image.network(
                                              item['image_url'],
                                              height: 150,
                                              width: double.infinity,
                                              fit: BoxFit.cover,
                                              loadingBuilder: (context, child,
                                                  loadingProgress) {
                                                // Fixed position
                                                if (loadingProgress == null)
                                                  return child;
                                                return Container(
                                                  height: 150,
                                                  color: Colors.black26,
                                                  child: const Center(
                                                    child:
                                                        CircularProgressIndicator(
                                                            color: Color(
                                                                0xFFD0F0C0)),
                                                  ),
                                                );
                                              },
                                              errorBuilder: (context, error,
                                                      stackTrace) =>
                                                  Container(
                                                height: 150,
                                                color: Colors.black26,
                                                child: const Icon(
                                                    Icons.fastfood,
                                                    color: Color(0xFFD0F0C0)),
                                              ),
                                            ),
                                          ),
                                        const SizedBox(height: 12),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    item['name'],
                                                    style: const TextStyle(
                                                      color: Color(0xFFEEEFEF),
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 8),
                                                  Row(
                                                    children: [
                                                      const Icon(Iconsax.timer,
                                                          size: 14,
                                                          color: Color(
                                                              0xFFEEEFEF)),
                                                      const SizedBox(width: 4),
                                                      Text(
                                                        item['cooking_time'],
                                                        style: const TextStyle(
                                                            color: Color(
                                                                0xFFEEEFEF),
                                                            fontSize: 12),
                                                      ),
                                                      const SizedBox(width: 12),
                                                      const Icon(Iconsax.star,
                                                          size: 14,
                                                          color: Color(
                                                              0xFFEEEFEF)),
                                                      const SizedBox(width: 4),
                                                      Text(
                                                        item['rating']
                                                            .toString(),
                                                        style: const TextStyle(
                                                            color: Color(
                                                                0xFFEEEFEF),
                                                            fontSize: 12),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 8),
                                                  Text(
                                                    '\$${item['price'].toStringAsFixed(2)}',
                                                    style: const TextStyle(
                                                      color: Color(0xFFEEEFEF),
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                IconButton(
                                                  icon: const Icon(Iconsax.edit,
                                                      color: Color(0xFFD0F0C0)),
                                                  onPressed: () =>
                                                      _editItem(index),
                                                ),
                                                IconButton(
                                                  icon: const Icon(
                                                      Iconsax.trash,
                                                      color: Colors.red),
                                                  onPressed: () =>
                                                      _deleteItem(index),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                        if (item['description'] != null &&
                                            item['description'].isNotEmpty)
                                          Padding(
                                            padding:
                                                const EdgeInsets.only(top: 8),
                                            child: Text(
                                              item['description'],
                                              style: const TextStyle(
                                                color: Color(0xFFEEEFEF),
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
            ),
          ],
        ),
      ),
    );
  }
}

class AddEditMenuItemScreen extends StatefulWidget {
  final String restaurantId;
  final Map<String, dynamic>? item;
  final Function(Map<String, dynamic>) onSave;

  const AddEditMenuItemScreen({
    super.key,
    required this.restaurantId,
    this.item,
    required this.onSave,
  });

  @override
  State<AddEditMenuItemScreen> createState() => _AddEditMenuItemScreenState();
}

class _AddEditMenuItemScreenState extends State<AddEditMenuItemScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _priceController;
  late TextEditingController _categoryController;
  late TextEditingController _timeController;
  late TextEditingController _ratingController;
  late TextEditingController _ingredientsController;
  late TextEditingController _descriptionController;

  File? _selectedFoodImage;
  String? _currentFoodImageUrl;
  bool _isImageLoading = false;
  final _foodImageService = FoodImageService();

  @override
  void initState() {
    super.initState();
    _currentFoodImageUrl = widget.item?['image_url'];
    _nameController = TextEditingController(text: widget.item?['name'] ?? '');
    _priceController =
        TextEditingController(text: widget.item?['price']?.toString() ?? '');
    _categoryController =
        TextEditingController(text: widget.item?['category'] ?? '');
    _timeController =
        TextEditingController(text: widget.item?['cooking_time'] ?? '');
    _ratingController = TextEditingController(
        text: widget.item?['rating']?.toString() ?? '4.5');
    _ingredientsController =
        TextEditingController(text: widget.item?['ingredients'] ?? '');
    _descriptionController =
        TextEditingController(text: widget.item?['description'] ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _categoryController.dispose();
    _timeController.dispose();
    _ratingController.dispose();
    _ingredientsController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _handleImageUpload() async {
    setState(() => _isImageLoading = true);
    try {
      final imageFile = await _foodImageService.pickImage();
      if (imageFile == null) return;
      setState(() {
        _selectedFoodImage = imageFile;
        _currentFoodImageUrl = null;
      });
    } finally {
      setState(() => _isImageLoading = false);
    }
  }

  void _removeImage() {
    setState(() {
      _selectedFoodImage = null;
      _currentFoodImageUrl = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF151611),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: HeaderWidget(
                leftIcon: Iconsax.arrow_left_1,
                onLeftButtonPressed: () => Navigator.pop(context),
                headingText:
                    widget.item == null ? 'Add Menu Item' : 'Edit Menu Item',
                rightIcon: Iconsax.tick_circle,
                onRightButtonPressed: () => _saveItem(),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 20)),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          CircleAvatar(
                            radius: 60,
                            backgroundColor:
                                const Color(0xFFD0F0C0).withOpacity(0.1),
                            child: ClipOval(
                              child: SizedBox(
                                width: 120,
                                height: 120,
                                child: _isImageLoading
                                    ? const Center(
                                        child: CircularProgressIndicator(
                                            color: Color(0xFFD0F0C0)))
                                    : _selectedFoodImage != null
                                        ? Image.file(_selectedFoodImage!,
                                            fit: BoxFit.cover)
                                        : _currentFoodImageUrl != null
                                            ? Image.network(
                                                _currentFoodImageUrl!,
                                                fit: BoxFit.cover,
                                                errorBuilder: (context, error,
                                                        stackTrace) =>
                                                    const Icon(Icons.fastfood,
                                                        size: 40,
                                                        color:
                                                            Color(0xFFD0F0C0)),
                                                loadingBuilder: (context, child,
                                                    loadingProgress) {
                                                  if (loadingProgress == null)
                                                    return child;
                                                  return const Center(
                                                      child:
                                                          CircularProgressIndicator(
                                                              color: Color(
                                                                  0xFFD0F0C0)));
                                                },
                                              )
                                            : const Icon(Icons.fastfood,
                                                size: 40,
                                                color: Color(0xFFD0F0C0)),
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Row(
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.6),
                                    shape: BoxShape.circle,
                                  ),
                                  child: IconButton(
                                    icon: const Icon(Iconsax.gallery_edit,
                                        size: 20),
                                    color: const Color(0xFFD0F0C0),
                                    onPressed: _handleImageUpload,
                                  ),
                                ),
                                if (_selectedFoodImage != null ||
                                    _currentFoodImageUrl != null)
                                  Padding(
                                    padding: const EdgeInsets.only(left: 8.0),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.6),
                                        shape: BoxShape.circle,
                                      ),
                                      child: IconButton(
                                        icon:
                                            const Icon(Iconsax.trash, size: 20),
                                        color: Colors.red,
                                        onPressed: _removeImage,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: _nameController,
                        style: const TextStyle(color: Color(0xFFEEEFEF)),
                        decoration: InputDecoration(
                          labelText: 'Item Name',
                          labelStyle: const TextStyle(color: Color(0xFFD0F0C0)),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide:
                                const BorderSide(color: Color(0xFFD0F0C0)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide:
                                const BorderSide(color: Color(0xFFD0F0C0)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide:
                                const BorderSide(color: Color(0xFFD0F0C0)),
                          ),
                        ),
                        validator: (value) =>
                            value?.isEmpty ?? true ? 'Required field' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _priceController,
                        style: const TextStyle(color: Color(0xFFEEEFEF)),
                        decoration: InputDecoration(
                          labelText: 'Price',
                          labelStyle: const TextStyle(color: Color(0xFFD0F0C0)),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide:
                                const BorderSide(color: Color(0xFFD0F0C0)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide:
                                const BorderSide(color: Color(0xFFD0F0C0)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide:
                                const BorderSide(color: Color(0xFFD0F0C0)),
                          ),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) =>
                            value?.isEmpty ?? true ? 'Required field' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _categoryController,
                        style: const TextStyle(color: Color(0xFFEEEFEF)),
                        decoration: InputDecoration(
                          labelText: 'Category',
                          labelStyle: const TextStyle(color: Color(0xFFD0F0C0)),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide:
                                const BorderSide(color: Color(0xFFD0F0C0)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide:
                                const BorderSide(color: Color(0xFFD0F0C0)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide:
                                const BorderSide(color: Color(0xFFD0F0C0)),
                          ),
                        ),
                        validator: (value) =>
                            value?.isEmpty ?? true ? 'Required field' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _timeController,
                        style: const TextStyle(color: Color(0xFFEEEFEF)),
                        decoration: InputDecoration(
                          labelText: 'Cooking Time',
                          labelStyle: const TextStyle(color: Color(0xFFD0F0C0)),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide:
                                const BorderSide(color: Color(0xFFD0F0C0)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide:
                                const BorderSide(color: Color(0xFFD0F0C0)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide:
                                const BorderSide(color: Color(0xFFD0F0C0)),
                          ),
                        ),
                        validator: (value) =>
                            value?.isEmpty ?? true ? 'Required field' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _ratingController,
                        style: const TextStyle(color: Color(0xFFEEEFEF)),
                        decoration: InputDecoration(
                          labelText: 'Rating',
                          labelStyle: const TextStyle(color: Color(0xFFD0F0C0)),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide:
                                const BorderSide(color: Color(0xFFD0F0C0)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide:
                                const BorderSide(color: Color(0xFFD0F0C0)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide:
                                const BorderSide(color: Color(0xFFD0F0C0)),
                          ),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) =>
                            value?.isEmpty ?? true ? 'Required field' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _ingredientsController,
                        style: const TextStyle(color: Color(0xFFEEEFEF)),
                        decoration: InputDecoration(
                          labelText: 'Ingredients',
                          labelStyle: const TextStyle(color: Color(0xFFD0F0C0)),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide:
                                const BorderSide(color: Color(0xFFD0F0C0)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide:
                                const BorderSide(color: Color(0xFFD0F0C0)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide:
                                const BorderSide(color: Color(0xFFD0F0C0)),
                          ),
                        ),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _descriptionController,
                        style: const TextStyle(color: Color(0xFFEEEFEF)),
                        decoration: InputDecoration(
                          labelText: 'Description',
                          labelStyle: const TextStyle(color: Color(0xFFD0F0C0)),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide:
                                const BorderSide(color: Color(0xFFD0F0C0)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide:
                                const BorderSide(color: Color(0xFFD0F0C0)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide:
                                const BorderSide(color: Color(0xFFD0F0C0)),
                          ),
                        ),
                        maxLines: 3,
                      ),
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

  void _saveItem() async {
    if (_formKey.currentState?.validate() ?? false) {
      try {
        String? imageUrl = _currentFoodImageUrl;
        if (_selectedFoodImage != null) {
          imageUrl = await _foodImageService.uploadFoodImage(
            widget.restaurantId,
            widget.item?['menu_id'] ??
                'temp_${DateTime.now().millisecondsSinceEpoch}',
            _selectedFoodImage!,
          );
        }
        final newItem = {
          if (widget.item != null) 'menu_id': widget.item!['menu_id'],
          'restaurant_id': widget.restaurantId,
          'name': _nameController.text,
          'price': double.parse(_priceController.text),
          'category': _categoryController.text,
          'rating': double.parse(_ratingController.text),
          'cooking_time': _timeController.text,
          'image_url': imageUrl,
          'ingredients': _ingredientsController.text,
          'description': _descriptionController.text,
          'created_at': DateTime.now().toIso8601String(),
        };
        widget.onSave(newItem);
        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }
}

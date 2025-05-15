import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tapeats/presentation/state_management/navbar_state.dart';
import 'package:tapeats/presentation/widgets/header_widget.dart';
import 'package:tapeats/presentation/widgets/footer_widget.dart';
import 'package:tapeats/presentation/widgets/search_bar.dart';
import 'package:tapeats/presentation/widgets/sidemenu_overlay.dart';

class SuppliersManagementPage extends StatefulWidget {
  final int selectedIndex;

  const SuppliersManagementPage({
    super.key,
    this.selectedIndex = 3, // Default to inventory tab index
  });

  @override
  State<SuppliersManagementPage> createState() =>
      _SuppliersManagementPageState();
}

class _SuppliersManagementPageState extends State<SuppliersManagementPage> {
  final SupabaseClient _supabase = Supabase.instance.client;
  final TextEditingController _searchController = TextEditingController();

  bool _isLoading = true;
  List<Map<String, dynamic>> _suppliers = [];
  List<Map<String, dynamic>> _filteredSuppliers = [];
  List<String> _productTypes = ['All'];
  String _selectedProductType = 'All';

  @override
  void initState() {
    super.initState();

    // Update the navbar state with the correct index
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<NavbarState>(context, listen: false)
          .updateIndex(widget.selectedIndex);
      _fetchSuppliers();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openSideMenu() {
    // Show the side menu as a modal overlay
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Side Menu",
      pageBuilder: (context, animation1, animation2) {
        return const RoleBasedSideMenu();
      },
    );
  }

  Future<void> _fetchSuppliers() async {
    setState(() => _isLoading = true);

    try {
      // Get restaurant ID
      final user = _supabase.auth.currentUser;
      if (user == null) {
        setState(() => _isLoading = false);
        return;
      }

      final userData = await _supabase
          .from('users')
          .select('restaurant_id')
          .eq('user_id', user.id)
          .maybeSingle();

      if (userData == null || userData['restaurant_id'] == null) {
        print('No restaurant_id found for user');
        setState(() => _isLoading = false);
        return;
      }

      final restaurantId = userData['restaurant_id'];

      // Fetch suppliers
      final suppliersResult = await _supabase
          .from('supplier_id')
          .select('*')
          .eq('restaurant_id', restaurantId);

      // Extract unique product types for filtering
      final productTypes = ['All'];
      for (var supplier in suppliersResult) {
        if (supplier['product_type'] != null &&
            !productTypes.contains(supplier['product_type'])) {
          productTypes.add(supplier['product_type']);
        }
      }

      setState(() {
        _suppliers = suppliersResult;
        _filteredSuppliers = suppliersResult;
        _productTypes = productTypes;
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching suppliers: $e');
      setState(() {
        _suppliers = [];
        _filteredSuppliers = [];
        _isLoading = false;
      });
    }
  }

  void _filterSuppliers() {
    final searchText = _searchController.text.toLowerCase();

    setState(() {
      _filteredSuppliers = _suppliers.where((supplier) {
        // Filter by product type first if not "All"
        if (_selectedProductType != 'All' &&
            supplier['product_type'] != _selectedProductType) {
          return false;
        }

        // Then filter by search text if any
        if (searchText.isEmpty) {
          return true;
        }

        final name = supplier['name']?.toString().toLowerCase() ?? '';
        final companyName =
            supplier['company_name']?.toString().toLowerCase() ?? '';
        final email = supplier['email']?.toString().toLowerCase() ?? '';
        final contact = supplier['contact']?.toString().toLowerCase() ?? '';
        final address = supplier['address']?.toString().toLowerCase() ?? '';

        return name.contains(searchText) ||
            companyName.contains(searchText) ||
            email.contains(searchText) ||
            contact.contains(searchText) ||
            address.contains(searchText);
      }).toList();
    });
  }

  void _selectProductType(String type) {
    setState(() {
      _selectedProductType = type;
    });
    _filterSuppliers();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            HeaderWidget(
              leftIcon: Iconsax.arrow_left_1,
              onLeftButtonPressed: () => Navigator.pop(context),
              headingText: "Suppliers",
              rightIcon: Iconsax.menu_1,
              onRightButtonPressed: _openSideMenu,
            ),

            const SizedBox(height: 20),

            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: CustomSearchBar(
                controller: _searchController,
                hintText: "Search suppliers...",
                onSearch: _filterSuppliers,
              ),
            ),

            const SizedBox(height: 16),

            // Product type filters
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: _productTypes
                    .map((type) => _buildProductTypeChip(
                        type, _selectedProductType == type))
                    .toList(),
              ),
            ),

            const SizedBox(height: 16),

            // Column Headers
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  Expanded(
                    flex: 4,
                    child: Text(
                      "Company",
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      "Contact",
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      "Products",
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.end,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Main content - Suppliers List
            Expanded(
              child: _isLoading
                  ? const Center(
                      child:
                          CircularProgressIndicator(color: Color(0xFFD0F0C0)))
                  : _filteredSuppliers.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          itemCount: _filteredSuppliers.length,
                          itemBuilder: (context, index) {
                            final supplier = _filteredSuppliers[index];
                            return _buildSupplierItem(supplier);
                          },
                        ),
            ),

            // Bottom padding for the navbar
            const SizedBox(height: 70),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFFD0F0C0),
        onPressed: () {
          _showAddEditSupplierModal(context);
        },
        child: const Icon(Iconsax.add, color: Color(0xFF222222)),
      ),
      // bottomNavigationBar: const DynamicFooter(),
    );
  }

  Widget _buildProductTypeChip(String label, bool isSelected) {
    return Container(
      margin: const EdgeInsets.only(right: 12),
      child: FilterChip(
        label: Text(
          label,
          style: TextStyle(
            color:
                isSelected ? const Color(0xFF222222) : const Color(0xFFEEEFEF),
            fontFamily: 'Helvetica Neue',
            fontWeight: FontWeight.w500,
          ),
        ),
        selected: isSelected,
        showCheckmark: false,
        backgroundColor: const Color(0xFF222222),
        selectedColor: const Color(0xFFD0F0C0),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        onSelected: (selected) {
          if (selected) {
            _selectProductType(label);
          }
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Iconsax.truck,
            size: 64,
            color: Colors.white.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            _selectedProductType != 'All'
                ? "No suppliers found for ${_selectedProductType}"
                : "No suppliers found",
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () {
              _showAddEditSupplierModal(context);
            },
            icon: const Icon(Iconsax.add, color: Color(0xFFD0F0C0)),
            label: const Text(
              "Add New Supplier",
              style: TextStyle(color: Color(0xFFD0F0C0)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSupplierItem(Map<String, dynamic> supplier) {
    return InkWell(
      onTap: () {
        _showAddEditSupplierModal(context, supplier: supplier);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF222222),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            // Company info
            Expanded(
              flex: 4,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    supplier['company_name'] ?? 'Unnamed Company',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    supplier['address'] ?? 'No address',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 12,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // Contact info
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    supplier['name'] ?? '—',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    supplier['contact'] ?? '—',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 12,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // Product type
            Expanded(
              flex: 3,
              child: Text(
                supplier['product_type'] ?? '—',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
                textAlign: TextAlign.end,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddEditSupplierModal(BuildContext context,
      {Map<String, dynamic>? supplier}) {
    // Controllers for the form fields
    final nameController = TextEditingController(text: supplier?['name'] ?? '');
    final companyNameController =
        TextEditingController(text: supplier?['company_name'] ?? '');
    final contactController =
        TextEditingController(text: supplier?['contact'] ?? '');
    final emailController =
        TextEditingController(text: supplier?['email'] ?? '');
    final addressController =
        TextEditingController(text: supplier?['address'] ?? '');
    final productTypeController =
        TextEditingController(text: supplier?['product_type'] ?? '');

    // Form key for validation
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Modal title
                  Center(
                    child: Text(
                      supplier != null ? 'Edit Supplier' : 'Add New Supplier',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Form fields
                  TextFormField(
                    controller: companyNameController,
                    decoration: _inputDecoration('Company Name'),
                    style: const TextStyle(color: Colors.white),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a company name';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  TextFormField(
                    controller: nameController,
                    decoration: _inputDecoration('Contact Person Name'),
                    style: const TextStyle(color: Colors.white),
                  ),

                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: contactController,
                          decoration: _inputDecoration('Phone Number'),
                          keyboardType: TextInputType.phone,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: emailController,
                          decoration: _inputDecoration('Email'),
                          keyboardType: TextInputType.emailAddress,
                          style: const TextStyle(color: Colors.white),
                          validator: (value) {
                            if (value != null && value.isNotEmpty) {
                              // Simple email validation
                              final emailRegExp =
                                  RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                              if (!emailRegExp.hasMatch(value)) {
                                return 'Invalid email';
                              }
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  TextFormField(
                    controller: addressController,
                    decoration: _inputDecoration('Address'),
                    style: const TextStyle(color: Colors.white),
                    maxLines: 2,
                  ),

                  const SizedBox(height: 16),

                  TextFormField(
                    controller: productTypeController,
                    decoration: _inputDecoration('Product Type'),
                    style: const TextStyle(color: Colors.white),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a product type';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 24),

                  // Action buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Cancel button
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(color: Colors.white70),
                        ),
                      ),

                      // Save button
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFD0F0C0),
                          foregroundColor: const Color(0xFF222222),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                        ),
                        onPressed: () {
                          if (formKey.currentState!.validate()) {
                            // Logic to save or update supplier
                            _saveSupplier(
                              context,
                              supplierId: supplier?['supplier_id'],
                              name: nameController.text,
                              companyName: companyNameController.text,
                              contact: contactController.text,
                              email: emailController.text,
                              address: addressController.text,
                              productType: productTypeController.text,
                            );
                          }
                        },
                        child: Text(
                          supplier != null ? 'Update' : 'Add Supplier',
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
      filled: true,
      fillColor: const Color(0xFF2A2A2A),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFD0F0C0), width: 1),
      ),
    );
  }

  Future<void> _saveSupplier(
    BuildContext context, {
    String? supplierId,
    required String companyName,
    String? name,
    String? contact,
    String? email,
    String? address,
    required String productType,
  }) async {
    // Close the modal
    Navigator.pop(context);

    // Show loading indicator
    setState(() => _isLoading = true);

    try {
      // Get restaurant ID
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      final userData = await _supabase
          .from('users')
          .select('restaurant_id')
          .eq('user_id', user.id)
          .maybeSingle();

      if (userData == null || userData['restaurant_id'] == null) return;

      final restaurantId = userData['restaurant_id'];
      final now = DateTime.now().toIso8601String();

      if (supplierId != null) {
        // Update existing supplier
        await _supabase.from('supplier_id').update({
          'name': name,
          'company_name': companyName,
          'contact': contact,
          'email': email,
          'address': address,
          'product_type': productType,
          'updated_at': now,
        }).eq('supplier_id', supplierId);
      } else {
        // Create new supplier
        await _supabase.from('supplier_id').insert({
          'name': name,
          'company_name': companyName,
          'contact': contact,
          'email': email,
          'address': address,
          'product_type': productType,
          'restaurant_id': restaurantId,
          'created_at': now,
          'updated_at': now,
        });
      }

      // Refresh suppliers data
      await _fetchSuppliers();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(supplierId != null
                ? 'Supplier updated successfully'
                : 'Supplier added successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error saving supplier: $e');

      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving supplier: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}

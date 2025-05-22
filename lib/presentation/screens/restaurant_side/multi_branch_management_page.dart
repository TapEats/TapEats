import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tapeats/presentation/widgets/feature_gate.dart';
import 'package:tapeats/presentation/widgets/header_widget.dart';
import 'package:tapeats/presentation/widgets/sidemenu_overlay.dart';
import 'package:tapeats/services/subscription_service.dart';

class MultiBranchManagementPage extends StatefulWidget {
  const MultiBranchManagementPage({super.key});

  @override
  State<MultiBranchManagementPage> createState() => _MultiBranchManagementPageState();
}

class _MultiBranchManagementPageState extends State<MultiBranchManagementPage> {
  final SupabaseClient _supabase = Supabase.instance.client;
  final SubscriptionService _subscriptionService = SubscriptionService();
  bool _isLoading = false;
  List<Map<String, dynamic>> _branches = [];
  String? _restaurantId;
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    _initializeData();
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    super.dispose();
  }
  
  Future<void> _initializeData() async {
    await _getRestaurantId();
    await _loadBranches();
  }
  
  Future<void> _getRestaurantId() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user != null) {
        _restaurantId = await _subscriptionService.getRestaurantIdForUser(user.id);
      }
    } catch (e) {
      print('Error getting restaurant ID: $e');
    }
  }
  
  Future<void> _loadBranches() async {
    if (_restaurantId == null) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Get all branches for this restaurant
      final branchesData = await _supabase
          .from('restaurant_branches')
          .select('*')
          .eq('main_restaurant_id', _restaurantId!)
          .order('created_at', ascending: false);
      
      setState(() {
        _branches = List<Map<String, dynamic>>.from(branchesData);
      });
    } catch (e) {
      print('Error loading branches: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading branches: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  Future<void> _addBranch() async {
    if (_nameController.text.isEmpty || _addressController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in name and address'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    if (_restaurantId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Restaurant ID not found'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Add the new branch
      await _supabase.from('restaurant_branches').insert({
        'main_restaurant_id': _restaurantId!,
        'name': _nameController.text,
        'address': _addressController.text,
        'phone': _phoneController.text.isNotEmpty ? _phoneController.text : null,
        'status': 'active',
        'created_at': DateTime.now().toIso8601String(),
      });
      
      // Clear the form
      _nameController.clear();
      _addressController.clear();
      _phoneController.clear();
      
      // Reload branches
      await _loadBranches();
      
      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Branch added successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error adding branch: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding branch: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  void _showAddBranchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF222222),
        title: const Text(
          'Add New Branch',
          style: TextStyle(
            color: Color(0xFFEEEFEF),
            fontFamily: 'Helvetica Neue',
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nameController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Branch Name',
                  labelStyle: TextStyle(color: Colors.grey[400]),
                  filled: true,
                  fillColor: const Color(0xFF151611),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _addressController,
                style: const TextStyle(color: Colors.white),
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Address',
                  labelStyle: TextStyle(color: Colors.grey[400]),
                  filled: true,
                  fillColor: const Color(0xFF151611),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _phoneController,
                style: const TextStyle(color: Colors.white),
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Phone Number (Optional)',
                  labelStyle: TextStyle(color: Colors.grey[400]),
                  filled: true,
                  fillColor: const Color(0xFF151611),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.grey[400]),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _addBranch();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD0F0C0),
              foregroundColor: Colors.black,
            ),
            child: const Text('Add Branch'),
          ),
        ],
      ),
    );
  }
  
  void _openSideMenu() {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        pageBuilder: (_, __, ___) => const RoleBasedSideMenu(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF151611),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            HeaderWidget(
              leftIcon: Iconsax.arrow_left_1,
              onLeftButtonPressed: () => Navigator.pop(context),
              headingText: "Branch Management",
              headingIcon: Iconsax.building,
              rightIcon: Iconsax.menu_1,
              onRightButtonPressed: _openSideMenu,
            ),
            
            // Feature Gate for Premium Multi-Branch Feature
            Expanded(
              child: FeatureGate(
                feature: 'multi_branch',
                child: _buildBranchContent(),
                onUpgrade: () {
                  // Navigate to subscription page
                  Navigator.pushNamed(context, '/subscription');
                },
              ),
            ),
          ],
        ),
      ),
      // Conditional FAB based on feature access
      floatingActionButton: _buildConditionalFAB(),
    );
  }
  
  Widget _buildConditionalFAB() {
    if (_restaurantId == null) return const SizedBox.shrink();
    
    return FutureBuilder<bool>(
      future: _subscriptionService.hasFeatureAccess(_restaurantId!, 'multi_branch'),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox.shrink();
        }
        
        final hasAccess = snapshot.data ?? false;
        
        if (hasAccess) {
          return FloatingActionButton(
            onPressed: _showAddBranchDialog,
            backgroundColor: const Color(0xFFD0F0C0),
            child: const Icon(
              Iconsax.add,
              color: Color(0xFF151611),
            ),
          );
        } else {
          return const SizedBox.shrink();
        }
      },
    );
  }
  
  Widget _buildBranchContent() {
    return Column(
      children: [
        // Statistics summary
        Padding(
          padding: const EdgeInsets.all(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF222222),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                _buildStatCard(
                  icon: Iconsax.building,
                  value: _branches.length.toString(),
                  label: 'Branches',
                ),
                const SizedBox(width: 16),
                _buildStatCard(
                  icon: Iconsax.user,
                  value: '${_branches.length * 3}',
                  label: 'Est. Staff',
                ),
                const SizedBox(width: 16),
                _buildStatCard(
                  icon: Iconsax.receipt_2,
                  value: '${_branches.length * 15}',
                  label: 'Est. Orders',
                ),
              ],
            ),
          ),
        ),
        
        // Branch list
        Expanded(
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: Color(0xFFD0F0C0)),
                )
              : _branches.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _branches.length,
                      itemBuilder: (context, index) {
                        final branch = _branches[index];
                        return _buildBranchCard(branch);
                      },
                    ),
        ),
      ],
    );
  }
  
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Iconsax.building,
            size: 64,
            color: Color(0xFF333333),
          ),
          const SizedBox(height: 16),
          Text(
            'No branches yet',
            style: GoogleFonts.lato(
              color: Colors.grey[400],
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add your first branch to get started',
            style: GoogleFonts.lato(
              color: Colors.grey[500],
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _showAddBranchDialog,
            icon: const Icon(Iconsax.add),
            label: const Text('Add First Branch'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD0F0C0),
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Expanded(
      child: Column(
        children: [
          Icon(
            icon,
            color: const Color(0xFFD0F0C0),
            size: 24,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.lato(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.lato(
              color: Colors.grey[400],
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildBranchCard(Map<String, dynamic> branch) {
    final bool isActive = branch['status'] == 'active';
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: const Color(0xFF1A1A1A),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    branch['name'] ?? 'Unnamed Branch',
                    style: GoogleFonts.lato(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isActive ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isActive ? Colors.green : Colors.red,
                      width: 1,
                    ),
                  ),
                  child: Text(
                    isActive ? 'ACTIVE' : 'INACTIVE',
                    style: GoogleFonts.lato(
                      color: isActive ? Colors.green : Colors.red,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (branch['address'] != null) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Iconsax.location,
                    color: Color(0xFFD0F0C0),
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      branch['address'],
                      style: GoogleFonts.lato(
                        color: Colors.grey[300],
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
            if (branch['phone'] != null) ...[
              Row(
                children: [
                  const Icon(
                    Iconsax.call,
                    color: Color(0xFFD0F0C0),
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    branch['phone'],
                    style: GoogleFonts.lato(
                      color: Colors.grey[300],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
            if (branch['created_at'] != null) ...[
              Row(
                children: [
                  const Icon(
                    Iconsax.calendar,
                    color: Color(0xFFD0F0C0),
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Added ${_formatDate(branch['created_at'])}',
                    style: GoogleFonts.lato(
                      color: Colors.grey[400],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  onPressed: () {
                    _showEditBranchDialog(branch);
                  },
                  icon: const Icon(
                    Iconsax.edit,
                    size: 16,
                  ),
                  label: const Text('Edit'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFD0F0C0),
                    side: const BorderSide(color: Color(0xFFD0F0C0)),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () {
                    _toggleBranchStatus(branch);
                  },
                  icon: Icon(
                    isActive ? Iconsax.pause : Iconsax.play,
                    size: 16,
                  ),
                  label: Text(isActive ? 'Deactivate' : 'Activate'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isActive ? Colors.orange : const Color(0xFFD0F0C0),
                    foregroundColor: isActive ? Colors.white : Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date);
      
      if (difference.inDays == 0) {
        return 'today';
      } else if (difference.inDays == 1) {
        return 'yesterday';
      } else if (difference.inDays < 30) {
        return '${difference.inDays} days ago';
      } else {
        return '${date.day}/${date.month}/${date.year}';
      }
    } catch (e) {
      return 'Unknown';
    }
  }
  
  void _showEditBranchDialog(Map<String, dynamic> branch) {
    _nameController.text = branch['name'] ?? '';
    _addressController.text = branch['address'] ?? '';
    _phoneController.text = branch['phone'] ?? '';
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF222222),
        title: const Text(
          'Edit Branch',
          style: TextStyle(
            color: Color(0xFFEEEFEF),
            fontFamily: 'Helvetica Neue',
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nameController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Branch Name',
                  labelStyle: TextStyle(color: Colors.grey[400]),
                  filled: true,
                  fillColor: const Color(0xFF151611),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _addressController,
                style: const TextStyle(color: Colors.white),
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Address',
                  labelStyle: TextStyle(color: Colors.grey[400]),
                  filled: true,
                  fillColor: const Color(0xFF151611),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _phoneController,
                style: const TextStyle(color: Colors.white),
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Phone Number',
                  labelStyle: TextStyle(color: Colors.grey[400]),
                  filled: true,
                  fillColor: const Color(0xFF151611),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.grey[400]),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _updateBranch(branch['id']);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD0F0C0),
              foregroundColor: Colors.black,
            ),
            child: const Text('Save Changes'),
          ),
        ],
      ),
    );
  }
  
  Future<void> _updateBranch(String branchId) async {
    if (_nameController.text.isEmpty || _addressController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in name and address'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      await _supabase.from('restaurant_branches').update({
        'name': _nameController.text,
        'address': _addressController.text,
        'phone': _phoneController.text.isNotEmpty ? _phoneController.text : null,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', branchId);
      
      // Clear the form
      _nameController.clear();
      _addressController.clear();
      _phoneController.clear();
      
      // Reload branches
      await _loadBranches();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Branch updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error updating branch: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating branch: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  Future<void> _toggleBranchStatus(Map<String, dynamic> branch) async {
    final bool isActive = branch['status'] == 'active';
    final String newStatus = isActive ? 'inactive' : 'active';
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      await _supabase.from('restaurant_branches').update({
        'status': newStatus,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', branch['id']);
      
      // Reload branches
      await _loadBranches();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Branch ${isActive ? 'deactivated' : 'activated'} successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error updating branch status: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating branch status: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:iconsax/iconsax.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tapeats/presentation/widgets/footer_widget.dart';
import 'package:tapeats/presentation/widgets/header_widget.dart';
import 'package:intl/intl.dart';

class AddEmployeePage extends StatefulWidget {
  const AddEmployeePage({super.key});

  @override
  State<AddEmployeePage> createState() => _AddEmployeePageState();
}

class _AddEmployeePageState extends State<AddEmployeePage> {
  final SupabaseClient supabase = Supabase.instance.client;
  final TextEditingController _firstnameController = TextEditingController();
  final TextEditingController _lastnameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _contactController = TextEditingController();
  final TextEditingController _salaryController = TextEditingController();
  final TextEditingController _joiningDateController = TextEditingController();
  
  // Available options for dropdown menus
  final List<String> _availableRoles = ['Manager', 'Chef', 'Waiter', 'Helper'];
  final List<String> _availableGenders = ['Male', 'Female', 'Other'];
  
  // Selected values
  String _selectedRole = 'Waiter';
  String _selectedGender = 'Male';
  DateTime _selectedJoiningDate = DateTime.now();
  
  bool _isLoading = false;
  bool _isSaving = false;
  String? _restaurantId;

  @override
  void initState() {
    super.initState();
    _fetchRestaurantId();
    
    // Initialize joining date controller with current date
    _joiningDateController.text = DateFormat('dd/MM/yyyy').format(_selectedJoiningDate);
  }

  @override
  void dispose() {
    _firstnameController.dispose();
    _lastnameController.dispose();
    _ageController.dispose();
    _contactController.dispose();
    _salaryController.dispose();
    _joiningDateController.dispose();
    super.dispose();
  }

  Future<void> _fetchRestaurantId() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Get current logged-in user
      final user = supabase.auth.currentUser;
      if (user == null) {
        throw Exception("No user logged in");
      }

      // Get the restaurant_id from the users table for the current user
      final userRecord = await supabase
          .from('users')
          .select('restaurant_id')
          .eq('user_id', user.id)
          .single();
      
      if (mounted) {
        setState(() {
          _restaurantId = userRecord['restaurant_id'];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching restaurant ID: $e');
      }
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading restaurant data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Open date picker for joining date
  Future<void> _selectJoiningDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedJoiningDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFFD0F0C0),
              onPrimary: Color(0xFF151611),
              surface: Color(0xFF222222),
              onSurface: Color(0xFFEEEFEF),
            ),
            dialogBackgroundColor: const Color(0xFF1E1F1B),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null && picked != _selectedJoiningDate) {
      setState(() {
        _selectedJoiningDate = picked;
        _joiningDateController.text = DateFormat('dd/MM/yyyy').format(_selectedJoiningDate);
      });
    }
  }

  Future<void> _saveEmployee() async {
    if (_firstnameController.text.isEmpty || _lastnameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a first and last name'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    if (_restaurantId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Restaurant information not available. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    try {
      setState(() {
        _isSaving = true;
      });
      
      final employeeData = {
        'first_name': _firstnameController.text,
        'last_name': _lastnameController.text,
        'age': int.tryParse(_ageController.text) ?? 0,
        'contact_number': _contactController.text,
        'salary': double.tryParse(_salaryController.text) ?? 0.0,
        'role': _selectedRole,
        'gender': _selectedGender, // Add gender field
        'joining_date': _selectedJoiningDate.toIso8601String(), // Add joining date field
        'restaurant_id': _restaurantId,
        'created_at': DateTime.now().toIso8601String(),
      };
      
      await supabase
          .from('employees')
          .insert(employeeData);
      
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
        
        Navigator.pop(context, true); // Return true to trigger refresh
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error saving employee data: $e');
      }
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding employee: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF151611),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFFD0F0C0)))
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  HeaderWidget(
                    leftIcon: Iconsax.arrow_left_1,
                    onLeftButtonPressed: () => Navigator.pop(context),
                    headingText: 'Add Employee',
                    rightIcon: Iconsax.menu_1,
                    onRightButtonPressed: () {},
                  ),
                  const SizedBox(height: 20),
                  
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E1F1B),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // User icon instead of profile image
                            Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                color: Colors.grey[800],
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Iconsax.user,
                                size: 50,
                                color: Colors.white70,
                              ),
                            ),
                            const SizedBox(height: 20),
                            
                            const Text(
                              "New Employee",
                              style: TextStyle(
                                color: Color(0xFFEEEFEF),
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 30),
                            
                            // Form fields
                            _buildTextField("First Name", _firstnameController),
                            const SizedBox(height: 16),
                            _buildTextField("Last Name", _lastnameController),
                            const SizedBox(height: 16),
                            
                            // Role selection
                            _buildDropdown(
                              label: "Role",
                              value: _selectedRole,
                              items: _availableRoles,
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() {
                                    _selectedRole = value;
                                  });
                                }
                              },
                            ),
                            const SizedBox(height: 16),
                            
                            // Gender selection (NEW)
                            _buildDropdown(
                              label: "Gender",
                              value: _selectedGender,
                              items: _availableGenders,
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() {
                                    _selectedGender = value;
                                  });
                                }
                              },
                            ),
                            const SizedBox(height: 16),
                            
                            // Joining date (NEW)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Joining Date",
                                  style: TextStyle(
                                    color: Colors.grey[400],
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                GestureDetector(
                                  onTap: _selectJoiningDate,
                                  child: AbsorbPointer(
                                    child: TextField(
                                      controller: _joiningDateController,
                                      style: const TextStyle(color: Color(0xFFEEEFEF)),
                                      decoration: InputDecoration(
                                        hintText: 'Select joining date',
                                        hintStyle: TextStyle(color: Colors.grey[600]),
                                        filled: true,
                                        fillColor: const Color(0xFF222222),
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(10),
                                          borderSide: BorderSide.none,
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(10),
                                          borderSide: BorderSide.none,
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(10),
                                          borderSide: const BorderSide(color: Color(0xFFD0F0C0), width: 1),
                                        ),
                                        suffixIcon: const Icon(
                                          Icons.calendar_today,
                                          color: Color(0xFFD0F0C0),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            
                            _buildTextField("Age", _ageController, keyboardType: TextInputType.number),
                            const SizedBox(height: 16),
                            _buildTextField("Contact number", _contactController, keyboardType: TextInputType.phone),
                            const SizedBox(height: 16),
                            _buildTextField("Salary", _salaryController, keyboardType: TextInputType.number),
                            const SizedBox(height: 40),
                            
                            // Add button
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _isSaving ? null : _saveEmployee,
                                style: ElevatedButton.styleFrom(
                                  foregroundColor: Colors.black,
                                  backgroundColor: const Color(0xFFD0F0C0),
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: _isSaving
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          color: Colors.black,
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Text('Add Employee'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
      ),
      extendBody: true,
      bottomNavigationBar: const DynamicFooter(),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {TextInputType keyboardType = TextInputType.text}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          style: const TextStyle(color: Color(0xFFEEEFEF)),
          decoration: InputDecoration(
            hintText: 'Enter $label',
            hintStyle: TextStyle(color: Colors.grey[600]),
            filled: true,
            fillColor: const Color(0xFF222222),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFD0F0C0), width: 1),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown({
    required String label, 
    required String value, 
    required List<String> items, 
    required Function(String?) onChanged
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF222222),
            borderRadius: BorderRadius.circular(10),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              onChanged: onChanged,
              items: items.map((item) {
                return DropdownMenuItem<String>(
                  value: item,
                  child: Text(
                    item,
                    style: const TextStyle(color: Color(0xFFEEEFEF)),
                  ),
                );
              }).toList(),
              dropdownColor: const Color(0xFF222222),
              icon: const Icon(Icons.arrow_drop_down, color: Color(0xFFD0F0C0)),
              isExpanded: true,
            ),
          ),
        ),
      ],
    );
  }
}
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:iconsax/iconsax.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tapeats/presentation/widgets/footer_widget.dart';
import 'package:tapeats/presentation/widgets/header_widget.dart';

class EditEmployeePage extends StatefulWidget {
  final String employeeId;
  
  const EditEmployeePage({
    super.key, 
    required this.employeeId
  });

  @override
  State<EditEmployeePage> createState() => _EditEmployeePageState();
}

class _EditEmployeePageState extends State<EditEmployeePage> {
  final SupabaseClient supabase = Supabase.instance.client;
  final TextEditingController _firstnameController = TextEditingController();
  final TextEditingController _lastnameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _contactController = TextEditingController();
  final TextEditingController _salaryController = TextEditingController();
  
  final List<String> _availableRoles = ['Manager', 'Chef', 'Waiter', 'Helper'];
  final List<String> _selectedRoles = [];
  
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _fetchEmployeeData();
  }

  @override
  void dispose() {
    _firstnameController.dispose();
    _lastnameController.dispose();
    _ageController.dispose();
    _contactController.dispose();
    _salaryController.dispose();
    super.dispose();
  }

  Future<void> _fetchEmployeeData() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final response = await supabase
          .from('employees')
          .select('first_name, last_name, age, contact_number, salary, role')
          .eq('employee_id', widget.employeeId)
          .single();
      
      if (mounted) {
        setState(() {
          _firstnameController.text = response['first_name'] ?? '';
          _lastnameController.text = response['last_name'] ?? '';
          _ageController.text = response['age']?.toString() ?? '';
          _contactController.text = response['contact_number']?.toString() ?? '';
          _salaryController.text = response['salary']?.toString() ?? '';
          
          // Fix for the error: handle role as a string instead of a list
          if (response['role'] != null) {
            _selectedRoles.clear();
            // Add the single role value
            _selectedRoles.add(response['role'] as String);
          }
          
          _isLoading = false;
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching employee data: $e');
      }
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading employee data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
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
        // Use the first selected role (since database stores as a single string)
        'role': _selectedRoles.isNotEmpty ? _selectedRoles.first : '',
      };
      
      await supabase
          .from('employees')
          .update(employeeData)
          .eq('employee_id', widget.employeeId);
      
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
            content: Text('Error saving employee data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteEmployee() async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF222222),
        title: const Text(
          'Delete Employee',
          style: TextStyle(color: Color(0xFFEEEFEF)),
        ),
        content: const Text(
          'Are you sure you want to delete this employee? This action cannot be undone.',
          style: TextStyle(color: Color(0xFFEEEFEF)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Color(0xFFD0F0C0)),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              backgroundColor: Colors.red.withOpacity(0.2),
            ),
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
    
    if (confirmed != true) {
      return;
    }
    
    try {
      setState(() {
        _isSaving = true;
      });
      
      await supabase
          .from('employees')
          .delete()
          .eq('employee_id', widget.employeeId);
      
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
        
        Navigator.pop(context, true); // Return true to trigger refresh
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting employee: $e');
      }
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting employee: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _toggleRole(String role) {
    setState(() {
      // Make sure only one role is selected at a time
      _selectedRoles.clear();
      _selectedRoles.add(role);
    });
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
                    headingText: 'Edit Employee',
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
                            
                            Text(
                              "${_firstnameController.text} ${_lastnameController.text}",
                              style: const TextStyle(
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
                            _buildTextField("Age", _ageController, keyboardType: TextInputType.number),
                            const SizedBox(height: 16),
                            _buildTextField("Contact number", _contactController, keyboardType: TextInputType.phone),
                            const SizedBox(height: 16),
                            _buildTextField("Salary", _salaryController, keyboardType: TextInputType.number),
                            const SizedBox(height: 24),
                            
                            // Roles section
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                "Role:",
                                style: TextStyle(
                                  color: Colors.grey[400],
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _availableRoles.map((role) {
                                final isSelected = _selectedRoles.contains(role);
                                return GestureDetector(
                                  onTap: () => _toggleRole(role),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: isSelected ? const Color(0xFF222222) : Colors.transparent,
                                      border: Border.all(
                                        color: isSelected ? const Color(0xFFD0F0C0) : Colors.grey,
                                        width: 1,
                                      ),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      role,
                                      style: TextStyle(
                                        color: isSelected ? const Color(0xFFD0F0C0) : Colors.grey,
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                            
                            const SizedBox(height: 40),
                            
                            // Save button
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: _isSaving ? null : _deleteEmployee,
                                    style: ElevatedButton.styleFrom(
                                      foregroundColor: Colors.white,
                                      backgroundColor: Colors.red.withOpacity(0.2),
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
                                              color: Colors.white,
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : const Text('Delete'),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  flex: 2,
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
                                        : const Text('Save Changes'),
                                  ),
                                ),
                              ],
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
}
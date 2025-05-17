import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:iconsax/iconsax.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tapeats/presentation/widgets/footer_widget.dart';
import 'package:tapeats/presentation/widgets/header_widget.dart';
import 'package:tapeats/presentation/screens/restaurant_side/edit_employee_page.dart';
import 'package:tapeats/presentation/screens/restaurant_side/add_employee_page.dart';

class EmployeeManagementPage extends StatefulWidget {
  final int selectedIndex;
  
  const EmployeeManagementPage({
    super.key, 
    required this.selectedIndex
  });

  @override
  State<EmployeeManagementPage> createState() => _EmployeeManagementPageState();
}

class _EmployeeManagementPageState extends State<EmployeeManagementPage> {
  final SupabaseClient supabase = Supabase.instance.client;
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> employees = [];
  List<Map<String, dynamic>> filteredEmployees = [];
  String selectedFilter = 'All';
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchEmployees();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchEmployees() async {
    try {
      setState(() {
        isLoading = true;
      });

      final response = await supabase
          .from('employees')
          .select('employee_id, first_name, role, salary');
      
      if (mounted) {
        setState(() {
          employees = List<Map<String, dynamic>>.from(response);
          filteredEmployees = List<Map<String, dynamic>>.from(response);
          isLoading = false;
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching employees: $e');
      }
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  void _filterEmployees(String query) {
    setState(() {
      if (query.isEmpty && selectedFilter == 'All') {
        filteredEmployees = employees;
      } else {
        filteredEmployees = employees.where((employee) {
          final nameMatches = employee['first_name'].toString().toLowerCase().contains(query.toLowerCase());
          final roleMatches = selectedFilter == 'All' || employee['role'] == selectedFilter;
          return nameMatches && roleMatches;
        }).toList();
      }
    });
  }

  void _selectFilter(String filter) {
    setState(() {
      selectedFilter = filter;
      _filterEmployees(_searchController.text);
    });
  }

  void _navigateToAddEmployee() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddEmployeePage(),
      ),
    );
    
    if (result == true) {
      _fetchEmployees();
    }
  }

  void _navigateToEditEmployee(Map<String, dynamic> employee) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditEmployeePage(
          employeeId: employee['employee_id'],
        ),
      ),
    );
    
    if (result == true) {
      _fetchEmployees();
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    return Scaffold(
      backgroundColor: const Color(0xFF151611),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            HeaderWidget(
              leftIcon: Iconsax.arrow_left_1,
              onLeftButtonPressed: () => Navigator.pop(context),
              headingText: 'Employee',
              rightIcon: Iconsax.menu_1,
              onRightButtonPressed: () {},
            ),
            const SizedBox(height: 20),
            
            // Search bar and add button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1A1A),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      child: Row(
                        children: [
                          const Icon(
                            Iconsax.search_normal,
                            color: Color(0xFFD0F0C0),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              style: const TextStyle(
                                color: Color(0xFFEEEFEF),
                                fontFamily: 'Helvetica Neue',
                                fontSize: 16,
                              ),
                              decoration: const InputDecoration(
                                hintText: 'Find Employee',
                                hintStyle: TextStyle(
                                  color: Color(0xFFEEEFEF),
                                  fontFamily: 'Helvetica Neue',
                                  fontWeight: FontWeight.w300,
                                ),
                                border: InputBorder.none,
                              ),
                              onChanged: _filterEmployees,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFD0F0C0),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.add),
                      color: Colors.black,
                      onPressed: _navigateToAddEmployee,
                      tooltip: 'Add Employee',
                    ),
                  ),
                ],
              ),
            ),
            
            // Role filter tabs
            const SizedBox(height: 20),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Row(
                children: [
                  _buildFilterButton('All'),
                  const SizedBox(width: 10),
                  _buildFilterButton('Manager'),
                  const SizedBox(width: 10),
                  _buildFilterButton('Chef'),
                  const SizedBox(width: 10),
                  _buildFilterButton('Waiter'),
                  const SizedBox(width: 10),
                  _buildFilterButton('Helper'),
                ],
              ),
            ),
            
            // Employees list
            const SizedBox(height: 20),
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFFD0F0C0)))
                  : filteredEmployees.isEmpty
                      ? const Center(
                          child: Text(
                            'No employees found',
                            style: TextStyle(color: Color(0xFFEEEFEF)),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 20.0),
                          itemCount: filteredEmployees.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 16),
                          itemBuilder: (context, index) {
                            final employee = filteredEmployees[index];
                            return _buildEmployeeCard(employee);
                          },
                        ),
            ),
          ],
        ),
      ),
      extendBody: true,
      bottomNavigationBar: const DynamicFooter(),
    );
  }

  Widget _buildFilterButton(String title) {
    final isSelected = selectedFilter == title;
    
    return GestureDetector(
      onTap: () => _selectFilter(title),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF222222) : const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isSelected ? const Color(0xFFD0F0C0) : const Color(0xFFEEEFEF),
            fontFamily: 'Helvetica Neue',
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildEmployeeCard(Map<String, dynamic> employee) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          // Avatar/Image
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.grey[800],
            backgroundImage: NetworkImage(
              'https://via.placeholder.com/60', // Replace with actual employee image
            ),
          ),
          const SizedBox(width: 16),
          
          // Employee details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  employee['first_name'] ?? 'Unknown',
                  style: const TextStyle(
                    color: Color(0xFFEEEFEF),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '\$${employee['salary']?.toStringAsFixed(2) ?? '0.00'}',
                  style: const TextStyle(
                    color: Color(0xFFD0F0C0),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          
          // Edit button
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFD0F0C0).withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: InkWell(
              onTap: () => _navigateToEditEmployee(employee),
              child: Row(
                children: [
                  const Text(
                    'Edit',
                    style: TextStyle(
                      color: Color(0xFFD0F0C0),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.edit,
                    color: Color(0xFFD0F0C0),
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

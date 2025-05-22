import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tapeats/presentation/widgets/header_widget.dart';

class TableManagementScreen extends StatefulWidget {

  const TableManagementScreen({
    super.key,
  });

  @override
  State<TableManagementScreen> createState() => _TableManagementScreenState();
}

class _TableManagementScreenState extends State<TableManagementScreen> {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> tables = [];
  bool isLoading = true;
  String? restaurantId;
  String? currentUserId;

  @override
  void initState() {
    super.initState();
    _fetchCurrentUserAndTables();
  }

  Future<void> _fetchCurrentUserAndTables() async {
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
          await _fetchRestaurantTables(restaurantId!);
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

  Future<void> _fetchRestaurantTables(String restaurantId) async {
    try {
      final data = await supabase
          .from('restaurant_tables')
          .select()
          .eq('restaurant_id', restaurantId)
          .order('table_number');

      setState(() {
        tables = List<Map<String, dynamic>>.from(data);
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error fetching tables: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _addNewTable() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditTableScreen(
          restaurantId: restaurantId!,
          onSave: (newTable) async {
            try {
              final response = await supabase
                  .from('restaurant_tables')
                  .insert(newTable)
                  .select()
                  .single();

              setState(() {
                tables.add(Map<String, dynamic>.from(response));
              });
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error adding table: $e'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
        ),
      ),
    );
  }

  void _editTable(int index) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditTableScreen(
          restaurantId: restaurantId!,
          table: tables[index],
          onSave: (updatedTable) async {
            try {
              await supabase
                  .from('restaurant_tables')
                  .update(updatedTable)
                  .eq('table_id', updatedTable['table_id']);

              setState(() {
                tables[index] = updatedTable;
              });
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error updating table: $e'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
        ),
      ),
    );
  }

  Future<void> _deleteTable(int index) async {
    final tableId = tables[index]['table_id'];
    try {
      await supabase.from('restaurant_tables').delete().eq('table_id', tableId);
      setState(() {
        tables.removeAt(index);
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting table: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _toggleReservationStatus(int index) async {
    final tableId = tables[index]['table_id'];
    final currentStatus = tables[index]['is_reserved'];

    try {
      await supabase
          .from('restaurant_tables')
          .update({'is_reserved': !currentStatus}).eq('table_id', tableId);

      setState(() {
        tables[index]['is_reserved'] = !currentStatus;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating reservation status: $e'),
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
                headingText: "Manage Tables",
                rightIcon: Iconsax.add,
                onRightButtonPressed:
                    restaurantId != null ? () => _addNewTable() : () {},
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
                      : tables.isEmpty
                          ? Center(
                              child: Text(
                                'No tables found',
                                style: TextStyle(color: Color(0xFFD0F0C0)),
                              ),
                            )
                          : GridView.builder(
                              padding: const EdgeInsets.all(16),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                                childAspectRatio: 1.0,
                              ),
                              itemCount: tables.length,
                              itemBuilder: (context, index) {
                                final table = tables[index];
                                return GestureDetector(
                                  onTap: () => _editTable(index),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: table['is_reserved']
                                          ? const Color(0xFF442222)
                                          : const Color(0xFF1A1A1A),
                                      borderRadius: BorderRadius.circular(15),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withAlpha(51),
                                          blurRadius: 10,
                                          spreadRadius: 2,
                                        ),
                                      ],
                                      border: Border.all(
                                        color: table['is_reserved']
                                            ? Colors.red
                                            : const Color(0xFFD0F0C0),
                                        width: 2,
                                      ),
                                    ),
                                    child: Stack(
                                      children: [
                                        Center(
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                'Table ${table['table_number']}',
                                                style: const TextStyle(
                                                  color: Color(0xFFEEEFEF),
                                                  fontSize: 24,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              Text(
                                                'Seats: ${table['seating_capacity']}',
                                                style: const TextStyle(
                                                  color: Color(0xFFD0F0C0),
                                                  fontSize: 16,
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              Text(
                                                table['is_reserved']
                                                    ? 'RESERVED'
                                                    : 'AVAILABLE',
                                                style: TextStyle(
                                                  color: table['is_reserved']
                                                      ? Colors.red
                                                      : const Color(0xFFD0F0C0),
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Positioned(
                                          top: 8,
                                          right: 8,
                                          child: IconButton(
                                            icon: Icon(
                                              table['is_reserved']
                                                  ? Iconsax.reserve
                                                  : Iconsax.tick_circle,
                                              color: table['is_reserved']
                                                  ? Colors.red
                                                  : const Color(0xFFD0F0C0),
                                            ),
                                            onPressed: () =>
                                                _toggleReservationStatus(index),
                                          ),
                                        ),
                                        Positioned(
                                          bottom: 8,
                                          right: 8,
                                          child: IconButton(
                                            icon: const Icon(
                                              Iconsax.trash,
                                              color: Colors.red,
                                            ),
                                            onPressed: () =>
                                                _deleteTable(index),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
            ),
          ],
        ),
      ),
    );
  }
}

class AddEditTableScreen extends StatefulWidget {
  final String restaurantId;
  final Map<String, dynamic>? table;
  final Function(Map<String, dynamic>) onSave;

  const AddEditTableScreen({
    super.key,
    required this.restaurantId,
    this.table,
    required this.onSave,
  });

  @override
  State<AddEditTableScreen> createState() => _AddEditTableScreenState();
}

class _AddEditTableScreenState extends State<AddEditTableScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _tableNumberController;
  late TextEditingController _seatingCapacityController;
  late bool _isReserved;

  @override
  void initState() {
    super.initState();
    _tableNumberController = TextEditingController(
        text: widget.table?['table_number']?.toString() ?? '');
    _seatingCapacityController = TextEditingController(
        text: widget.table?['seating_capacity']?.toString() ?? '');
    _isReserved = widget.table?['is_reserved'] ?? false;
  }

  @override
  void dispose() {
    _tableNumberController.dispose();
    _seatingCapacityController.dispose();
    super.dispose();
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
                headingText: widget.table == null ? 'Add Table' : 'Edit Table',
                rightIcon: Iconsax.tick_circle,
                onRightButtonPressed: _saveTable,
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
                      TextFormField(
                        controller: _tableNumberController,
                        style: const TextStyle(color: Color(0xFFEEEFEF)),
                        decoration: InputDecoration(
                          labelText: 'Table Number',
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
                        controller: _seatingCapacityController,
                        style: const TextStyle(color: Color(0xFFEEEFEF)),
                        decoration: InputDecoration(
                          labelText: 'Seating Capacity',
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
                      SwitchListTile(
                        title: Text(
                          'Reserved Status',
                          style: TextStyle(color: Color(0xFFEEEFEF)),
                        ),
                        activeColor: const Color(0xFFD0F0C0),
                        value: _isReserved,
                        onChanged: (value) {
                          setState(() {
                            _isReserved = value;
                          });
                        },
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

  void _saveTable() {
    if (_formKey.currentState?.validate() ?? false) {
      final newTable = {
        if (widget.table != null) 'table_id': widget.table!['table_id'],
        'restaurant_id': widget.restaurantId,
        'table_number': int.parse(_tableNumberController.text),
        'seating_capacity': int.parse(_seatingCapacityController.text),
        'is_reserved': _isReserved,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      widget.onSave(newTable);
      Navigator.pop(context);
    }
  }
}

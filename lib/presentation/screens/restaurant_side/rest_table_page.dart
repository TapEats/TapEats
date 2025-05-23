import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tapeats/presentation/widgets/header_widget.dart';

class TableManagementScreen extends StatefulWidget {
  const TableManagementScreen({super.key});

  @override
  State<TableManagementScreen> createState() => _TableManagementScreenState();
}

class _TableManagementScreenState extends State<TableManagementScreen> {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> tables = [];
  bool isLoading = true;
  String? restaurantId;
  String? currentUserId;
  late final RealtimeChannel _tableChannel;

  @override
  void initState() {
    super.initState();
    _tableChannel = supabase.channel('table_changes');
    _fetchCurrentUserAndTables();
  }

  @override
  void dispose() {
    _tableChannel.unsubscribe();
    super.dispose();
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

      if (['restaurant_owner', 'restaurant_waiter', 'restaurant_manager']
          .contains(userData['role'])) {
        restaurantId = userData['restaurant_id'];
        if (restaurantId != null) {
          await _fetchRestaurantTables(restaurantId!);
          _setupRealtimeSubscription();
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

  void _setupRealtimeSubscription() {
    _tableChannel
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'restaurant_tables',
          callback: (payload) => _handleTableUpdate(payload),
        )
        .subscribe();
  }

  void _handleTableUpdate(PostgresChangePayload payload) {
    if (payload.oldRecord['restaurant_id'] != restaurantId) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _fetchRestaurantTables(restaurantId!);
      }
    });
  }

  String _getTableStatus(Map<String, dynamic> table) {
    if (table['is_prebooked'] == true) return 'reserved';
    if (table['is_reserved'] == true) return 'occupied';
    return 'available';
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'reserved':
        return const Color(0xFF442222);
      case 'occupied':
        return const Color(0xFF332F22);
      default:
        return const Color(0xFF1A1A1A);
    }
  }

  Color _getStatusTextColor(String status) {
    switch (status) {
      case 'reserved':
        return Colors.red;
      case 'occupied':
        return const Color(0xFFFFA726);
      default:
        return const Color(0xFFD0F0C0);
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'reserved':
        return Iconsax.reserve;
      case 'occupied':
        return Iconsax.user;
      default:
        return Iconsax.tick_circle;
    }
  }

  Future<void> _toggleTableStatus(int index) async {
    final table = tables[index];
    final currentStatus = _getTableStatus(table);
    Map<String, dynamic> updates = {};

    switch (currentStatus) {
      case 'available':
        updates = {'is_reserved': true, 'is_prebooked': false};
        break;
      case 'occupied':
        updates = {'is_reserved': false, 'is_prebooked': true};
        break;
      case 'reserved':
        updates = {'is_reserved': false, 'is_prebooked': false};
        break;
    }

    try {
      await supabase
          .from('restaurant_tables')
          .update(updates)
          .eq('table_id', table['table_id']);

      setState(() {
        tables[index].addAll(updates);
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating status: $e'),
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
                                final status = _getTableStatus(table);
                                return GestureDetector(
                                  onTap: () => _editTable(index),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: _getStatusColor(status),
                                      borderRadius: BorderRadius.circular(15),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withAlpha(51),
                                          blurRadius: 10,
                                          spreadRadius: 2,
                                        ),
                                      ],
                                      border: Border.all(
                                        color: _getStatusTextColor(status),
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
                                                status.toUpperCase(),
                                                style: TextStyle(
                                                  color: _getStatusTextColor(
                                                      status),
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
                                              _getStatusIcon(status),
                                              color:
                                                  _getStatusTextColor(status),
                                            ),
                                            onPressed: () =>
                                                _toggleTableStatus(index),
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
  late String _selectedStatus;

  @override
  void initState() {
    super.initState();
    _tableNumberController = TextEditingController(
        text: widget.table?['table_number']?.toString() ?? '');
    _seatingCapacityController = TextEditingController(
        text: widget.table?['seating_capacity']?.toString() ?? '');
    _selectedStatus = _getInitialStatus();
  }

  String _getInitialStatus() {
    if (widget.table == null) return 'available';
    if (widget.table!['is_prebooked'] == true) return 'reserved';
    if (widget.table!['is_reserved'] == true) return 'occupied';
    return 'available';
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'reserved':
        return Colors.red;
      case 'occupied':
        return const Color(0xFFFFA726);
      default:
        return const Color(0xFFD0F0C0);
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
                      DropdownButtonFormField<String>(
                        value: _selectedStatus,
                        dropdownColor: const Color(0xFF222222),
                        style: const TextStyle(color: Color(0xFFEEEFEF)),
                        items: ['available', 'occupied', 'reserved']
                            .map((status) => DropdownMenuItem(
                                  value: status,
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 10,
                                        height: 10,
                                        decoration: BoxDecoration(
                                          color: _getStatusColor(status),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        status.toUpperCase(),
                                        style: TextStyle(
                                            color: _getStatusColor(status)),
                                      ),
                                    ],
                                  ),
                                ))
                            .toList(),
                        onChanged: (value) =>
                            setState(() => _selectedStatus = value!),
                        decoration: InputDecoration(
                          labelText: 'Table Status',
                          labelStyle: const TextStyle(color: Color(0xFFD0F0C0)),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
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
    );
  }

  void _saveTable() {
    if (_formKey.currentState?.validate() ?? false) {
      final newTable = {
        if (widget.table != null) 'table_id': widget.table!['table_id'],
        'restaurant_id': widget.restaurantId,
        'table_number': int.parse(_tableNumberController.text),
        'seating_capacity': int.parse(_seatingCapacityController.text),
        'is_reserved': _selectedStatus == 'occupied',
        'is_prebooked': _selectedStatus == 'reserved',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      widget.onSave(newTable);
      Navigator.pop(context);
    }
  }
}

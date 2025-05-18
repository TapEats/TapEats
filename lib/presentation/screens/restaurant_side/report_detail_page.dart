import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:tapeats/presentation/widgets/footer_widget.dart';
import 'package:tapeats/presentation/widgets/header_widget.dart';
import 'package:tapeats/presentation/widgets/sidemenu_overlay.dart';

class DetailedReportPage extends StatefulWidget {
  final String reportType;
  final String reportTitle;
  final Map<String, dynamic> reportData;

  const DetailedReportPage({
    super.key,
    required this.reportType,
    required this.reportTitle,
    required this.reportData,
  });

  @override
  State<DetailedReportPage> createState() => _DetailedReportPageState();
}

class _DetailedReportPageState extends State<DetailedReportPage> {
  // Theme colors
  final Color _bgColor = const Color(0xFF151611);     // Background
  final Color _secondaryColor = const Color(0xFF222222); // Secondary
  final Color _accentColor = const Color(0xFFD0F0C0);  // Accent
  final Color _textColor = const Color(0xFFEEEFEF);   // Text
  
  // Filter values
  String _selectedTimeframe = 'monthly';
  String _selectedFormat = 'pdf';
  
  @override
  void initState() {
    super.initState();
  }

  void _openSideMenu() {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        pageBuilder: (_, __, ___) => const RoleBasedSideMenu(),
      ),
    );
  }

  void _downloadReport() {
    // Show download started message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Downloading ${widget.reportTitle} as ${_selectedFormat.toUpperCase()}...'),
        backgroundColor: _accentColor.withOpacity(0.8),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        action: SnackBarAction(
          label: 'Cancel',
          textColor: Colors.black,
          onPressed: () {
            // Cancel download action
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Section
            HeaderWidget(
              leftIcon: Iconsax.arrow_left_1,
              onLeftButtonPressed: () => Navigator.pop(context),
              headingText: widget.reportTitle,
              headingIcon: _getIconForReportType(widget.reportType),
              rightIcon: Iconsax.menu_1,
              onRightButtonPressed: _openSideMenu,
            ),
            
            // Main content - Scrollable
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Filter Section
                    Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: _buildFilterSection(),
                    ),
                    
                    // Report Content
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: _buildReportContent(),
                    ),
                    
                    // Download Button
                    Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: _buildDownloadButton(),
                    ),
                    
                    const SizedBox(height: 80), // Space for bottom bar
                  ],
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

  IconData _getIconForReportType(String type) {
    switch (type) {
      case 'sales':
        return Iconsax.chart;
      case 'inventory':
        return Iconsax.box;
      case 'menu':
        return Iconsax.book_1;
      case 'payroll':
        return Iconsax.money;
      case 'deals':
        return Iconsax.tag;
      case 'crm':
        return Iconsax.user;
      case 'iwt':
        return Iconsax.trash;
      default:
        return Iconsax.document;
    }
  }

  Widget _buildFilterSection() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: _secondaryColor,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Report Filters',
            style: TextStyle(
              color: _textColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Timeframe',
                      style: TextStyle(
                        color: _textColor.withOpacity(0.7),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildDropdown(
                      value: _selectedTimeframe,
                      items: const [
                        DropdownMenuItem(value: 'daily', child: Text('Daily')),
                        DropdownMenuItem(value: 'weekly', child: Text('Weekly')),
                        DropdownMenuItem(value: 'monthly', child: Text('Monthly')),
                        DropdownMenuItem(value: 'quarterly', child: Text('Quarterly')),
                        DropdownMenuItem(value: 'yearly', child: Text('Yearly')),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _selectedTimeframe = value;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Format',
                      style: TextStyle(
                        color: _textColor.withOpacity(0.7),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildDropdown(
                      value: _selectedFormat,
                      items: const [
                        DropdownMenuItem(value: 'pdf', child: Text('PDF')),
                        DropdownMenuItem(value: 'excel', child: Text('Excel')),
                        DropdownMenuItem(value: 'csv', child: Text('CSV')),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _selectedFormat = value;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          _buildDateRangePicker(),
        ],
      ),
    );
  }

  Widget _buildDropdown({
    required String value,
    required List<DropdownMenuItem<String>> items,
    required Function(String?) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: _bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _accentColor.withOpacity(0.3)),
      ),
      child: DropdownButton<String>(
        value: value,
        items: items,
        onChanged: onChanged,
        isExpanded: true,
        underline: const SizedBox(),
        dropdownColor: _bgColor,
        style: TextStyle(
          color: _textColor,
          fontSize: 14,
        ),
        icon: Icon(
          Iconsax.arrow_down_1,
          color: _accentColor,
          size: 16,
        ),
      ),
    );
  }

  Widget _buildDateRangePicker() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Start Date',
                style: TextStyle(
                  color: _textColor.withOpacity(0.7),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () {
                  // Show date picker
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  decoration: BoxDecoration(
                    color: _bgColor,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _accentColor.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '01/04/2025',
                        style: TextStyle(
                          color: _textColor,
                          fontSize: 14,
                        ),
                      ),
                      Icon(
                        Iconsax.calendar,
                        color: _accentColor,
                        size: 16,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'End Date',
                style: TextStyle(
                  color: _textColor.withOpacity(0.7),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () {
                  // Show date picker
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  decoration: BoxDecoration(
                    color: _bgColor,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _accentColor.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '30/04/2025',
                        style: TextStyle(
                          color: _textColor,
                          fontSize: 14,
                        ),
                      ),
                      Icon(
                        Iconsax.calendar,
                        color: _accentColor,
                        size: 16,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReportContent() {
    // Customize this based on the report type
    if (widget.reportType == 'sales') {
      return _buildSalesReportContent();
    } else if (widget.reportType == 'inventory') {
      return _buildInventoryReportContent();
    } else if (widget.reportType == 'menu') {
      return _buildMenuReportContent();
    } else {
      return _buildGenericReportContent();
    }
  }

  Widget _buildSalesReportContent() {
    // Sample sales metrics
    final salesMetrics = [
      {'name': 'Total Revenue', 'value': '\$12,456.78', 'change': '+15%', 'icon': Iconsax.money_recive},
      {'name': 'Average Order Value', 'value': '\$28.45', 'change': '+5%', 'icon': Iconsax.chart_2},
      {'name': 'Number of Orders', 'value': '438', 'change': '+12%', 'icon': Iconsax.clipboard_text},
      {'name': 'Highest Sale Day', 'value': 'Saturday', 'change': '', 'icon': Iconsax.calendar},
    ];
    
    // Sample top selling items
    final topSellingItems = [
      {'name': 'Italian Pizza', 'quantity': 156, 'revenue': '\$2,340.00'},
      {'name': 'Caesar Salad', 'quantity': 98, 'revenue': '\$970.20'},
      {'name': 'Chicken Burger', 'quantity': 85, 'revenue': '\$892.50'},
      {'name': 'Pasta Carbonara', 'quantity': 72, 'revenue': '\$864.00'},
      {'name': 'Chocolate Cake', 'quantity': 65, 'revenue': '\$455.00'},
    ];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Sales Metrics Grid
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.5,
          crossAxisSpacing: 15,
          mainAxisSpacing: 15,
          children: salesMetrics.map((metric) => _buildMetricCard(metric)).toList(),
        ),
        const SizedBox(height: 20),
        
        // Top Selling Items
        Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: _secondaryColor,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Iconsax.chart_success,
                    color: _accentColor,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Top Selling Items',
                    style: TextStyle(
                      color: _textColor,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              // Headers
              Row(
                children: [
                  Expanded(
                    flex: 5,
                    child: Text(
                      'Item',
                      style: TextStyle(
                        color: _textColor.withOpacity(0.7),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      'Qty',
                      style: TextStyle(
                        color: _textColor.withOpacity(0.7),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      'Revenue',
                      style: TextStyle(
                        color: _textColor.withOpacity(0.7),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
              ),
              const Divider(height: 20, color: Color(0xFF333333)),
              // Items
              ...topSellingItems.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Row(
                  children: [
                    Expanded(
                      flex: 5,
                      child: Text(
                        item['name'] as String,
                        style: TextStyle(
                          color: _textColor,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        item['quantity'].toString(),
                        style: TextStyle(
                          color: _textColor,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(
                        item['revenue'] as String,
                        style: TextStyle(
                          color: _accentColor,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ],
                ),
              )),
            ],
          ),
        ),
        const SizedBox(height: 20),
        
        // Sales by Time Period
        Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: _secondaryColor,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Iconsax.timer,
                    color: _accentColor,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Sales by Time of Day',
                    style: TextStyle(
                      color: _textColor,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              // Simple chart representation
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildTimeBar('Morning', 35, '35%'),
                  _buildTimeBar('Afternoon', 45, '45%'),
                  _buildTimeBar('Evening', 85, '85%'),
                  _buildTimeBar('Night', 25, '25%'),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInventoryReportContent() {
    // Sample inventory metrics
    final inventoryMetrics = [
      {'name': 'Total Items', 'value': '248', 'change': '+5', 'icon': Iconsax.box},
      {'name': 'Low Stock Items', 'value': '12', 'change': '-3', 'icon': Iconsax.warning_2},
      {'name': 'Out of Stock', 'value': '3', 'change': '-1', 'icon': Iconsax.box_remove},
      {'name': 'Value of Inventory', 'value': '\$8,945.60', 'change': '+\$345', 'icon': Iconsax.money},
    ];
    
    // Sample inventory items
    final inventoryItems = [
      {'name': 'Tomatoes', 'quantity': '12 kg', 'status': 'In Stock', 'statusColor': Colors.green},
      {'name': 'Chicken Breast', 'quantity': '5 kg', 'status': 'Low Stock', 'statusColor': Colors.orange},
      {'name': 'Mozzarella Cheese', 'quantity': '8 kg', 'status': 'In Stock', 'statusColor': Colors.green},
      {'name': 'Olive Oil', 'quantity': '2 bottles', 'status': 'Low Stock', 'statusColor': Colors.orange},
      {'name': 'Basil Leaves', 'quantity': '0 bunches', 'status': 'Out of Stock', 'statusColor': Colors.red},
    ];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Inventory Metrics Grid
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.5,
          crossAxisSpacing: 15,
          mainAxisSpacing: 15,
          children: inventoryMetrics.map((metric) => _buildMetricCard(metric)).toList(),
        ),
        const SizedBox(height: 20),
        
        // Inventory Items
        Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: _secondaryColor,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Iconsax.box,
                    color: _accentColor,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Inventory Status',
                    style: TextStyle(
                      color: _textColor,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              // Headers
              Row(
                children: [
                  Expanded(
                    flex: 4,
                    child: Text(
                      'Item',
                      style: TextStyle(
                        color: _textColor.withOpacity(0.7),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      'Quantity',
                      style: TextStyle(
                        color: _textColor.withOpacity(0.7),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      'Status',
                      style: TextStyle(
                        color: _textColor.withOpacity(0.7),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
              ),
              const Divider(height: 20, color: Color(0xFF333333)),
              // Items
              ...inventoryItems.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Row(
                  children: [
                    Expanded(
                      flex: 4,
                      child: Text(
                        item['name'] as String,
                        style: TextStyle(
                          color: _textColor,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(
                        item['quantity'] as String,
                        style: TextStyle(
                          color: _textColor,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _bgColor,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          item['status'] as String,
                          style: TextStyle(
                            color: item['statusColor'] as Color,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMenuReportContent() {
    // Sample menu metrics
    final menuMetrics = [
      {'name': 'Total Menu Items', 'value': '42', 'change': '+3', 'icon': Iconsax.book_1},
      {'name': 'Popular Category', 'value': 'Pizza', 'change': '', 'icon': Iconsax.star},
      {'name': 'Least Ordered', 'value': 'Salads', 'change': '', 'icon': Iconsax.chart_fail},
      {'name': 'Menu Changes', 'value': '5', 'change': '+2', 'icon': Iconsax.edit},
    ];
    
    // Sample category performance
    final categoryPerformance = [
      {'name': 'Pizza', 'orders': 425, 'revenue': '\$5,950'},
      {'name': 'Pasta', 'orders': 310, 'revenue': '\$3,720'},
      {'name': 'Burgers', 'orders': 285, 'revenue': '\$2,850'},
      {'name': 'Desserts', 'orders': 220, 'revenue': '\$1,540'},
      {'name': 'Salads', 'orders': 120, 'revenue': '\$960'},
    ];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Menu Metrics Grid
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.5,
          crossAxisSpacing: 15,
          mainAxisSpacing: 15,
          children: menuMetrics.map((metric) => _buildMetricCard(metric)).toList(),
        ),
        const SizedBox(height: 20),
        
        // Category Performance
        Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: _secondaryColor,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Iconsax.category,
                    color: _accentColor,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Category Performance',
                    style: TextStyle(
                      color: _textColor,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              // Headers
              Row(
                children: [
                  Expanded(
                    flex: 4,
                    child: Text(
                      'Category',
                      style: TextStyle(
                        color: _textColor.withOpacity(0.7),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      'Orders',
                      style: TextStyle(
                        color: _textColor.withOpacity(0.7),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      'Revenue',
                      style: TextStyle(
                        color: _textColor.withOpacity(0.7),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
              ),
              const Divider(height: 20, color: Color(0xFF333333)),
              // Items
              ...categoryPerformance.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Row(
                  children: [
                    Expanded(
                      flex: 4,
                      child: Text(
                        item['name'] as String,
                        style: TextStyle(
                          color: _textColor,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(
                        item['orders'].toString(),
                        style: TextStyle(
                          color: _textColor,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(
                        item['revenue'] as String,
                        style: TextStyle(
                          color: _accentColor,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ],
                ),
              )),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGenericReportContent() {
    // Generic metrics based on report type
    final List<Map<String, dynamic>> metrics = [];
    
    switch (widget.reportType) {
      case 'payroll':
        metrics.addAll([
          {'name': 'Total Payroll', 'value': '\$24,680', 'change': '+2.5%', 'icon': Iconsax.money},
          {'name': 'Employees', 'value': '28', 'change': '+1', 'icon': Iconsax.user},
          {'name': 'Avg. Salary', 'value': '\$2,450', 'change': '+\$50', 'icon': Iconsax.money_recive},
          {'name': 'Overtime Hours', 'value': '145', 'change': '-12', 'icon': Iconsax.clock},
        ]);
        break;
      case 'deals':
        metrics.addAll([
          {'name': 'Active Deals', 'value': '8', 'change': '+2', 'icon': Iconsax.tag},
          {'name': 'Redemptions', 'value': '342', 'change': '+58', 'icon': Iconsax.tick_square},
          {'name': 'Avg. Discount', 'value': '15%', 'change': '', 'icon': Iconsax.percentage_circle},
          {'name': 'Deal Revenue', 'value': '\$4,820', 'change': '+\$680', 'icon': Iconsax.money_recive},
        ]);
        break;
      case 'crm':
        metrics.addAll([
          {'name': 'Total Customers', 'value': '29,301', 'change': '+845', 'icon': Iconsax.user},
          {'name': 'New Customers', 'value': '342', 'change': '+12%', 'icon': Iconsax.user_add},
          {'name': 'Loyalty Members', 'value': '8,456', 'change': '+248', 'icon': Iconsax.heart},
          {'name': 'Avg. Rating', 'value': '4.7/5', 'change': '+0.1', 'icon': Iconsax.star},
        ]);
        break;
      case 'iwt':
        metrics.addAll([
          {'name': 'Total Waste', 'value': '245kg', 'change': '-18kg', 'icon': Iconsax.trash},
          {'name': 'Food Waste', 'value': '142kg', 'change': '-12kg', 'icon': Iconsax.coffee},
          {'name': 'Recyclables', 'value': '78kg', 'change': '+4kg', 'icon': Iconsax.refresh},
          {'name': 'Waste Cost', 'value': '\$845', 'change': '-\$75', 'icon': Iconsax.money},
        ]);
        break;
      default:
        metrics.addAll([
          {'name': 'Metric 1', 'value': '125', 'change': '+5', 'icon': Iconsax.chart},
          {'name': 'Metric 2', 'value': '\$1,234', 'change': '+\$123', 'icon': Iconsax.money},
          {'name': 'Metric 3', 'value': '42%', 'change': '+3%', 'icon': Iconsax.percentage_circle},
          {'name': 'Metric 4', 'value': '365', 'change': '-12', 'icon': Iconsax.activity},
        ]);
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Metrics Grid
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.5,
          crossAxisSpacing: 15,
          mainAxisSpacing: 15,
          children: metrics.map((metric) => _buildMetricCard(metric)).toList(),
        ),
        const SizedBox(height: 20),
        
        // Note about detailed report
        Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: _secondaryColor,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _bgColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Iconsax.info_circle,
                  color: _accentColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Detailed Report',
                      style: TextStyle(
                        color: _textColor,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'For a more detailed analysis, download the complete report using the button below.',
                      style: TextStyle(
                        color: _textColor.withOpacity(0.7),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard(Map<String, dynamic> metric) {
    final bool hasChange = metric['change'] != null && metric['change'].toString().isNotEmpty;
    
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: _secondaryColor,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _bgColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  metric['icon'] as IconData,
                  color: _accentColor,
                  size: 16,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  metric['name'] as String,
                  style: TextStyle(
                    color: _textColor.withOpacity(0.7),
                    fontSize: 12,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            metric['value'] as String,
            style: TextStyle(
              color: _textColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (hasChange)
            Row(
              children: [
                Text(
                  metric['change'] as String,
                  style: TextStyle(
                    color: metric['change'].toString().startsWith('-') ? Colors.red : _accentColor,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildTimeBar(String time, double percentage, String label) {
    return Column(
      children: [
        Text(
          time,
          style: TextStyle(
            color: _textColor.withOpacity(0.7),
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: 30,
          height: 120,
          decoration: BoxDecoration(
            color: _bgColor,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                width: 30,
                height: percentage * 1.2,
                decoration: BoxDecoration(
                  color: _accentColor,
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: _accentColor,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildDownloadButton() {
    return ElevatedButton(
      onPressed: _downloadReport,
      style: ElevatedButton.styleFrom(
        backgroundColor: _accentColor,
        foregroundColor: Colors.black,
        padding: const EdgeInsets.symmetric(vertical: 15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        elevation: 0,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Iconsax.document_download,
            color: Colors.black,
            size: 20,
          ),
          const SizedBox(width: 10),
          Text(
            'Download ${_selectedFormat.toUpperCase()} Report',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

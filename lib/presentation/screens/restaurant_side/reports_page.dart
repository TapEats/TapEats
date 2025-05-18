import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:tapeats/presentation/widgets/footer_widget.dart';
import 'package:tapeats/presentation/widgets/header_widget.dart';
import 'package:tapeats/presentation/widgets/sidemenu_overlay.dart';
import 'package:tapeats/presentation/state_management/navbar_state.dart';
import 'package:intl/intl.dart';

// Chart data model
class ChartData {
  final String x;
  final double y;
  final Color color;

  ChartData(this.x, this.y, {this.color = const Color(0xFFD0F0C0)});
}

class ReportsPage extends StatefulWidget {

  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> with SingleTickerProviderStateMixin {
  // Theme colors
  final Color _bgColor = const Color(0xFF151611);     // Background
  final Color _secondaryColor = const Color(0xFF222222); // Secondary
  final Color _accentColor = const Color(0xFFD0F0C0);  // Accent
  final Color _textColor = const Color(0xFFEEEFEF);   // Text
  
  // Selected report type
  String _selectedReportType = 'sales';
  
  // Animation state
  bool _pageLoaded = false;
  late AnimationController _animationController;
  
  // Mock data for reports
  final Map<String, Map<String, dynamic>> _reportData = {
    'sales': {
      'title': 'Sales Report',
      'icon': Iconsax.chart,
      'value': '\$1,432,446,851',
      'chartData': [12.5, 18.3, 14.2, 16.8, 22.5, 19.2, 15.9],
      'months': ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul'],
    },
    'inventory': {
      'title': 'Inventory Report',
      'icon': Iconsax.box,
      'value': 'Full',
      'chartData': [8.2, 14.6, 11.5, 10.2, 9.8, 12.5, 13.1],
      'months': ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul'],
    },
    'menu': {
      'title': 'Menu Report',
      'icon': Iconsax.book_1,
      'value': 'Ok',
      'chartData': [10.5, 11.3, 9.2, 12.8, 14.5, 15.2, 13.9],
      'months': ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul'],
    },
    'payroll': {
      'title': 'Payroll Reports',
      'icon': Iconsax.money,
      'value': '\$630,423,918',
      'chartData': [22.5, 18.3, 17.2, 15.8, 14.5, 13.2, 12.9],
      'months': ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul'],
    },
    'deals': {
      'title': 'Deals Reports',
      'icon': Iconsax.tag,
      'value': '\$-203,132',
      'chartData': [5.5, 8.3, 7.2, 9.8, 12.5, 11.2, 10.9],
      'months': ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul'],
    },
    'crm': {
      'title': 'CRM Reports',
      'icon': Iconsax.user,
      'value': '+29301 Users',
      'chartData': [11.5, 13.3, 14.2, 15.8, 18.5, 19.2, 17.9],
      'months': ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul'],
    },
    'iwt': {
      'title': 'IWT Reports',
      'icon': Iconsax.trash,
      'value': '-245kg Waste',
      'chartData': [18.5, 16.3, 14.2, 13.8, 11.5, 9.2, 7.9],
      'months': ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul'],
    }
  };

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Update NavbarState index
      Provider.of<NavbarState>(context, listen: false);
      
      // Start animations
      _animationController.forward();
      if (mounted) {
        setState(() {
          _pageLoaded = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _openProfile() {
    // Profile navigation logic here
  }

  void _openSideMenu() {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        pageBuilder: (_, __, ___) => const RoleBasedSideMenu(),
      ),
    );
  }

  void _selectReport(String reportType) {
    setState(() {
      _selectedReportType = reportType;
    });
  }

  void _downloadReport(String reportType) {
    // Show download started message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Downloading ${_reportData[reportType]?['title']} PDF...'),
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
  
  void _openDetailedReport(String reportType) {
    // Navigate to detailed report page
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReportDetailPage(
          reportType: reportType,
          reportTitle: _reportData[reportType]?['title'] as String,
          reportData: _reportData[reportType] as Map<String, dynamic>,
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
              leftIcon: Iconsax.user,
              onLeftButtonPressed: _openProfile,
              headingText: 'Reports',
              headingIcon: Iconsax.chart_success,
              rightIcon: Iconsax.menu_1,
              onRightButtonPressed: _openSideMenu,
            ),
            
            // Main content - Scrollable
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: AnimatedOpacity(
                  opacity: _pageLoaded ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeOut,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Sales Performance Chart Section
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                        child: _buildPerformanceSection(),
                      ),
                      
                      // Select Report Section
                      Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: _buildReportSelectionSection(),
                      ),
                      
                      const SizedBox(height: 80), // Space for bottom bar
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

  Widget _buildPerformanceSection() {
    // Get data for the selected report
    final reportData = _reportData[_selectedReportType]!;
    final List<double> chartData = List<double>.from(reportData['chartData']);
    final List<String> months = List<String>.from(reportData['months']);
    
    // Convert to chart data format
    final List<ChartData> data = List.generate(
      chartData.length,
      (index) => ChartData(
        months[index],
        chartData[index],
      ),
    );
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${reportData['title']} Performance',
          style: TextStyle(
            color: _textColor,
            fontSize: 22,
            fontWeight: FontWeight.bold,
            fontFamily: 'Helvetica Neue',
          ),
        ),
        const SizedBox(height: 20),
        Container(
          height: 240,
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: _secondaryColor,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Column(
            children: [
              Expanded(
                child: _buildChart(data),
              ),
              
              // Views badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: _accentColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Iconsax.eye,
                          color: _accentColor,
                          size: 14,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          '20 views',
                          style: TextStyle(
                            color: _accentColor,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    'Monday, April 22nd',
                    style: TextStyle(
                      color: _textColor.withOpacity(0.5),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 15),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
              decoration: BoxDecoration(
                color: _secondaryColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Text(
                    '30%',
                    style: TextStyle(
                      color: _accentColor,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Your sales performance is 30% better compare to last month',
                style: TextStyle(
                  color: _textColor,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildChart(List<ChartData> chartData) {
    return SfCartesianChart(
      plotAreaBorderWidth: 0,
      primaryXAxis: CategoryAxis(
        majorGridLines: const MajorGridLines(width: 0),
        labelStyle: TextStyle(color: _textColor.withOpacity(0.7), fontSize: 10),
        axisLine: const AxisLine(width: 0),
      ),
      primaryYAxis: NumericAxis(
        isVisible: false,
        majorGridLines: const MajorGridLines(width: 0),
      ),
      tooltipBehavior: TooltipBehavior(
        enable: true,
        color: _secondaryColor,
        textStyle: TextStyle(color: _accentColor),
      ),
      series: <CartesianSeries>[
        // Animated column series
        ColumnSeries<ChartData, String>(
          animationDuration: 1500,
          dataSource: chartData,
          xValueMapper: (ChartData data, _) => data.x,
          yValueMapper: (ChartData data, _) => data.y,
          pointColorMapper: (ChartData data, _) => _accentColor,
          borderRadius: BorderRadius.circular(4),
          width: 0.6,
          spacing: 0.2,
        )
      ],
    );
  }

  Widget _buildAlternativeChart(List<double> values, List<String> labels) {
    final double maxValue = values.reduce((a, b) => a > b ? a : b);
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(values.length, (index) {
        // Calculate the relative height
        final double relativeHeight = values[index] / maxValue;
        
        return Column(
          children: [
            // Value label
            AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return Opacity(
                  opacity: _animationController.value,
                  child: Text(
                    values[index].toStringAsFixed(1),
                    style: TextStyle(
                      color: _accentColor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 5),
            // Bar
            TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: 140 * relativeHeight),
              duration: const Duration(milliseconds: 1000),
              curve: Curves.easeOutQuad,
              builder: (context, value, child) {
                return Container(
                  width: 20,
                  height: value,
                  decoration: BoxDecoration(
                    color: _accentColor,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(4),
                      topRight: Radius.circular(4),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 5),
            // Month label
            Text(
              labels[index],
              style: TextStyle(
                color: _textColor.withOpacity(0.7),
                fontSize: 10,
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildReportSelectionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Report',
          style: TextStyle(
            color: _textColor,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            fontFamily: 'Helvetica Neue',
          ),
        ),
        const SizedBox(height: 15),
        // Generate report selection widgets from _reportData
        ..._reportData.entries.map((entry) => _buildReportCard(entry.key, entry.value)).toList(),
      ],
    );
  }

  Widget _buildReportCard(String reportType, Map<String, dynamic> reportData) {
    return GestureDetector(
      onTap: () => _selectReport(reportType),
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: _secondaryColor,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: _selectedReportType == reportType ? _accentColor : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            // Report icon
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _bgColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                reportData['icon'] as IconData,
                color: _accentColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 15),
            // Report details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    reportData['title'] as String,
                    style: TextStyle(
                      color: _textColor,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    reportData['value'] as String,
                    style: TextStyle(
                      color: _textColor.withOpacity(0.7),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            // Actions row
            Row(
              children: [
                // View details button
                GestureDetector(
                  onTap: () => _openDetailedReport(reportType),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _bgColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Iconsax.chart_2,
                      color: _accentColor,
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // Download button
                GestureDetector(
                  onTap: () => _downloadReport(reportType),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _bgColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Iconsax.document_download,
                      color: _accentColor,
                      size: 20,
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
}

// Report Detail Page
class ReportDetailPage extends StatefulWidget {
  final String reportType;
  final String reportTitle;
  final Map<String, dynamic> reportData;

  const ReportDetailPage({
    super.key,
    required this.reportType,
    required this.reportTitle,
    required this.reportData,
  });

  @override
  State<ReportDetailPage> createState() => _ReportDetailPageState();
}

class _ReportDetailPageState extends State<ReportDetailPage> with SingleTickerProviderStateMixin {
  // Theme colors
  final Color _bgColor = const Color(0xFF151611);     // Background
  final Color _secondaryColor = const Color(0xFF222222); // Secondary
  final Color _accentColor = const Color(0xFFD0F0C0);  // Accent
  final Color _textColor = const Color(0xFFEEEFEF);   // Text
  
  // Filter values
  String _selectedTimeframe = 'monthly';
  String _selectedFormat = 'pdf';
  
  // Animation controller
  late AnimationController _animationController;
  
  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _animationController.forward();
    });
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
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
                    // Chart Section
                    Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: _buildDetailChartSection(),
                    ),
                    
                    // Filter Section
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: _buildFilterSection(),
                    ),
                    
                    // Report Content
                    Padding(
                      padding: const EdgeInsets.all(20.0),
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

  Widget _buildDetailChartSection() {
    final List<double> chartData = List<double>.from(widget.reportData['chartData']);
    final List<String> months = List<String>.from(widget.reportData['months']);
    
    // Convert to chart data format
    final List<ChartData> data = List.generate(
      chartData.length,
      (index) => ChartData(
        months[index],
        chartData[index],
      ),
    );
    
    return Container(
      height: 300,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: _secondaryColor,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${widget.reportTitle} Trend',
            style: TextStyle(
              color: _textColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: _buildDetailChart(data),
          ),
        ],
      ),
    );
  }
  
  Widget _buildDetailChart(List<ChartData> chartData) {
    return SfCartesianChart(
      plotAreaBorderWidth: 0,
      margin: const EdgeInsets.all(0),
      primaryXAxis: CategoryAxis(
        majorGridLines: const MajorGridLines(width: 0),
        labelStyle: TextStyle(color: _textColor.withOpacity(0.7), fontSize: 10),
        axisLine: const AxisLine(width: 0),
      ),
      primaryYAxis: NumericAxis(
        axisLine: const AxisLine(width: 0),
        labelStyle: TextStyle(color: _textColor.withOpacity(0.7), fontSize: 10),
        majorGridLines: MajorGridLines(
          width: 0.5,
          color: _textColor.withOpacity(0.2),
        ),
      ),
      legend: Legend(
        isVisible: true,
        position: LegendPosition.bottom,
        textStyle: TextStyle(color: _textColor.withOpacity(0.7), fontSize: 12),
      ),
      tooltipBehavior: TooltipBehavior(
        enable: true,
        color: _secondaryColor,
        textStyle: TextStyle(color: _accentColor),
      ),
      zoomPanBehavior: ZoomPanBehavior(
        enablePinching: true,
        enablePanning: true,
        zoomMode: ZoomMode.x,
      ),
      series: <CartesianSeries>[
        // Line series
        LineSeries<ChartData, String>(
          name: widget.reportTitle,
          animationDuration: 1500,
          dataSource: chartData,
          xValueMapper: (ChartData data, _) => data.x,
          yValueMapper: (ChartData data, _) => data.y,
          color: _accentColor,
          width: 2,
          markerSettings: MarkerSettings(
            isVisible: true,
            color: _accentColor,
            borderColor: _secondaryColor,
            borderWidth: 2,
          ),
        ),
        // Area series for background
        AreaSeries<ChartData, String>(
          name: 'Area',
          animationDuration: 1800,
          dataSource: chartData,
          xValueMapper: (ChartData data, _) => data.x,
          yValueMapper: (ChartData data, _) => data.y,
          color: _accentColor.withOpacity(0.15),
          borderColor: _accentColor.withOpacity(0.5),
          borderWidth: 1,
        ),
      ],
    );
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
    
    // Sample time-of-day data
    final timeData = [
      ChartData('Morning', 35),
      ChartData('Afternoon', 45),
      ChartData('Evening', 85),
      ChartData('Night', 25),
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
        AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.05, 0),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: _animationController,
                curve: const Interval(0.3, 0.8, curve: Curves.easeOutCubic),
              )),
              child: FadeTransition(
                opacity: Tween<double>(begin: 0, end: 1).animate(
                  CurvedAnimation(
                    parent: _animationController,
                    curve: const Interval(0.3, 0.8, curve: Curves.easeOut),
                  ),
                ),
                child: child,
              ),
            );
          },
          child: Container(
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
                )).toList(),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        
        // Sales by Time Period
        AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.05, 0),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: _animationController,
                curve: const Interval(0.4, 0.9, curve: Curves.easeOutCubic),
              )),
              child: FadeTransition(
                opacity: Tween<double>(begin: 0, end: 1).animate(
                  CurvedAnimation(
                    parent: _animationController,
                    curve: const Interval(0.4, 0.9, curve: Curves.easeOut),
                  ),
                ),
                child: child,
              ),
            );
          },
          child: Container(
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
                SizedBox(
                  height: 200,
                  child: SfCartesianChart(
                    plotAreaBorderWidth: 0,
                    primaryXAxis: CategoryAxis(
                      majorGridLines: const MajorGridLines(width: 0),
                      labelStyle: TextStyle(color: _textColor.withOpacity(0.7), fontSize: 10),
                      axisLine: const AxisLine(width: 0),
                    ),
                    primaryYAxis: NumericAxis(
                      isVisible: false,
                      majorGridLines: const MajorGridLines(width: 0),
                    ),
                    series: <CartesianSeries>[
                      ColumnSeries<ChartData, String>(
                        animationDuration: 1500,
                        dataSource: timeData,
                        xValueMapper: (ChartData data, _) => data.x,
                        yValueMapper: (ChartData data, _) => data.y,
                        pointColorMapper: (ChartData data, _) => _accentColor,
                        borderRadius: BorderRadius.circular(4),
                        dataLabelSettings: DataLabelSettings(
                          isVisible: true,
                          textStyle: TextStyle(
                            color: _textColor,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          labelAlignment: ChartDataLabelAlignment.top,
                        ),
                      )
                    ],
                  ),
                ),
              ],
            ),
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
    
    // Inventory status distribution
    final inventoryStatus = [
      {'status': 'In Stock', 'value': 85, 'color': Colors.green},
      {'status': 'Low Stock', 'value': 12, 'color': Colors.orange},
      {'status': 'Out of Stock', 'value': 3, 'color': Colors.red},
    ];
    
    final pieData = inventoryStatus
        .map((item) => ChartData(
              item['status'] as String,
              item['value'] as double,
              color: item['color'] as Color,
            ))
        .toList();
    
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
        
        // Inventory Status Pie Chart
        AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.05, 0),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: _animationController,
                curve: const Interval(0.3, 0.8, curve: Curves.easeOutCubic),
              )),
              child: FadeTransition(
                opacity: Tween<double>(begin: 0, end: 1).animate(
                  CurvedAnimation(
                    parent: _animationController,
                    curve: const Interval(0.3, 0.8, curve: Curves.easeOut),
                  ),
                ),
                child: child,
              ),
            );
          },
          child: Container(
            height: 300,
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
                      Iconsax.status_up,
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
                Expanded(
                  child: SfCircularChart(
                    margin: EdgeInsets.zero,
                    legend: Legend(
                      isVisible: true,
                      position: LegendPosition.bottom,
                      textStyle: TextStyle(color: _textColor, fontSize: 12),
                    ),
                    series: <CircularSeries>[
                      DoughnutSeries<ChartData, String>(
                        animationDuration: 1200,
                        dataSource: pieData,
                        xValueMapper: (ChartData data, _) => data.x,
                        yValueMapper: (ChartData data, _) => data.y,
                        pointColorMapper: (ChartData data, _) => data.color,
                        radius: '80%',
                        innerRadius: '60%',
                        dataLabelSettings: DataLabelSettings(
                          isVisible: true,
                          textStyle: TextStyle(
                            color: _textColor,
                            fontSize: 12,
                          ),
                          labelPosition: ChartDataLabelPosition.outside,
                        ),
                      )
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        
        // Inventory Items Table
        AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.05, 0),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: _animationController,
                curve: const Interval(0.4, 0.9, curve: Curves.easeOutCubic),
              )),
              child: FadeTransition(
                opacity: Tween<double>(begin: 0, end: 1).animate(
                  CurvedAnimation(
                    parent: _animationController,
                    curve: const Interval(0.4, 0.9, curve: Curves.easeOut),
                  ),
                ),
                child: child,
              ),
            );
          },
          child: Container(
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
                      'Inventory Items',
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
                )).toList(),
              ],
            ),
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
    
    // Category data for chart
    final categoryData = categoryPerformance
        .map((item) => ChartData(
              item['name'] as String,
              (item['orders'] as int).toDouble(),
            ))
        .toList();
    
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
        
        // Category Chart
        AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.05, 0),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: _animationController,
                curve: const Interval(0.3, 0.8, curve: Curves.easeOutCubic),
              )),
              child: FadeTransition(
                opacity: Tween<double>(begin: 0, end: 1).animate(
                  CurvedAnimation(
                    parent: _animationController,
                    curve: const Interval(0.3, 0.8, curve: Curves.easeOut),
                  ),
                ),
                child: child,
              ),
            );
          },
          child: Container(
            height: 300,
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
                Expanded(
                  child: SfCartesianChart(
                    plotAreaBorderWidth: 0,
                    primaryXAxis: CategoryAxis(
                      majorGridLines: const MajorGridLines(width: 0),
                      labelStyle: TextStyle(color: _textColor.withOpacity(0.7), fontSize: 10),
                      axisLine: const AxisLine(width: 0),
                    ),
                    primaryYAxis: NumericAxis(
                      axisLine: const AxisLine(width: 0),
                      labelStyle: TextStyle(color: _textColor.withOpacity(0.7), fontSize: 10),
                      majorGridLines: MajorGridLines(
                        width: 0.5,
                        color: _textColor.withOpacity(0.2),
                      ),
                    ),
                    series: <CartesianSeries>[
                      BarSeries<ChartData, String>(
                        animationDuration: 1500,
                        dataSource: categoryData,
                        xValueMapper: (ChartData data, _) => data.x,
                        yValueMapper: (ChartData data, _) => data.y,
                        pointColorMapper: (ChartData data, _) => _accentColor,
                        borderRadius: BorderRadius.circular(4),
                        dataLabelSettings: DataLabelSettings(
                          isVisible: true,
                          textStyle: TextStyle(
                            color: _textColor,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        
        // Category Performance Table
        AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.05, 0),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: _animationController,
                curve: const Interval(0.4, 0.9, curve: Curves.easeOutCubic),
              )),
              child: FadeTransition(
                opacity: Tween<double>(begin: 0, end: 1).animate(
                  CurvedAnimation(
                    parent: _animationController,
                    curve: const Interval(0.4, 0.9, curve: Curves.easeOut),
                  ),
                ),
                child: child,
              ),
            );
          },
          child: Container(
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
                      Iconsax.document_text,
                      color: _accentColor,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Category Details',
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
                )).toList(),
              ],
            ),
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
          {'name': 'Avg. Discount', 'value': '15%', 'change': '', 'icon': Iconsax.percentage_square},
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
          {'name': 'Metric 3', 'value': '42%', 'change': '+3%', 'icon': Iconsax.percentage_square},
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
    
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return FadeTransition(
          opacity: Tween<double>(begin: 0, end: 1).animate(
            CurvedAnimation(
              parent: _animationController,
              curve: const Interval(0.1, 0.6, curve: Curves.easeOut),
            ),
          ),
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.95, end: 1.0).animate(
              CurvedAnimation(
                parent: _animationController,
                curve: const Interval(0.1, 0.6, curve: Curves.easeOut),
              ),
            ),
            child: child,
          ),
        );
      },
      child: Container(
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
      ),
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
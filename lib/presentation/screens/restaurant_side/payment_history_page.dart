import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tapeats/presentation/widgets/header_widget.dart';
import 'package:tapeats/presentation/widgets/sidemenu_overlay.dart';
import 'package:intl/intl.dart';

class PaymentHistoryPage extends StatefulWidget {
  const PaymentHistoryPage({super.key});

  @override
  State<PaymentHistoryPage> createState() => _PaymentHistoryPageState();
}

class _PaymentHistoryPageState extends State<PaymentHistoryPage> {
  final SupabaseClient _supabase = Supabase.instance.client;
  bool _isLoading = false;
  List<Map<String, dynamic>> _history = [];
  
  @override
  void initState() {
    super.initState();
    _loadHistory();
  }
  
  Future<void> _loadHistory() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final user = _supabase.auth.currentUser;
      if (user != null) {
        final response = await _supabase
            .from('subscription_history')
            .select()
            .eq('user_id', user.id)
            .order('created_at', ascending: false);
        
        setState(() {
          _history = List<Map<String, dynamic>>.from(response);
        });
      }
    } catch (e) {
      print('Error loading history: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
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
              headingText: "Payment History",
              rightIcon: Iconsax.menu_1,
              onRightButtonPressed: _openSideMenu,
            ),
            
            // Loading indicator
            if (_isLoading)
              const LinearProgressIndicator(
                backgroundColor: Color(0xFF222222),
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFD0F0C0)),
              ),
            
            // Content
            Expanded(
              child: _history.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Iconsax.receipt_1,
                            size: 64,
                            color: Colors.grey[700],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No payment history found',
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _history.length,
                      itemBuilder: (context, index) {
                        final transaction = _history[index];
                        return _buildTransactionCard(transaction);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildTransactionCard(Map<String, dynamic> transaction) {
    final formatter = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 2,
    );
    
    final amount = transaction['amount'] is double
        ? transaction['amount']
        : double.parse(transaction['amount'].toString());
        
    final dateTime = DateTime.parse(transaction['created_at']);
    final formattedDate = DateFormat('dd MMM yyyy, hh:mm a').format(dateTime);
    
    final bool isSuccessful = transaction['status'] == 'success';
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: const Color(0xFF1A1A1A),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${transaction['plan_id'].toString().toUpperCase()} Plan',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isSuccessful ? Colors.green[800] : Colors.red[800],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    transaction['status'].toString().toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                      Iconsax.calendar,
                      color: Color(0xFFD0F0C0),
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      formattedDate,
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                Text(
                  formatter.format(amount),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(
                  Iconsax.receipt_2,
                  color: Color(0xFFD0F0C0),
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  transaction['payment_id'] ?? 'N/A',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            if (transaction['payment_method'] != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(
                    Iconsax.card,
                    color: Color(0xFFD0F0C0),
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Paid with ${transaction['payment_method']}',
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ],
            // Add invoice download option
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () {
                  // Future implementation: Generate and download invoice
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Invoice download will be available soon'),
                      backgroundColor: Colors.blue,
                    ),
                  );
                },
                icon: const Icon(
                  Iconsax.document_download,
                  color: Color(0xFFD0F0C0),
                  size: 16,
                ),
                label: const Text(
                  'Invoice',
                  style: TextStyle(
                    color: Color(0xFFD0F0C0),
                    fontSize: 12,
                  ),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
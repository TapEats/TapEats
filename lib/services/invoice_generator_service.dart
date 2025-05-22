import 'dart:io';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:share_plus/share_plus.dart';

class InvoiceGenerator {
  final SupabaseClient _supabase = Supabase.instance.client;
  
  // Get transaction data
  Future<Map<String, dynamic>?> getTransactionData(String transactionId) async {
    try {
      final transaction = await _supabase
          .from('subscription_transactions')
          .select('''
            *,
            invoice_details(*),
            users:user_id(username, email, phone_number),
            subscription_plans:plan_id(name, price, currency)
          ''')
          .eq('id', transactionId)
          .single();
          
      return transaction;
    } catch (e) {
      print('Error getting transaction data: $e');
      return null;
    }
  }
  
  // Generate and share invoice
  Future<void> generateAndShareInvoice(String transactionId) async {
    try {
      // Get transaction data
      final transaction = await getTransactionData(transactionId);
      if (transaction == null) {
        throw Exception('Transaction not found');
      }
      
      // Create PDF
      final pdf = await _createInvoicePdf(transaction);
      
      // Save PDF to file
      final output = await getTemporaryDirectory();
      final invoiceNumber = transaction['invoice_details']['invoice_number'];
      final file = File('${output.path}/invoice_$invoiceNumber.pdf');
      await file.writeAsBytes(await pdf.save());
      
      // Share PDF
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'TapEats Invoice #$invoiceNumber',
        subject: 'TapEats Subscription Invoice',
      );
    } catch (e) {
      print('Error generating and sharing invoice: $e');
      rethrow;
    }
  }
  
  // Create invoice PDF
  Future<pw.Document> _createInvoicePdf(Map<String, dynamic> transaction) async {
    // Initialize PDF document
    final pdf = pw.Document();
    
    // Load logo image
    final ByteData logoBytes = await rootBundle.load('assets/images/logo.png');
    final Uint8List logoData = logoBytes.buffer.asUint8List();
    
    // Format dates
    final invoiceDate = DateTime.parse(transaction['created_at']);
    final formattedDate = DateFormat('dd/MM/yyyy').format(invoiceDate);
    
    // Format amount
    final formatter = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 2,
    );
    final amount = transaction['amount'] is double
        ? transaction['amount']
        : double.parse(transaction['amount'].toString());
    
    // Calculate tax (assuming 18% GST)
    final taxRate = 0.18;
    final taxAmount = amount * taxRate;
    final subTotal = amount - taxAmount;
    
    // Get the invoice details
    final invoiceDetails = transaction['invoice_details'];
    final invoiceNumber = invoiceDetails['invoice_number'];
    final businessName = invoiceDetails['business_name'] ?? 'Restaurant Owner';
    final businessAddress = invoiceDetails['address'] ?? '';
    final state = invoiceDetails['state'] ?? 'Gujarat';
    
    // User details
    final user = transaction['users'];
    final userName = user['username'] ?? 'Customer';
    final userEmail = user['email'] ?? '';
    final userPhone = user['phone_number'] ?? '';
    
    // Plan details
    final plan = transaction['subscription_plans'];
    final planName = plan['name'];
    
    // Add pages to the PDF
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Container(
            padding: const pw.EdgeInsets.all(40),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Header
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    // Logo and company info
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Image(
                          pw.MemoryImage(logoData),
                          width: 100,
                          height: 50,
                        ),
                        pw.SizedBox(height: 10),
                        pw.Text(
                          'TapEats',
                          style: pw.TextStyle(
                            fontSize: 20,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.Text(
                          'GSTIN: 24AABCT1234Z1ZT',
                          style: const pw.TextStyle(fontSize: 10),
                        ),
                        pw.Text(
                          'support@tapeats.com',
                          style: const pw.TextStyle(fontSize: 10),
                        ),
                      ],
                    ),
                    
                    // Invoice info
                    pw.Container(
                      padding: const pw.EdgeInsets.all(10),
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: PdfColors.grey300),
                        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'INVOICE',
                            style: pw.TextStyle(
                              fontSize: 16,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                          pw.SizedBox(height: 5),
                          pw.Text(
                            'Invoice Number: $invoiceNumber',
                            style: const pw.TextStyle(fontSize: 10),
                          ),
                          pw.Text(
                            'Date: $formattedDate',
                            style: const pw.TextStyle(fontSize: 10),
                          ),
                          pw.Text(
                            'Payment ID: ${transaction['payment_id']}',
                            style: const pw.TextStyle(fontSize: 10),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                pw.SizedBox(height: 40),
                
                // Billing information
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    // Bill to
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'Bill To:',
                            style: pw.TextStyle(
                              fontSize: 14,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                          pw.SizedBox(height: 5),
                          pw.Text(
                            businessName,
                            style: const pw.TextStyle(fontSize: 12),
                          ),
                          if (businessAddress.isNotEmpty)
                            pw.Text(
                              businessAddress,
                              style: const pw.TextStyle(fontSize: 10),
                            ),
                          pw.Text(
                            'State: $state, India',
                            style: const pw.TextStyle(fontSize: 10),
                          ),
                          pw.SizedBox(height: 5),
                          pw.Text(
                            'Contact: $userName',
                            style: const pw.TextStyle(fontSize: 10),
                          ),
                          pw.Text(
                            'Email: $userEmail',
                            style: const pw.TextStyle(fontSize: 10),
                          ),
                          if (userPhone.isNotEmpty)
                            pw.Text(
                              'Phone: $userPhone',
                              style: const pw.TextStyle(fontSize: 10),
                            ),
                        ],
                      ),
                    ),
                    
                    // Payment info
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'Payment Method:',
                            style: pw.TextStyle(
                              fontSize: 14,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                          pw.SizedBox(height: 5),
                          pw.Text(
                            'Razorpay (${transaction['payment_method'] ?? 'Online Payment'})',
                            style: const pw.TextStyle(fontSize: 12),
                          ),
                          pw.SizedBox(height: 10),
                          pw.Text(
                            'Payment Status:',
                            style: pw.TextStyle(
                              fontSize: 14,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                          pw.SizedBox(height: 5),
                          pw.Container(
                            padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: pw.BoxDecoration(
                              color: PdfColors.green100,
                              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
                            ),
                            child: pw.Text(
                              transaction['status'].toString().toUpperCase(),
                              style: pw.TextStyle(
                                color: PdfColors.green800,
                                fontSize: 12,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                pw.SizedBox(height: 40),
                
                // Invoice items
                pw.Container(
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey300),
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
                  ),
                  child: pw.Column(
                    children: [
                      // Table header
                      pw.Container(
                        padding: const pw.EdgeInsets.all(10),
                        decoration: const pw.BoxDecoration(
                          color: PdfColors.grey200,
                          borderRadius: pw.BorderRadius.only(
                            topLeft: pw.Radius.circular(10),
                            topRight: pw.Radius.circular(10),
                          ),
                        ),
                        child: pw.Row(
                          children: [
                            pw.Expanded(
                              flex: 6,
                              child: pw.Text(
                                'Item',
                                style: pw.TextStyle(
                                  fontWeight: pw.FontWeight.bold,
                                ),
                              ),
                            ),
                            pw.Expanded(
                              flex: 2,
                              child: pw.Text(
                                'Quantity',
                                style: pw.TextStyle(
                                  fontWeight: pw.FontWeight.bold,
                                ),
                                textAlign: pw.TextAlign.center,
                              ),
                            ),
                            pw.Expanded(
                              flex: 3,
                              child: pw.Text(
                                'Price',
                                style: pw.TextStyle(
                                  fontWeight: pw.FontWeight.bold,
                                ),
                                textAlign: pw.TextAlign.right,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Table item
                      pw.Container(
                        padding: const pw.EdgeInsets.all(10),
                        child: pw.Row(
                          children: [
                            pw.Expanded(
                              flex: 6,
                              child: pw.Column(
                                crossAxisAlignment: pw.CrossAxisAlignment.start,
                                children: [
                                  pw.Text(
                                    '$planName Subscription Plan',
                                    style: pw.TextStyle(
                                      fontWeight: pw.FontWeight.bold,
                                    ),
                                  ),
                                  pw.SizedBox(height: 5),
                                  pw.Text(
                                    'Subscription Period: 1 Month',
                                    style: const pw.TextStyle(fontSize: 10),
                                  ),
                                ],
                              ),
                            ),
                            pw.Expanded(
                              flex: 2,
                              child: pw.Text(
                                '1',
                                textAlign: pw.TextAlign.center,
                              ),
                            ),
                            pw.Expanded(
                              flex: 3,
                              child: pw.Text(
                                formatter.format(subTotal),
                                textAlign: pw.TextAlign.right,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Divider
                      pw.Divider(color: PdfColors.grey300),
                      
                      // Subtotal
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(10),
                        child: pw.Row(
                          children: [
                            pw.Expanded(
                              flex: 8,
                              child: pw.Text(
                                'Subtotal',
                                style: pw.TextStyle(
                                  fontWeight: pw.FontWeight.bold,
                                ),
                                textAlign: pw.TextAlign.right,
                              ),
                            ),
                            pw.Expanded(
                              flex: 3,
                              child: pw.Text(
                                formatter.format(subTotal),
                                textAlign: pw.TextAlign.right,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Tax
                      pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        child: pw.Row(
                          children: [
                            pw.Expanded(
                              flex: 8,
                              child: pw.Text(
                                'GST (18%)',
                                style: pw.TextStyle(
                                  fontWeight: pw.FontWeight.bold,
                                ),
                                textAlign: pw.TextAlign.right,
                              ),
                            ),
                            pw.Expanded(
                              flex: 3,
                              child: pw.Text(
                                formatter.format(taxAmount),
                                textAlign: pw.TextAlign.right,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Total
                      pw.Container(
                        padding: const pw.EdgeInsets.all(10),
                        decoration: const pw.BoxDecoration(
                          color: PdfColors.grey200,
                          borderRadius: pw.BorderRadius.only(
                            bottomLeft: pw.Radius.circular(10),
                            bottomRight: pw.Radius.circular(10),
                          ),
                        ),
                        child: pw.Row(
                          children: [
                            pw.Expanded(
                              flex: 8,
                              child: pw.Text(
                                'Total',
                                style: pw.TextStyle(
                                  fontWeight: pw.FontWeight.bold,
                                  fontSize: 14,
                                ),
                                textAlign: pw.TextAlign.right,
                              ),
                            ),
                            pw.Expanded(
                              flex: 3,
                              child: pw.Text(
                                formatter.format(amount),
                                style: pw.TextStyle(
                                  fontWeight: pw.FontWeight.bold,
                                  fontSize: 14,
                                ),
                                textAlign: pw.TextAlign.right,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                pw.SizedBox(height: 40),
                
                // Notes and terms
                pw.Container(
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey300),
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Terms & Conditions:',
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 5),
                      pw.Text(
                        '1. Subscription is valid for 1 month from the date of purchase.',
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                      pw.Text(
                        '2. All prices are inclusive of GST.',
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                      pw.Text(
                        '3. For any queries, please contact support@tapeats.com',
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                    ],
                  ),
                ),
                
                pw.Spacer(),
                
                // Footer
                pw.Center(
                  child: pw.Text(
                    'Thank you for choosing TapEats!',
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                pw.SizedBox(height: 5),
                pw.Center(
                  child: pw.Text(
                    'This is a computer-generated invoice and does not require a signature.',
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
    
    return pdf;
  }
}
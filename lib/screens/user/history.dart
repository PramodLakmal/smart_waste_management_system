import 'dart:io' as io;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:html' as html;

class PaymentHistory extends StatefulWidget {
  const PaymentHistory({super.key});

  @override
  State<PaymentHistory> createState() => _PaymentHistoryState();
}

class _PaymentHistoryState extends State<PaymentHistory> {
  User? currentUser;
  Query? paymentsQuery;

  @override
  void initState() {
    super.initState();
    _getCurrentUser();
  }

  void _getCurrentUser() {
    User? user = FirebaseAuth.instance.currentUser;
    setState(() {
      currentUser = user;
      if (user != null) {
        paymentsQuery = FirebaseFirestore.instance
            .collection('payments')
            .where('userId', isEqualTo: user.uid);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Payment History'),
        backgroundColor: const Color(0xFF2E7D32),
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [const Color(0xFF4CAF50), Colors.teal.shade50],
          ),
        ),
        child: currentUser == null
            ? const Center(
                child: Text(
                  'No user is logged in',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              )
            : _buildResponsiveLayout(),
      ),
    );
  }

  Widget _buildResponsiveLayout() {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 600) {
          return _buildPaymentHistory(isMobile: true);
        } else {
          return _buildPaymentHistory(isMobile: false);
        }
      },
    );
  }

  Widget _buildPaymentHistory({required bool isMobile}) {
    if (paymentsQuery == null) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.teal),
        ),
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: paymentsQuery?.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.teal),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text(
              'No payment history available',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          );
        }

        var paymentDocs = snapshot.data!.docs;

        return isMobile
            ? ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: paymentDocs.length,
                itemBuilder: (context, index) {
                  var paymentData =
                      paymentDocs[index].data() as Map<String, dynamic>;
                  return _buildPaymentCard(paymentData, isMobile);
                },
              )
            : GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.2,
                ),
                itemCount: paymentDocs.length,
                itemBuilder: (context, index) {
                  var paymentData =
                      paymentDocs[index].data() as Map<String, dynamic>;
                  return _buildPaymentCard(paymentData, isMobile);
                },
              );
      },
    );
  }

  Widget _buildPaymentCard(Map<String, dynamic> paymentData, bool isMobile) {
    double electricalWasteWeight = paymentData['electricalWasteWeight'] ?? 0.0;
    double otherWasteWeight = paymentData['otherWasteWeight'] ?? 0.0;
    double totalPayment = paymentData['totalPayment'] ?? 0.0;
    String userId = paymentData['userId'] ?? 'Unknown';
    Timestamp timestamp = paymentData['timestamp'] ?? Timestamp.now();

    String formattedDate =
        DateFormat('yyyy-MM-dd – kk:mm').format(timestamp.toDate());

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      elevation: 5,
      shadowColor: Colors.teal.withOpacity(0.5),
      margin: const EdgeInsets.all(8),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, Colors.teal.shade50],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Total Payment',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: isMobile ? 18 : 16,
                  color: Colors.teal.shade700,
                ),
              ),
              Text(
                '\$${totalPayment.toStringAsFixed(2)}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: isMobile ? 24 : 20,
                  color: Colors.teal,
                ),
              ),
              const SizedBox(height: 8),
              _buildInfoRow('Electrical Waste', '$electricalWasteWeight kg'),
              _buildInfoRow('Other Waste', '$otherWasteWeight kg'),
              const SizedBox(height: 8),
              _buildInfoRow('Date', formattedDate),
              Text(
                'User ID: $userId',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () {
                  _downloadReceipt(electricalWasteWeight, otherWasteWeight,
                      totalPayment, formattedDate, userId);
                },
                child: const Text('Download Receipt'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.teal.shade700,
              fontSize: 12,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  void _downloadReceipt(double electricalWaste, double otherWaste,
      double totalPayment, String formattedDate, String userId) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Payment Receipt',
                  style: pw.TextStyle(
                      fontSize: 24, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 20),
              pw.Text('Date: $formattedDate'),
              pw.SizedBox(height: 10),
              pw.Text('User ID: $userId'),
              pw.SizedBox(height: 10),
              pw.Text('Total Payment: \$${totalPayment.toStringAsFixed(2)}'),
              pw.SizedBox(height: 10),
              pw.Text('Electrical Waste: $electricalWaste kg'),
              pw.SizedBox(height: 10),
              pw.Text('Other Waste: $otherWaste kg'),
              pw.SizedBox(height: 20),
              pw.Text('Thank you for recycling!',
                  style: pw.TextStyle(fontStyle: pw.FontStyle.italic)),
            ],
          );
        },
      ),
    );

    if (kIsWeb) {
      final bytes = await pdf.save();
      final blob = html.Blob([bytes], 'application/pdf');
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
        ..setAttribute('download', 'receipt.pdf')
        ..click();
      html.Url.revokeObjectUrl(url);
    } else {
      var status = await Permission.storage.request();
      if (status.isGranted) {
        final directory = await getApplicationDocumentsDirectory();
        final file = io.File(
            '${directory.path}/receipt_${DateTime.now().millisecondsSinceEpoch}.pdf');
        await file.writeAsBytes(await pdf.save());

        await Printing.sharePdf(
            bytes: await pdf.save(), filename: 'receipt.pdf');
      } else {
        print('Storage permission denied');
      }
    }
  }
}

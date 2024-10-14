import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Payment extends StatefulWidget {
  const Payment({super.key});

  @override
  State<Payment> createState() => _PaymentState();
}

class _PaymentState extends State<Payment> {
  double totalPayment = 0.0;
  double totalCoins = 0.0;
  double totalElectricalWeight = 0.0;
  double totalOtherWeight = 0.0;
  double grandTotal = 0.0;
  double discountFromCoins = 0.0;
  double netAmount = 0.0;
  bool usedCoins = false;
  double remainingCoins = 0.0;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    calculateTotalAmount();
    fetchCurrentCoins();
  }

  Future<void> fetchCurrentCoins() async {
    User? currentUser = _auth.currentUser;
    if (currentUser != null) {
      String userId = currentUser.uid;
      DocumentSnapshot coinsDoc = await FirebaseFirestore.instance
          .collection('coins')
          .doc(userId)
          .get();

      if (coinsDoc.exists) {
        setState(() {
          totalCoins = (coinsDoc['totalCoins'] ?? 0.0).toDouble();
        });
      }
    }
  }

  Future<void> calculateTotalAmount() async {
    double coinsFromCollectionTotals = await calculateWasteCollectionTotals();
    await calculateSpecialWasteTotals(coinsFromCollectionTotals);
    setState(() {
      netAmount = totalPayment;
    });
  }

  Future<double> calculateWasteCollectionTotals() async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser == null) return 0.0;
      String userId = currentUser.uid;

      QuerySnapshot wasteCollectionRequests = await FirebaseFirestore.instance
          .collection('wasteCollectionRequests')
          .where('userId', isEqualTo: userId)
          .where('isCollected', isEqualTo: false)
          .where('paymentStatus', isEqualTo: 'pending')
          .get();

      double otherWasteTotal = 0.0;
      double electricalWasteCoins = 0.0;

      for (var requestDoc in wasteCollectionRequests.docs) {
        var requestData = requestDoc.data() as Map<String, dynamic>;
        String binId = requestData['binId'];

        DocumentSnapshot binDoc = await FirebaseFirestore.instance
            .collection('bins')
            .doc(binId)
            .get();

        if (binDoc.exists) {
          var binData = binDoc.data() as Map<String, dynamic>;
          String type = binData['type'] ?? '';
          double weight = (binData['weight'] ?? 0.0).toDouble();

          if (type == 'Electrical Waste') {
            electricalWasteCoins += weight;
            totalElectricalWeight += weight;
          } else {
            double amount = weight * 2;
            otherWasteTotal += amount;
            totalOtherWeight += weight;
          }
        }
      }

      setState(() {
        totalPayment += otherWasteTotal;
      });

      return electricalWasteCoins;
    } catch (e) {
      print('Error calculating waste collection totals: $e');
      return 0.0;
    }
  }

  Future<void> calculateSpecialWasteTotals(
      double coinsFromCollectionTotals) async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser == null) return;
      String userId = currentUser.uid;

      QuerySnapshot specialWasteRequests = await FirebaseFirestore.instance
          .collection('specialWasteRequests')
          .where('userId', isEqualTo: userId)
          .where('paymentStatus', isEqualTo: 'pending')
          .get();

      double electricalWasteCoins = 0.0;

      for (var requestDoc in specialWasteRequests.docs) {
        var requestData = requestDoc.data() as Map<String, dynamic>;
        List<dynamic> wasteTypes = requestData['wasteTypes'] ?? [];

        for (var wasteType in wasteTypes) {
          String type = wasteType['type'] ?? '';
          double weight = (wasteType['weight'] ?? 0.0).toDouble();

          if (type == 'Electrical Waste') {
            electricalWasteCoins += weight;
            totalElectricalWeight += weight;
          } else {
            totalOtherWeight += weight;
            totalPayment += weight * 2;
          }
        }
      }

      electricalWasteCoins += coinsFromCollectionTotals;

      if (electricalWasteCoins > 0) {
        DocumentSnapshot balanceDoc = await FirebaseFirestore.instance
            .collection('balance')
            .doc(userId)
            .get();

        double leftCoins =
            (balanceDoc.exists ? balanceDoc['leftCoins'] ?? 0.0 : 0.0)
                .toDouble();

        setState(() {
          totalCoins = leftCoins + electricalWasteCoins;
        });

        await updateCoinsInFirestore(userId, totalCoins);
      }
    } catch (e) {
      print('Error calculating special waste totals: $e');
    }
  }

  Future<void> updateCoinsInFirestore(
      String userId, double updatedCoins) async {
    try {
      DocumentSnapshot coinsDoc = await FirebaseFirestore.instance
          .collection('coins')
          .doc(userId)
          .get();

      if (coinsDoc.exists) {
        await FirebaseFirestore.instance
            .collection('coins')
            .doc(userId)
            .update({'totalCoins': updatedCoins});
      } else {
        await FirebaseFirestore.instance.collection('coins').doc(userId).set({
          'totalCoins': updatedCoins,
        });
      }
    } catch (e) {
      print('Error updating coins in Firestore: $e');
    }
  }

  Future<void> proceedToPay() async {
    // Removed the early return for netAmount <= 0
    // Now, netAmount can be zero and still proceed with payment

    try {
      User? currentUser = _auth.currentUser;
      if (currentUser == null) return;
      String userId = currentUser.uid;

      await FirebaseFirestore.instance.collection('payments').add({
        'userId': userId,
        'totalPayment': netAmount,
        'electricalWasteWeight': totalElectricalWeight,
        'otherWasteWeight': totalOtherWeight,
        'timestamp': Timestamp.now(),
      });

      await updatePaymentStatus('wasteCollectionRequests', userId);
      await updatePaymentStatus('specialWasteRequests', userId);

      if (usedCoins) {
        await updateCoinsInFirestore(userId, remainingCoins);
      }

      await transferRemainingCoinsToBalance(userId);

      setState(() {
        totalPayment = 0.0;
        totalElectricalWeight = 0.0;
        totalOtherWeight = 0.0;
        if (!usedCoins) {
          totalCoins = 0.0;
        } else {
          discountFromCoins = 0.0;
          netAmount = 0.0;
          usedCoins = false;
          remainingCoins = 0.0;
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payment Successful!')),
      );
    } catch (e) {
      print('Error processing payment: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Payment Failed: $e')),
      );
    }
  }

  Future<void> transferRemainingCoinsToBalance(String userId) async {
    try {
      DocumentSnapshot balanceDoc = await FirebaseFirestore.instance
          .collection('balance')
          .doc(userId)
          .get();

      if (balanceDoc.exists) {
        await FirebaseFirestore.instance
            .collection('balance')
            .doc(userId)
            .update({
          'leftCoins': remainingCoins,
        });
      } else {
        await FirebaseFirestore.instance.collection('balance').doc(userId).set({
          'leftCoins': remainingCoins,
        });
      }
    } catch (e) {
      print('Error transferring remaining coins to balance: $e');
    }
  }

  Future<void> updatePaymentStatus(String collection, String userId) async {
    try {
      QuerySnapshot requests = await FirebaseFirestore.instance
          .collection(collection)
          .where('userId', isEqualTo: userId)
          .where('paymentStatus', isEqualTo: 'pending')
          .get();

      for (var requestDoc in requests.docs) {
        await FirebaseFirestore.instance
            .collection(collection)
            .doc(requestDoc.id)
            .update({'paymentStatus': 'paid'});
      }
    } catch (e) {
      print('Error updating payment status: $e');
    }
  }

  void useCoins() async {
    double coinsValue = totalCoins * 0.5;
    double maximumDiscount =
        totalPayment < coinsValue ? totalPayment : coinsValue;
    discountFromCoins = maximumDiscount;
    remainingCoins = totalCoins - (discountFromCoins * 2);

    final confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Use Coins'),
          content: Text(
              'Do you want to use your coins for a discount of \$${maximumDiscount.toStringAsFixed(2)}?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Yes'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('No'),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      setState(() {
        netAmount = totalPayment - maximumDiscount;
        usedCoins = true;
        totalCoins = remainingCoins; // Update totalCoins to reflect deduction
      });

      // Check if netAmount is zero, then auto proceed to pay
      if (netAmount == 0.0) {
        await proceedToPay();
      }
      // Else, allow user to manually proceed to pay
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text('Payment',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.teal,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildTotalPaymentCard(),
              const SizedBox(height: 20),
              _buildInfoCards(),
              const SizedBox(height: 20),
              if (usedCoins) _buildDiscountCard(),
              const SizedBox(height: 20),
              _buildNetAmountCard(),
              const SizedBox(height: 30),
              _buildActionButtons(),
              if (usedCoins) const SizedBox(height: 20),
              if (usedCoins) _buildRemainingCoinsCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTotalPaymentCard() {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              'Total Payment',
              style: GoogleFonts.poppins(fontSize: 18, color: Colors.grey[600]),
            ),
            const SizedBox(height: 10),
            Text(
              '\$${totalPayment.toStringAsFixed(2)}',
              style: GoogleFonts.poppins(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: Colors.teal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCards() {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _buildInfoCard(
            'Electrical Waste',
            '${totalElectricalWeight.toStringAsFixed(2)} kg',
            Icons.electrical_services,
            Colors.orange),
        _buildInfoCard(
            'Other Waste',
            '${totalOtherWeight.toStringAsFixed(2)} kg',
            Icons.delete_outline,
            Colors.green),
        _buildInfoCard('Total Coins', totalCoins.toStringAsFixed(0),
            Icons.monetization_on, Colors.purple),
        _buildInfoCard('Net Amount', '\$${netAmount.toStringAsFixed(2)}',
            Icons.account_balance_wallet, Colors.blue),
      ],
    );
  }

  Widget _buildInfoCard(
      String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 30, color: color),
            const SizedBox(height: 10),
            Text(title,
                style:
                    GoogleFonts.poppins(fontSize: 14, color: Colors.grey[600])),
            const SizedBox(height: 5),
            Text(value,
                style: GoogleFonts.poppins(
                    fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildDiscountCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      color: Colors.redAccent,
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Discount from Coins',
                style: GoogleFonts.poppins(fontSize: 16, color: Colors.white)),
            Text('-\$${discountFromCoins.toStringAsFixed(2)}',
                style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white)),
          ],
        ),
      ),
    );
  }

  Widget _buildNetAmountCard() {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      color: Colors.blue,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              'Net Amount',
              style: GoogleFonts.poppins(fontSize: 18, color: Colors.white),
            ),
            const SizedBox(height: 10),
            Text(
              '\$${(usedCoins ? netAmount : totalPayment).toStringAsFixed(2)}',
              style: GoogleFonts.poppins(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        ElevatedButton.icon(
          onPressed: totalCoins > 0 ? useCoins : null,
          icon: const Icon(Icons.credit_score),
          label: const Text('Use Coins for Discounts'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
            textStyle:
                GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
            backgroundColor: Colors.teal,
            foregroundColor: Colors.white,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            elevation: 5,
          ),
        ),
        const SizedBox(height: 15),
        ElevatedButton.icon(
          onPressed: proceedToPay,
          icon: const Icon(Icons.payment),
          label: const Text('Proceed to Pay'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
            textStyle:
                GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            elevation: 5,
          ),
        ),
      ],
    );
  }

  Widget _buildRemainingCoinsCard() {
    return Card(
      color: Colors.grey[200],
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(15.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Remaining Coins:',
              style: GoogleFonts.poppins(fontSize: 16, color: Colors.black87),
            ),
            Text(
              remainingCoins.toStringAsFixed(0),
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.purple,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class InfoCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const InfoCard({
    Key? key,
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(15.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 30, color: color),
            const SizedBox(height: 10),
            Text(
              label,
              style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[700]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 5),
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

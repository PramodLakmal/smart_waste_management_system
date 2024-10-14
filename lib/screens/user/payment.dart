import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:smart_waste_management_system/screens/user/cardDetails.dart';
import 'package:smart_waste_management_system/screens/user/history.dart';

class Payment extends StatefulWidget {
  const Payment({super.key});

  @override
  State<Payment> createState() => _PaymentState();
}

class _PaymentState extends State<Payment> {
  final Color darkGreen = const Color(0xFF2E7D32);
  final Color green = const Color(0xFF4CAF50);
  final Color lightGreen = const Color(0xFF81C784);
  final Color lightYellow = const Color(0xFFFFFDE7);
  double totalPayment = 0.0;
  double totalCoins = 0.0;
  double totalElectricalWeight = 0.0;
  double totalOtherWeight = 0.0;
  double grandTotal = 0.0;
  double discountFromCoins = 0.0;
  double netAmount = 0.0;
  bool usedCoins = false;
  double remainingCoins = 0.0;
  double penaltyAmount = 0.0; // Added penaltyAmount
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

    double computedNetAmount = totalPayment;
    double computedPenalty = 0.0;

    if (computedNetAmount > 1000) {
      computedPenalty = computedNetAmount * 0.05;
      computedNetAmount += computedPenalty;
    }

    setState(() {
      netAmount = computedNetAmount;
      penaltyAmount = computedPenalty; // Set penaltyAmount
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
        penaltyAmount = 0.0; // Reset penalty amount
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
      backgroundColor: Colors.white,
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth > 900) {
            return _buildWebLayout();
          } else {
            return _buildMobileLayout();
          }
        },
      ),
    );
  }

  Widget _buildWebLayout() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: _buildTotalPaymentCard(),
                  ),
                  const SizedBox(height: 20),
                  _buildInfoCards(),
                ],
              ),
            ),
            const SizedBox(width: 24),
            Expanded(
              flex: 1,
              child: Card(
                elevation: 8,
                color: lightYellow,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15)),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Payment Summary',
                        style: GoogleFonts.poppins(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: darkGreen,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      if (usedCoins) _buildDiscountCard(),
                      const SizedBox(height: 20),
                      _buildNetAmountCard(),
                      const SizedBox(height: 30),
                      _buildActionButtons(),
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

  Widget _buildMobileLayout() {
    return SingleChildScrollView(
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
          ],
        ),
      ),
    );
  }

  Widget _buildTotalPaymentCard() {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.amber, Colors.yellow],
          ),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Text(
                'Total Payment',
                style: GoogleFonts.poppins(
                    fontSize: 18,
                    color: darkGreen,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Text(
                '\$${totalPayment.toStringAsFixed(2)}',
                style: GoogleFonts.poppins(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              if (totalPayment > 800)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(
                    'Warning: You will be fined if the total exceeds \$1000',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.red,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCards() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return GridView.count(
          crossAxisCount: constraints.maxWidth > 600 ? 4 : 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _buildInfoCard(
                'Electrical Waste',
                '${totalElectricalWeight.toStringAsFixed(2)} kg',
                Icons.electrical_services),
            _buildInfoCard(
                'Other Waste',
                '${totalOtherWeight.toStringAsFixed(2)} kg',
                Icons.delete_outline),
            _buildInfoCard('Total Coins', totalCoins.toStringAsFixed(0),
                Icons.monetization_on),
            _buildInfoCard(
              'Penalty Amount',
              '\$${penaltyAmount.toStringAsFixed(2)}',
              Icons.warning,
            ),
          ],
        );
      },
    );
  }

  Widget _buildInfoCard(String title, String value, IconData icon) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [lightGreen, green],
          ),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 30, color: Colors.black),
              const SizedBox(height: 10),
              Text(title,
                  style: GoogleFonts.poppins(fontSize: 14, color: Colors.black),
                  textAlign: TextAlign.center),
              const SizedBox(height: 5),
              Text(value,
                  style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black),
                  textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDiscountCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      color: lightGreen,
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Discount from Coins',
                style: GoogleFonts.poppins(fontSize: 16, color: Colors.black)),
            Text('-\$${discountFromCoins.toStringAsFixed(2)}',
                style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black)),
          ],
        ),
      ),
    );
  }

  Widget _buildNetAmountCard() {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [green, darkGreen],
          ),
          borderRadius: BorderRadius.circular(15),
        ),
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
                '\$${netAmount.toStringAsFixed(2)}',
                style: GoogleFonts.poppins(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        const SizedBox(height: 15),
        SizedBox(
          width: double.infinity, // Make the button take full available width
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (context) => AddCardDetails()));
            },
            icon: const Icon(Icons.credit_card),
            label: const Text('Add Card Details'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
              textStyle: GoogleFonts.poppins(
                  fontSize: 16, fontWeight: FontWeight.w600),
              backgroundColor: Colors.blue, // Button color
              foregroundColor: Colors.white, // Text color
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              elevation: 5,
            ),
          ),
        ),
        const SizedBox(height: 15),
        SizedBox(
          width: double.infinity, // Make the button take full available width
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (context) => PaymentHistory()));
            },
            icon: const Icon(Icons.history),
            label: const Text('View Payment History'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
              textStyle: GoogleFonts.poppins(
                  fontSize: 16, fontWeight: FontWeight.w600),
              backgroundColor: darkGreen,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              elevation: 5,
            ),
          ),
        ),
        const SizedBox(height: 15),
        SizedBox(
          width: double.infinity, // Make the button take full available width
          child: ElevatedButton.icon(
            onPressed: totalCoins > 0 ? useCoins : null,
            icon: const Icon(Icons.monetization_on),
            label: const Text('Use Coins for Discounts'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
              textStyle: GoogleFonts.poppins(
                  fontSize: 16, fontWeight: FontWeight.w600),
              backgroundColor: green,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              elevation: 5,
            ),
          ),
        ),
        const SizedBox(height: 15),
        SizedBox(
          width: double.infinity, // Make the button take full available width
          child: ElevatedButton.icon(
            onPressed: proceedToPay,
            icon: const Icon(Icons.payment),
            label: const Text('Proceed to Pay'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
              textStyle: GoogleFonts.poppins(
                  fontSize: 16, fontWeight: FontWeight.w600),
              backgroundColor: Colors.amber,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              elevation: 5,
            ),
          ),
        ),
      ],
    );
  }
}

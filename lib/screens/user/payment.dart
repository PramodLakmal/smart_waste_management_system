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
  double grandTotal = 0.0; // To hold the grand total after applying coins
  double discountFromCoins = 0.0; // Discount you get from coins
  double netAmount = 0.0; // Net amount after using coins or not
  bool usedCoins = false; // Tracks if user used coins or not
  double remainingCoins = 0.0; // To track coins after deduction for payment
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    calculateTotalAmount();
    fetchCurrentCoins(); // Fetch current coins on initialization
  }

  Future<void> fetchCurrentCoins() async {
    User? currentUser = _auth.currentUser;
    if (currentUser != null) {
      String userId = currentUser.uid;
      DocumentSnapshot coinsDoc = await FirebaseFirestore.instance
          .collection('coins')
          .doc(userId)
          .get();

      // Initialize totalCoins with the value from Firestore
      if (coinsDoc.exists) {
        setState(() {
          totalCoins = coinsDoc['totalCoins'] ?? 0.0;
        });
      }
    }
  }

  Future<void> calculateTotalAmount() async {
    // Calculate coins from wasteCollectionTotals
    double coinsFromCollectionTotals = await calculateWasteCollectionTotals();

    // Pass the coins to calculateSpecialWasteTotals
    await calculateSpecialWasteTotals(coinsFromCollectionTotals);

    // By default, set net amount as totalPayment (when no coins are used)
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
      double electricalWasteCoins = 0.0; // Coins earned from electrical waste

      for (var requestDoc in wasteCollectionRequests.docs) {
        var requestData = requestDoc.data() as Map<String, dynamic>;
        String binId = requestData['binId'];

        DocumentSnapshot binDoc = await FirebaseFirestore.instance
            .collection('bins')
            .doc(binId)
            .get();

        if (binDoc.exists) {
          var binData = binDoc.data() as Map<String, dynamic>;
          String type = binData['type'];
          double weight = binData['weight'];

          if (type == 'Electrical Waste') {
            electricalWasteCoins += weight; // 1 coin per kg of electrical waste
            totalElectricalWeight += weight; // Update total electrical weight
          } else {
            double amount = weight * 2;
            otherWasteTotal += amount;
            totalOtherWeight += weight; // Update total other weight
          }
        }
      }

      // Update totalPayment with the total for non-electrical waste
      setState(() {
        totalPayment += otherWasteTotal;
      });

      return electricalWasteCoins; // Return coins earned from this method
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
        List<dynamic> wasteTypes = requestData['wasteTypes'];

        for (var wasteType in wasteTypes) {
          String type = wasteType['type'];
          double weight = wasteType['weight'];

          if (type == 'Electrical Waste') {
            electricalWasteCoins += weight; // 1 coin per kg of electrical waste
            totalElectricalWeight += weight; // Update total electrical weight
          } else {
            totalOtherWeight +=
                weight; // Update total other weight for non-electrical waste
            totalPayment +=
                weight * 2; // Only accumulate payment for other waste
          }
        }
      }

      // Add coins from wasteCollectionTotals
      electricalWasteCoins += coinsFromCollectionTotals;

      // Only update totalCoins with electrical waste coins
      if (electricalWasteCoins > 0) {
        DocumentSnapshot balanceDoc = await FirebaseFirestore.instance
            .collection('balance')
            .doc(userId)
            .get();

        double leftCoins =
            balanceDoc.exists ? balanceDoc['leftCoins'] ?? 0.0 : 0.0;

        // Calculate the new total coins
        totalCoins =
            leftCoins + electricalWasteCoins; // Add coins from both sources

        // Store the new total in Firestore
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
        // Update the totalCoins in Firestore with the updatedCoins value
        await FirebaseFirestore.instance
            .collection('coins')
            .doc(userId)
            .update({'totalCoins': updatedCoins});
      } else {
        // If the document does not exist, create it with the updated coins
        await FirebaseFirestore.instance.collection('coins').doc(userId).set({
          'totalCoins': updatedCoins,
        });
      }
    } catch (e) {
      print('Error updating coins in Firestore: $e');
    }
  }

  Future<void> proceedToPay() async {
    if (totalPayment <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No payments yet.')),
      );
      return;
    }

    try {
      User? currentUser = _auth.currentUser;
      if (currentUser == null) return;
      String userId = currentUser.uid;

      // Store payment details in Firestore
      await FirebaseFirestore.instance.collection('payments').add({
        'userId': userId,
        'totalPayment': netAmount, // Use netAmount if coins are applied
        'electricalWasteWeight': totalElectricalWeight,
        'otherWasteWeight': totalOtherWeight,
        'timestamp': Timestamp.now(),
      });

      // Update the payment status of related waste requests
      await updatePaymentStatus('wasteCollectionRequests', userId);
      await updatePaymentStatus('specialWasteRequests', userId);

      // Update remaining coins in Firestore after successful payment
      if (usedCoins) {
        await updateCoinsInFirestore(userId, remainingCoins);
      }

      // Transfer remaining coins to balance collection
      await transferRemainingCoinsToBalance(userId);

      // Reset the UI state
      setState(() {
        totalPayment = 0.0;
        totalElectricalWeight = 0.0;
        totalOtherWeight = 0.0;
        if (!usedCoins) {
          totalCoins = 0.0; // Reset coins in UI only if coins weren't used
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

  // New method to handle coin usage confirmation without updating Firestore
  void useCoins() async {
    double coinsValue = totalCoins * 0.5; // Each coin is worth $0.5
    double maximumDiscount = totalPayment < coinsValue
        ? totalPayment
        : coinsValue; // Cap discount to total payment
    discountFromCoins = maximumDiscount;
    remainingCoins = (totalCoins) -
        discountFromCoins * 2; // Calculate remaining coins after usage

    // Show confirmation dialog before proceeding
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
        // Apply maximum discount to net amount
        netAmount = totalPayment - maximumDiscount;
        usedCoins = true;
      });

      proceedToPay(); // Proceed with the payment after confirmation
    }
  }

  @override
  Widget build(BuildContext context) {
    // Determine screen size for responsiveness
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment'),
        backgroundColor: Colors.teal, // Enhanced AppBar color
        centerTitle: true,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          // Determine if the screen is wide (web) or narrow (mobile)
          bool isWideScreen = constraints.maxWidth > 600;

          return SingleChildScrollView(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Grid for Info Cards
                    GridView(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: isWideScreen ? 3 : 1,
                        crossAxisSpacing: 16.0,
                        mainAxisSpacing: 16.0,
                        childAspectRatio: isWideScreen ? 1.5 : 3,
                      ),
                      children: [
                        // First Row: Total Payment (spans all columns on wide screens)
                        if (isWideScreen)
                          InfoCard(
                            icon: Icons.attach_money,
                            label: 'Total Payment',
                            value: '\$${totalPayment.toStringAsFixed(2)}',
                            color: Colors.teal,
                            span: 3, // Span all three columns
                          ),
                        if (!isWideScreen)
                          InfoCard(
                            icon: Icons.attach_money,
                            label: 'Total Payment',
                            value: '\$${totalPayment.toStringAsFixed(2)}',
                            color: Colors.teal,
                          ),
                        // Second Row: Three Cards
                        InfoCard(
                          icon: Icons.electrical_services,
                          label: 'Electrical Waste Weight',
                          value:
                              '${totalElectricalWeight.toStringAsFixed(2)} kg',
                          color: Colors.orange,
                        ),
                        InfoCard(
                          icon: Icons.recycling,
                          label: 'Other Waste Weight',
                          value: '${totalOtherWeight.toStringAsFixed(2)} kg',
                          color: Colors.green,
                        ),
                        InfoCard(
                          icon: Icons.monetization_on,
                          label: 'Total Coins',
                          value: '${totalCoins.toStringAsFixed(0)}',
                          color: Colors.purple,
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),
                    // Conditional Discount from Coins Card
                    if (usedCoins)
                      InfoCard(
                        icon: Icons.discount,
                        label: 'Discount from Coins',
                        value: '-\$${discountFromCoins.toStringAsFixed(2)}',
                        color: Colors.redAccent,
                      ),
                    if (usedCoins) const SizedBox(height: 15),
                    // Net Amount Card
                    InfoCard(
                      icon: Icons.account_balance_wallet,
                      label: 'Net Amount',
                      value: usedCoins
                          ? '\$${netAmount.toStringAsFixed(2)}'
                          : '\$${totalPayment.toStringAsFixed(2)}',
                      color: Colors.blue,
                    ),
                    const SizedBox(height: 30),
                    // Action Buttons
                    Column(
                      children: [
                        // Use Coins Button
                        ElevatedButton.icon(
                          onPressed: totalCoins > 0 ? useCoins : null,
                          icon: const Icon(Icons.credit_score),
                          label: const Text('Use Coins for Discounts'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            textStyle: GoogleFonts.poppins(
                                fontSize: 16, fontWeight: FontWeight.w600),
                            backgroundColor: Colors.teal, // Button color
                            foregroundColor: Colors.white, // Text color
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            elevation: 5,
                          ),
                        ),
                        const SizedBox(height: 15),
                        // Proceed to Pay Button
                        ElevatedButton.icon(
                          onPressed: proceedToPay,
                          icon: const Icon(Icons.payment),
                          label: const Text('Proceed to Pay'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            textStyle: GoogleFonts.poppins(
                                fontSize: 16, fontWeight: FontWeight.w600),
                            backgroundColor: Colors.orange, // Button color
                            foregroundColor: Colors.white, // Text color
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            elevation: 5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),
                    // Optional: Display remaining coins after usage
                    if (usedCoins)
                      Card(
                        color: Colors.grey[100],
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(15.0),
                          child: Text(
                            'Remaining Coins: ${(remainingCoins).toStringAsFixed(0)}',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              color: Colors.black87,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// Custom widget for displaying information cards with icons
class InfoCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final int span; // Number of columns to span (default is 1)

  const InfoCard({
    Key? key,
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.span = 1,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Adjust the card's height based on the content
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            // Icon with color
            Icon(
              icon,
              color: color,
              size: 28,
            ),
            const SizedBox(width: 15),
            // Label and Value
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    value,
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

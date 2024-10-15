import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/special_collection_request_model.dart';

class SpecialWasteRequestService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Submit a new special waste request
  Future<void> submitSpecialWasteRequest({
    required String userId,
    required String address,
    required String city,
    required String description,
    required DateTime scheduledDate,
    required List<WasteType> wasteTypes,
  }) async {
    DateTime requestTime = DateTime.now();

    await _db.collection('specialWasteRequests').add({
      'userId': userId,
      'address': address,
      'city': city,
      'description': description,
      'requestTime': requestTime.toIso8601String(),
      'scheduledDate': scheduledDate.toIso8601String(),
      'status': 'pending',
      'wasteTypes': wasteTypes.map((waste) => waste.toMap()).toList(),
      'paymentStatus': 'pending',
    });
  }

  // Fetch all special waste requests for a specific user
  Stream<List<SpecialWasteRequest>> getUserRequests(String userId) {
    return _db
        .collection('specialWasteRequests')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => SpecialWasteRequest.fromDocument(doc))
            .toList());
  }

  // Fetch pending requests for admin view
  Stream<List<SpecialWasteRequest>> getPendingRequests() {
    return _db
        .collection('specialWasteRequests')
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => SpecialWasteRequest.fromDocument(doc))
            .toList());
  }

  // Mark a request as collected/processed
  Future<void> markAsProcessed(String requestId) async {
    await _db.collection('specialWasteRequests').doc(requestId).update({
      'status': 'processed',
    });
  }

  // Update the payment status
  Future<void> updatePaymentStatus(String requestId, String status) async {
    await _db.collection('specialWasteRequests').doc(requestId).update({
      'paymentStatus': status,
    });
  }
}

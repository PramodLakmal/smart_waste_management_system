import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/collection_request_model.dart';

class WasteCollectionService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Send a new waste collection request
  Future<void> sendWasteCollectionRequest({
    required String binId,
    required String userId,
    required String binNickname,
  }) async {
    try {
      // Create a new collection request in Firestore
      await _db.collection('wasteCollectionRequests').add({
        'userId': userId,
        'binId': binId,
        'requestedTime': FieldValue.serverTimestamp(),
        'isCollected': false,
        'isScheduled': false,
        'paymentStatus': 'pending',
      });

      // Update the bin to mark that a collection request has been sent
      await _db.collection('bins').doc(binId).update({
        'collectionRequestSent': true,
      });
    } catch (e) {
      print('Error sending waste collection request: $e');
      throw Exception('Failed to send waste collection request');
    }
  }

  // Fetch all waste collection requests for a specific user
  Stream<List<WasteCollectionRequest>> getUserCollectionRequests(String userId) {
    return _db
        .collection('wasteCollectionRequests')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => WasteCollectionRequest.fromDocument(doc))
            .toList());
  }

  // Fetch all collection requests that are pending for admin view
  Stream<List<WasteCollectionRequest>> getPendingCollectionRequests() {
    return _db
        .collection('wasteCollectionRequests')
        .where('isCollected', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => WasteCollectionRequest.fromDocument(doc))
            .toList());
  }

  // Mark a collection request as collected
  Future<void> markAsCollected(String requestId, String binId) async {
    try {
      // Mark the waste collection request as collected
      await _db
          .collection('wasteCollectionRequests')
          .doc(requestId)
          .update({'isCollected': true});

      // Reset the bin's filled percentage and mark that no collection request is pending
      await _db.collection('bins').doc(binId).update({
        'collectionRequestSent': false,
        'filledPercentage': 0,
      });
    } catch (e) {
      print('Error marking request as collected: $e');
      throw Exception('Failed to mark request as collected');
    }
  }

  // Schedule a collection for a specific waste request
  Future<void> scheduleCollection(String requestId) async {
    try {
      await _db.collection('wasteCollectionRequests').doc(requestId).update({
        'isScheduled': true,
      });
    } catch (e) {
      print('Error scheduling collection: $e');
      throw Exception('Failed to schedule collection');
    }
  }
}

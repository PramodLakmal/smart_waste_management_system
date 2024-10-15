import 'package:cloud_firestore/cloud_firestore.dart';

class WasteCollectionRequest {
  String requestId; // Firestore-generated ID for the request
  String userId; // ID of the user who made the request
  String binId; // ID of the bin for which the request is made
  Timestamp requestedTime; // Time when the request was made
  bool isCollected; // Whether the bin has been collected
  bool isScheduled; // Whether the collection has been scheduled
  String paymentStatus; // Payment status, e.g., 'pending', 'paid'

  WasteCollectionRequest({
    required this.requestId,
    required this.userId,
    required this.binId,
    required this.requestedTime,
    required this.isCollected,
    required this.isScheduled,
    required this.paymentStatus,
  });

  // Convert a WasteCollectionRequest to a map to send it to Firestore
  Map<String, dynamic> toMap() {
    return {
      'requestId': requestId,
      'userId': userId,
      'binId': binId,
      'requestedTime': requestedTime,
      'isCollected': isCollected,
      'isScheduled': isScheduled,
      'paymentStatus': paymentStatus,
    };
  }

  // Create a WasteCollectionRequest object from a Firestore document
  factory WasteCollectionRequest.fromDocument(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return WasteCollectionRequest(
      requestId: doc.id,
      userId: data['userId'],
      binId: data['binId'],
      requestedTime: data['requestedTime'],
      isCollected: data['isCollected'],
      isScheduled: data['isScheduled'],
      paymentStatus: data['paymentStatus'],
    );
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';

class SpecialWasteRequest {
  final String id;
  final String userId;
  final String address;
  final String city;
  final String description;
  final DateTime requestTime;
  final DateTime scheduledDate;
  final String status;
  final List<WasteType> wasteTypes;
  final String paymentStatus;

  SpecialWasteRequest({
    required this.id,
    required this.userId,
    required this.address,
    required this.city,
    required this.description,
    required this.requestTime,
    required this.scheduledDate,
    required this.status,
    required this.wasteTypes,
    required this.paymentStatus,
  });

  // Convert Firestore document to SpecialWasteRequest object
  factory SpecialWasteRequest.fromDocument(DocumentSnapshot doc) {
    return SpecialWasteRequest(
      id: doc.id,
      userId: doc['userId'],
      address: doc['address'],
      city: doc['city'],
      description: doc['description'],
      requestTime: (doc['requestTime'] as Timestamp).toDate(),
      scheduledDate: (doc['scheduledDate'] as Timestamp).toDate(),
      status: doc['status'],
      wasteTypes: (doc['wasteTypes'] as List)
          .map((item) => WasteType.fromMap(item))
          .toList(),
      paymentStatus: doc['paymentStatus'],
    );
  }

  // Convert SpecialWasteRequest object to map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'address': address,
      'city': city,
      'description': description,
      'requestTime': requestTime,
      'scheduledDate': scheduledDate,
      'status': status,
      'wasteTypes': wasteTypes.map((type) => type.toMap()).toList(),
      'paymentStatus': paymentStatus,
    };
  }
}

// WasteType class to represent different types of waste in the request
class WasteType {
  final String type;
  final double weight;

  WasteType({required this.type, required this.weight});

  factory WasteType.fromMap(Map<String, dynamic> data) {
    return WasteType(
      type: data['type'],
      weight: (data['weight'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'weight': weight,
    };
  }
}

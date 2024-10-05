import 'package:cloud_firestore/cloud_firestore.dart';

class WasteRecord {
  String id;
  String wasteType;
  double weight;
  String routeId;
  String status;

  WasteRecord({this.id = '', required this.wasteType, required this.weight, required this.routeId, required this.status});

  Map<String, dynamic> toMap() {
    return {
      'wasteType': wasteType,
      'weight': weight,
      'routeId': routeId,
      'status': status,
    };
  }

  factory WasteRecord.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return WasteRecord(
      id: doc.id,
      wasteType: data['wasteType'] ?? '',
      weight: data['weight']?.toDouble() ?? 0,
      routeId: data['routeId'] ?? '',
      status: data['status'] ?? 'pending',
    );
  }
}

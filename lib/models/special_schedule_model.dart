import 'package:cloud_firestore/cloud_firestore.dart';

class SpecialSchedule {
  String? id;
  String address;
  String city;
  String requestId; // Changed from userId to requestId
  DateTime scheduledDate;
  String status; // 'pending', 'completed'
  String wasteCollector; // Added wasteCollector
  String wasteCollectorId; // Added wasteCollectorId
  List<WasteType> wasteTypes;

  SpecialSchedule({
    this.id,
    required this.address,
    required this.city,
    required this.requestId, // Changed from userId to requestId
    required this.scheduledDate,
    required this.status,
    required this.wasteCollector, // Added wasteCollector
    required this.wasteCollectorId, // Added wasteCollectorId
    required this.wasteTypes,
  });

  factory SpecialSchedule.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return SpecialSchedule(
      id: doc.id,
      address: data['address'],
      city: data['city'],
      requestId: data['requestId'], // Changed from userId to requestId
      scheduledDate: DateTime.parse(data['scheduledDate']), // Parse string to DateTime
      status: data['status'],
      wasteCollector: data['wasteCollector'], // Added wasteCollector
      wasteCollectorId: data['wasteCollectorId'], // Added wasteCollectorId
      wasteTypes: (data['wasteTypes'] as List).map((w) => WasteType.fromMap(w)).toList(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'address': address,
      'city': city,
      'requestId': requestId, // Changed from userId to requestId
      'scheduledDate': scheduledDate.toIso8601String(),
      'status': status,
      'wasteCollector': wasteCollector, // Added wasteCollector
      wasteCollectorId: wasteCollectorId, // Added wasteCollectorId
      'wasteTypes': wasteTypes.map((w) => w.toMap()).toList(),
    };
  }
}

class WasteType {
  String type;
  int weight;

  WasteType({
    required this.type,
    required this.weight,
  });

  factory WasteType.fromMap(Map<String, dynamic> data) {
    return WasteType(
      type: data['type'],
      weight: data['weight'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'weight': weight,
    };
  }
}

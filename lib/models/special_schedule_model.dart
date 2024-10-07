import 'package:cloud_firestore/cloud_firestore.dart';

class SpecialSchedule {
  String? id;
  String address;
  String city;
  String description;
  DateTime requestTime;
  DateTime scheduledDate;
  String status; // 'pending', 'completed'
  String userId;
  List<WasteType> wasteTypes;

  SpecialSchedule({
    this.id,
    required this.address,
    required this.city,
    required this.description,
    required this.requestTime,
    required this.scheduledDate,
    required this.status,
    required this.userId,
    required this.wasteTypes,
  });

  factory SpecialSchedule.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return SpecialSchedule(
      id: doc.id,
      address: data['address'],
      city: data['city'],
      description: data['description'],
      requestTime: DateTime.parse(data['requestTime']),
      scheduledDate: DateTime.parse(data['scheduledDate']),
      status: data['status'],
      userId: data['userId'],
      wasteTypes: (data['wasteTypes'] as List).map((w) => WasteType.fromMap(w)).toList(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'address': address,
      'city': city,
      'description': description,
      'requestTime': requestTime.toIso8601String(),
      'scheduledDate': scheduledDate.toIso8601String(),
      'status': status,
      'userId': userId,
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

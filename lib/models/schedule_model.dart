import 'package:cloud_firestore/cloud_firestore.dart';

class Schedule {
  String? id;
  String collectionZone;
  String vehicleNumber;
  String wasteCollector;
  DateTime startTime;
  DateTime endTime;
  String location;
  String status; // 'pending', 'completed'
  
  Schedule({
    this.id,
    required this.collectionZone,
    required this.vehicleNumber,
    required this.wasteCollector,
    required this.startTime,
    required this.endTime,
    required this.location,
    this.status = 'pending',
  });

  factory Schedule.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Schedule(
      id: doc.id,
      collectionZone: data['collectionZone'],
      vehicleNumber: data['vehicleNumber'],
      wasteCollector: data['wasteCollector'],
      startTime: (data['startTime'] as Timestamp).toDate(),
      endTime: (data['endTime'] as Timestamp).toDate(),
      location: data['location'],
      status: data['status'] ?? 'pending',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'collectionZone': collectionZone,
      'vehicleNumber': vehicleNumber,
      'wasteCollector': wasteCollector,
      'startTime': Timestamp.fromDate(startTime),
      'endTime': Timestamp.fromDate(endTime),
      'location': location,
      'status': status,
    };
  }
}

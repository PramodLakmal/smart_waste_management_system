import 'package:cloud_firestore/cloud_firestore.dart';

class Schedule {
  String? id;
  String city;
  String vehicleNumber;
  String wasteCollector;
  DateTime startTime;
  DateTime endTime;
  String status; // 'pending', 'completed'
   List<String> userIds; // Add this field for user IDs
  
  Schedule({
    this.id,
    required this.city,
    required this.vehicleNumber,
    required this.wasteCollector,
    required this.startTime,
    required this.endTime,
    this.status = 'pending',
     this.userIds = const [], // Initialize an empty list
  });

  factory Schedule.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Schedule(
      id: doc.id,
      city: data['city'],
      vehicleNumber: data['vehicleNumber'],
      wasteCollector: data['wasteCollector'],
      startTime: (data['startTime'] as Timestamp).toDate(),
      endTime: (data['endTime'] as Timestamp).toDate(),
      status: data['status'] ?? 'pending',
      userIds: List<String>.from(data['userIds'] ?? []), // Handle the userIds field
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'city': city,
      'vehicleNumber': vehicleNumber,
      'wasteCollector': wasteCollector,
      'startTime': Timestamp.fromDate(startTime),
      'endTime': Timestamp.fromDate(endTime),
      'status': status,
       'userIds': userIds, 
    };
  }
}

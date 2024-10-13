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
  final List<String> bins;// Add this field for bin IDs
  final String wasteCollectorId; // Add wasteCollectorId field
  bool isScheduled; // Add this field for scheduled status

  Schedule({
    this.id,
    required this.city,
    required this.vehicleNumber,
    required this.wasteCollector,
    required this.startTime,
    required this.endTime,
    this.status = 'pending',
    this.userIds = const [], // Initialize an empty list
    this.bins = const [], // Initialize an empty list
    required this.wasteCollectorId, // Initialize wasteCollectorId
    this.isScheduled = false, // Default to false
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
      bins: List<String>.from(data['bins'] ?? []), // Handle the bins field
      wasteCollectorId: data['wasteCollectorId'], // Handle the wasteCollectorId field
      isScheduled: data['isScheduled'] ?? false, // Handle the isScheduled field
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
      'bins': bins, // Include bins in the map
      'wasteCollectorId': wasteCollectorId, // Include wasteCollectorId in the map
      'isScheduled': isScheduled, // Include isScheduled in the map
    };
  }
}

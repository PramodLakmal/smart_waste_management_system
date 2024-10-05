// In your WasteRecord model
import 'package:cloud_firestore/cloud_firestore.dart';

class WasteRecord {
  final String id;
  final String wasteType;
  final double weight;
  final String wasteCollector;
  final String status; // New variable for status

  WasteRecord({
    required this.id,
    required this.wasteType,
    required this.weight,
    required this.wasteCollector,
    required this.status,
  });

  factory WasteRecord.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map;

    return WasteRecord(
      id: doc.id,
      wasteType: data['wasteType'] ?? '',
      weight: (data['weight'] ?? 0).toDouble(),
      wasteCollector: data['wasteCollector'] ?? '', status: data['status'] ?? '',
    );
  }
}

// In your WasteRecord model
import 'package:cloud_firestore/cloud_firestore.dart';

class WasteRecord {
  final String id;
  final String wasteType;
  final double weight;
  final String wasteCollector;

  WasteRecord({
    required this.id,
    required this.wasteType,
    required this.weight,
    required this.wasteCollector,
  });

  factory WasteRecord.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map;

    return WasteRecord(
      id: doc.id,
      wasteType: data['wasteType'] ?? '',
      weight: (data['weight'] ?? 0).toDouble(),
      wasteCollector: data['wasteCollector'] ?? '',
    );
  }
}

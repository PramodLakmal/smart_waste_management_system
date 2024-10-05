// services/waste_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smart_waste_management_system/models/schedule_model.dart';
import '../models/waste_record_model.dart';

class WasteService {
  final CollectionReference wasteRecordsCollection =
      FirebaseFirestore.instance.collection('wasteRecords');

  // Fetch waste records for a specific waste collector
  Future<List<WasteRecord>> fetchWasteRecordsByCollector(String wasteCollector) async {
    try {
      QuerySnapshot querySnapshot = await wasteRecordsCollection
          .where('wasteCollector', isEqualTo: wasteCollector)
          .get();

      return querySnapshot.docs
          .map((doc) => WasteRecord.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error fetching waste records: $e');
      return [];
    }
  }

  // Add new waste record to Firestore
  Future<void> addWasteRecord(WasteRecord wasteRecord) async {
    try {
      await wasteRecordsCollection.add({
        'wasteType': wasteRecord.wasteType,
        'weight': wasteRecord.weight,
        'wasteCollector': wasteRecord.wasteCollector,
      });
    } catch (e) {
      print('Error adding waste record: $e');
      throw e;
    }
  }
}


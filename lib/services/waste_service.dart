// services/waste_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
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
        'status': wasteRecord.status,
      });
    } catch (e) {
      print('Error adding waste record: $e');
      rethrow;
    }
  }

  // Update waste record status
  Future<void> updateWasteStatus(String id, String status) async {
    try {
      await wasteRecordsCollection.doc(id).update({'status': status});
    } catch (e) {
      print('Error updating waste record status: $e');
      rethrow;
    }
  }

  Future<double> calculateTotalWaste(String wasteCollector) async {
    try {
      QuerySnapshot querySnapshot = await wasteRecordsCollection
          .where('wasteCollector', isEqualTo: wasteCollector)
          .get();

      double totalWeight = querySnapshot.docs
          .map((doc) => WasteRecord.fromFirestore(doc))
          .fold(0.0, (sum, record) => sum + record.weight);

      return totalWeight;
    } catch (e) {
      print('Error calculating total waste: $e');
      return 0.0;
    }
  }
}


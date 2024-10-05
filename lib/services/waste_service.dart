import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smart_waste_management_system/models/waste_record_model.dart';

class WasteService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> addWasteRecord(WasteRecord wasteRecord) async {
    await _db.collection('waste_records').add(wasteRecord.toMap());
  }

  Future<List<WasteRecord>> getWasteRecordsByRoute(String routeId) async {
    QuerySnapshot snapshot = await _db.collection('waste_records').where('routeId', isEqualTo: routeId).get();
    return snapshot.docs.map((doc) => WasteRecord.fromFirestore(doc)).toList();
  }
}

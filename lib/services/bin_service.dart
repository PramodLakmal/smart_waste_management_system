import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import '../models/bin_model.dart';

class BinService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Add a new bin with image upload
  Future<void> addBin(Bin bin, File imageFile) async {
    // Upload the image to Firebase Storage
    final imageRef = _storage.ref().child('bin_images/${bin.binId}');
    await imageRef.putFile(imageFile);
    final imageUrl = await imageRef.getDownloadURL();

    // Set the imageUrl in the bin object and add to Firestore
    bin.imageUrl = imageUrl;
    await _db.collection('bins').doc(bin.binId).set(bin.toMap());
  }

  // Fetch bins for a specific user
  Stream<List<Bin>> getBinsForUser(String userId) {
    return _db
        .collection('bins')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Bin.fromDocument(doc)).toList());
  }

  // Confirm a bin (admin functionality)
  Future<void> confirmBin(String binId) async {
    await _db.collection('bins').doc(binId).update({'confirmed': true});
  }

  // Fetch bins awaiting confirmation (for admin)
  Stream<List<Bin>> getUnconfirmedBins() {
    return _db
        .collection('bins')
        .where('confirmed', isEqualTo: false)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Bin.fromDocument(doc)).toList());
  }

  // Fetch bins assigned to a specific waste collector
  Stream<List<Bin>> getBinsForCollector(String wasteCollector) {
    return _db
        .collection('bins')
        .where('wasteCollector', isEqualTo: wasteCollector)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Bin.fromDocument(doc)).toList());
  }

  // Mark a bin as collected, resetting its filled percentage and collection status
  Future<void> markBinAsCollected(String binId) async {
    await _db.collection('bins').doc(binId).update({
      'collectionRequestSent': false,
      'filledPercentage': 0,
    });
  }
}

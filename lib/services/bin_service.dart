import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import '../models/bin_model.dart';

class BinService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Add a new bin
  Future<void> addBin(Bin bin, File imageFile) async {
    // Upload image to Firebase Storage
    final imageRef = _storage.ref().child('bin_images/${bin.id}');
    await imageRef.putFile(imageFile);
    final imageUrl = await imageRef.getDownloadURL();

    // Add bin to Firestore with the image URL
    bin.imageUrl = imageUrl;
    await _db.collection('bins').doc(bin.id).set(bin.toMap());
  }

  // Fetch bins for a specific user
  Stream<List<Bin>> getBinsForUser(String userId) {
    return _db
        .collection('bins')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Bin.fromDocument(doc)).toList());
  }

  // Confirm bin (admin)
  Future<void> confirmBin(String binId) async {
    await _db.collection('bins').doc(binId).update({'isConfirmed': true});
  }

  // Fetch bins awaiting confirmation (for admin)
  Stream<List<Bin>> getUnconfirmedBins() {
    return _db
        .collection('bins')
        .where('isConfirmed', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Bin.fromDocument(doc)).toList());
  }

  Stream<List<Bin>> getBinsForCollector(String wasteCollector) {
    return _db
        .collection('bins')
        .where('wasteCollector', isEqualTo: wasteCollector)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Bin.fromDocument(doc)).toList());
  }

  getBinsForCollectorByAddress(String wasteCollector) {
    return _db
        .collection('bins')
        .where('wasteCollector', isEqualTo: wasteCollector)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Bin.fromDocument(doc)).toList());
  }

  markBinAsCollected(String binId) {
    return _db.collection('bins').doc(binId).update({
      'collectionRequestSent': false,
      'filledPercentage': 0,
    });
  }
}

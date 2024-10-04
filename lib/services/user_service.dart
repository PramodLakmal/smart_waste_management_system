import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Fetch user details by UID
  Future<UserModel?> getUserById(String uid) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('users').doc(uid).get();

      // Check if the document exists
      if (doc.exists) {
        // Use fromDocument to create a UserModel from the DocumentSnapshot
        return UserModel.fromDocument(doc);
      } else {
        return null;  // If no user found, return null
      }
    } catch (e) {
      print(e.toString());
      return null;
    }
  }

  // Update user profile
  Future<void> updateUser(UserModel userModel) async {
    await _firestore.collection('users').doc(userModel.uid).update(userModel.toMap());
  }
}

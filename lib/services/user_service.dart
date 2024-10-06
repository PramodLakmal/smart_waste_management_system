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

  // Fetch all users
  Stream<List<UserModel>> getUsers() {
    return _firestore.collection('users').snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => UserModel.fromDocument(doc)).toList());
  }

  // Fetch users by role
  Stream<List<UserModel>> getUsersByRole(String role) {
    return _firestore
        .collection('users')
        .where('role', isEqualTo: role)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => UserModel.fromDocument(doc)).toList());
  }

  // Fetch users by role and status
  Stream<List<UserModel>> getUsersByRoleAndStatus(String role, bool isActive) {
    return _firestore
        .collection('users')
        .where('role', isEqualTo: role)
        .where('isActive', isEqualTo: isActive)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => UserModel.fromDocument(doc)).toList());
  }

  //Get user by address
  Stream<List<UserModel>> getUsersByAddress(String address) {
    return _firestore
        .collection('users')
        .where('address', isEqualTo: address)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => UserModel.fromDocument(doc)).toList());
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  String uid; // User ID
  String email; // User email
  String name; // User name
  String phone; // User phone number
  String role; // User role (e.g., 'admin', 'user', etc.)
  String address; // User address
  String city; // User city

  UserModel({
    required this.uid,
    required this.email,
    required this.name,
    required this.phone,
    required this.role,
    required this.address,
    required this.city,
  });

  // Convert a UserModel object into a map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'name': name,
      'phone': phone,
      'role': role,
      'address': address,
      'city': city,
    };
  }

  // Create a UserModel object from a map
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      phone: map['phone'] ?? '',
      role: map['role'] ?? '',
      address: map['address'] ?? '',
      city: map['city'] ?? '',
    );
  }

  // Create a UserModel object from a Firestore DocumentSnapshot
  factory UserModel.fromDocument(DocumentSnapshot doc) {
    // Ensure data is not null and cast it to a Map
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>? ?? {};
    return UserModel.fromMap(data);
  }
}

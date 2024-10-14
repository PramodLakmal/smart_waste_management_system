import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Sign in method
  Future<Map<String, dynamic>?> signIn(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Fetch user role from Firestore after successful login
      User? user = userCredential.user;
      if (user != null) {
        DocumentSnapshot<Map<String, dynamic>> userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (userDoc.exists) {
          return userDoc.data(); // Return user data including role
        }
      }
      return null;
    } catch (e) {
      print(e.toString());
      return null; // Return null if login fails or fetching role fails
    }
  }

  // Sign up method (if needed)
  Future<UserModel?> signUp(String email, String password, String name) async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = userCredential.user;

      if (user != null) {
        UserModel userModel = UserModel(
          uid: user.uid,
          email: email,
          name: name,
          phone: '',
          role: 'user',
          address: '',
          city: 'Malabe',
        );

        await FirebaseFirestore.instance.collection('users').doc(user.uid).set(userModel.toMap());

        return userModel;
      }
    } catch (e) {
      print(e.toString());
      return null;
    }
    return null;
  }

  // Sign out method
  Future<void> signOut() async {
    await _auth.signOut();
  }
}

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Sign in method
  Future<bool> signIn(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return true; // Return true if login is successful
    } catch (e) {
      print(e.toString());
      return false; // Return false if login fails
    }
  }

  // Sign up method (if needed)
  Future<UserModel?> signUp(String email, String password, String name, String phone) async {
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
          phone: phone,
          role: 'user',
          address: '',
          city: '',
          state: '',
          country: '',
          postalCode: '',
        );

        await FirebaseFirestore.instance.collection('users').doc(user.uid).set(userModel.toMap());

        return userModel;
      }
    } catch (e) {
      print(e.toString());
      return null;
    }
  }

  // Sign out method
  Future<void> signOut() async {
    await _auth.signOut();
  }
}

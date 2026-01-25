import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';

class AuthService with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  UserModel? _currentUser;
  bool _isLoading = false;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;

  // Listen to auth changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<void> signOut() async {
    await _auth.signOut();
    _currentUser = null;
    notifyListeners();
  }

  // Sign in with email and password
  Future<String?> signIn(String email, String password) async {
    try {
      _isLoading = true;
      notifyListeners();

      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      User? user = result.user;
      if (user != null) {
        // Fetch user details from Firestore
        DocumentSnapshot doc = await _firestore.collection('users').doc(user.uid).get();
        if (doc.exists) {
          _currentUser = UserModel.fromMap(doc.data() as Map<String, dynamic>, user.uid);
          notifyListeners();
          return null; // Success
        } else {
          // If no user doc exists, maybe creating one or it's an error. 
          // For now, return error.
          return 'User record not found.';
        }
      }
      return 'Authentication failed.';
    } on FirebaseAuthException catch (e) {
      return e.message;
    } catch (e) {
      return e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Reload user data
  Future<void> reloadUserData() async {
    User? firebaseUser = _auth.currentUser;
    if (firebaseUser != null) {
       DocumentSnapshot doc = await _firestore.collection('users').doc(firebaseUser.uid).get();
        if (doc.exists) {
          _currentUser = UserModel.fromMap(doc.data() as Map<String, dynamic>, firebaseUser.uid);
          notifyListeners();
        }
    }
  }
}

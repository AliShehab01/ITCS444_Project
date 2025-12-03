import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/user_role.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user stream
  Stream<User?> get userStream => _auth.authStateChanges();

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Sign in with email and password
  Future<UserModel?> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (result.user != null) {
        return await getUserData(result.user!.uid);
      }
      return null;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Register with email and password
  Future<UserModel?> registerWithEmailAndPassword({
    required String email,
    required String password,
    required String name,
    required String contact,
    required String idNumber,
    required String preferredContactMethod,
    required UserRole role,
  }) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (result.user != null) {
        // Create user document in Firestore
        UserModel newUser = UserModel(
          uid: result.user!.uid,
          email: email,
          name: name,
          contact: contact,
          idNumber: idNumber,
          preferredContactMethod: preferredContactMethod,
          role: role,
          createdAt: DateTime.now(),
        );

        await _firestore
            .collection('users')
            .doc(result.user!.uid)
            .set(newUser.toMap());

        return newUser;
      }
      return null;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Get user data from Firestore
  Future<UserModel?> getUserData(String uid) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(uid)
          .get();
      if (doc.exists) {
        return UserModel.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      throw 'Error fetching user data: ${e.toString()}';
    }
  }

  // Update user profile
  Future<void> updateUserProfile({
    required String uid,
    String? name,
    String? contact,
    String? idNumber,
    String? preferredContactMethod,
  }) async {
    try {
      Map<String, dynamic> updates = {};
      if (name != null) updates['name'] = name;
      if (contact != null) updates['contact'] = contact;
      if (idNumber != null) updates['idNumber'] = idNumber;
      if (preferredContactMethod != null) {
        updates['preferredContactMethod'] = preferredContactMethod;
      }

      await _firestore.collection('users').doc(uid).update(updates);
    } catch (e) {
      throw 'Error updating profile: ${e.toString()}';
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Handle Firebase Auth exceptions
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'The password provided is too weak.';
      case 'email-already-in-use':
        return 'An account already exists for that email.';
      case 'user-not-found':
        return 'No user found for that email.';
      case 'wrong-password':
        return 'Wrong password provided.';
      case 'invalid-email':
        return 'The email address is not valid.';
      case 'user-disabled':
        return 'This user account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      default:
        return 'Authentication error: ${e.message}';
    }
  }

  // Continue as guest (anonymous sign in)
  Future<void> continueAsGuest() async {
    try {
      UserCredential result = await _auth.signInAnonymously();

      if (result.user != null) {
        // Create guest user document
        UserModel guestUser = UserModel(
          uid: result.user!.uid,
          email: 'guest@anonymous.com',
          name: 'Guest User',
          contact: '',
          idNumber: '',
          preferredContactMethod: 'email',
          role: UserRole.guest,
          createdAt: DateTime.now(),
        );

        await _firestore
            .collection('users')
            .doc(result.user!.uid)
            .set(guestUser.toMap());
      }
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }
}

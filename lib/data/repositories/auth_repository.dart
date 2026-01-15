import 'package:firebase_auth/firebase_auth.dart';

class AuthRepository {
  final FirebaseAuth _firebaseAuth;

  AuthRepository({FirebaseAuth? firebaseAuth})
    : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  Stream<User?> get user => _firebaseAuth.authStateChanges();

  Future<UserCredential> signUp({
    required String email,
    required String password,
  }) async {
    try {
      return await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw Exception('Code: ${e.code} - Message: ${e.message}');
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    try {
      return await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw Exception('Code: ${e.code} - Message: ${e.message}');
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }

  Future<void> updateDisplayName(String name) async {
    try {
      await _firebaseAuth.currentUser?.updateDisplayName(name);
      await _firebaseAuth.currentUser?.reload();
    } on FirebaseAuthException catch (e) {
      throw Exception('Code: ${e.code} - Message: ${e.message}');
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<void> updatePhotoURL(String photoURL) async {
    try {
      await _firebaseAuth.currentUser?.updatePhotoURL(photoURL);
      await _firebaseAuth.currentUser?.reload();
    } on FirebaseAuthException catch (e) {
      throw Exception('Code: ${e.code} - Message: ${e.message}');
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<void> changePassword(String currentPassword, String newPassword) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null || user.email == null) {
        throw Exception('No user logged in');
      }

      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );

      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(newPassword);
    } on FirebaseAuthException catch (e) {
      throw Exception('Code: ${e.code} - Message: ${e.message}');
    } catch (e) {
      throw Exception(e.toString());
    }
  }
}
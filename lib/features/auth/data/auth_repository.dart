import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:welinked/core/constants/firebase_constants.dart';
import 'package:welinked/core/errors/failures.dart';
import 'package:welinked/features/auth/domain/app_user.dart';
import 'package:welinked/shared/providers/firebase_providers.dart';

/// Repository for Firebase Authentication and user document management.
/// No signOut exposed — permanent login by design.
class AuthRepository {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  AuthRepository(this._auth, this._firestore);

  /// Current Firebase user (null if not signed in).
  User? get currentFirebaseUser => _auth.currentUser;

  /// Current user UID.
  String? get currentUid => _auth.currentUser?.uid;

  /// Stream of auth state changes.
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Sign in with email and password.
  Future<AppUser> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final uid = credential.user!.uid;
      final doc = await _firestore
          .collection(FirebaseConstants.usersCollection)
          .doc(uid)
          .get();
      if (!doc.exists) {
        throw const AuthFailure('User document not found in database.');
      }
      // Update online status on login
      await _firestore
          .collection(FirebaseConstants.usersCollection)
          .doc(uid)
          .update({
        'isOnline': true,
        'lastSeen': FieldValue.serverTimestamp(),
      });
      return AppUser.fromFirestore(doc);
    } on FirebaseAuthException catch (e) {
      throw AuthFailure.fromFirebase(e.code);
    }
  }

  /// Register with name, email, and password.
  /// Creates Firestore user document immediately.
  Future<AppUser> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final uid = credential.user!.uid;
      final user = AppUser(
        uid: uid,
        name: name.trim(),
        email: email.trim(),
        createdAt: DateTime.now(),
      );
      await _firestore
          .collection(FirebaseConstants.usersCollection)
          .doc(uid)
          .set(user.toNewUserFirestore());
      // Also create default settings document
      await _firestore
          .collection(FirebaseConstants.settingsCollection)
          .doc(uid)
          .set({
        'redSoundEnabled': true,
        'greenSoundEnabled': true,
        'blueSoundEnabled': true,
        'yellowSoundEnabled': true,
      });
      return user;
    } on FirebaseAuthException catch (e) {
      throw AuthFailure.fromFirebase(e.code);
    }
  }

  /// Stream the current user's Firestore document.
  /// Returns null if not signed in.
  Stream<AppUser?> watchCurrentUser() {
    final uid = currentUid;
    if (uid == null) return Stream.value(null);
    return _firestore
        .collection(FirebaseConstants.usersCollection)
        .doc(uid)
        .snapshots()
        .map((doc) {
      if (!doc.exists) return null;
      return AppUser.fromFirestore(doc);
    });
  }

  /// Get current user document once.
  Future<AppUser?> getCurrentUser() async {
    final uid = currentUid;
    if (uid == null) return null;
    final doc = await _firestore
        .collection(FirebaseConstants.usersCollection)
        .doc(uid)
        .get();
    if (!doc.exists) return null;
    return AppUser.fromFirestore(doc);
  }

  /// Update FCM token in user document.
  Future<void> updateFcmToken(String token) async {
    final uid = currentUid;
    if (uid == null) return;
    await _firestore
        .collection(FirebaseConstants.usersCollection)
        .doc(uid)
        .update({'fcmToken': token});
  }

  /// Update user's online status.
  Future<void> updateOnlineStatus(bool isOnline) async {
    final uid = currentUid;
    if (uid == null) return;
    await _firestore
        .collection(FirebaseConstants.usersCollection)
        .doc(uid)
        .update({
      'isOnline': isOnline,
      'lastSeen': FieldValue.serverTimestamp(),
    });
  }
}

/// Provider for AuthRepository.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    ref.watch(firebaseAuthProvider),
    ref.watch(firestoreProvider),
  );
});

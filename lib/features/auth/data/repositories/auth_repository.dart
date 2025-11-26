import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:movies_app_graduation_project/core/prefs_manager/prefs_manager.dart';
import 'package:movies_app_graduation_project/features/auth/data/models/user_model.dart';

class AuthRepository {
  final PrefsManager _prefsManager;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  AuthRepository(this._prefsManager);

  // Storage keys
  static const String _keyUserId = 'user_id';

  /// Login user with email and password
  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email.trim().toLowerCase(),
        password: password,
      );

      if (userCredential.user == null) {
        throw Exception('Login failed. Please try again.');
      }

      // Get user profile from Firestore
      final user = await _getUserFromFirestore(userCredential.user!.uid);

      // Save user ID locally
      await _prefsManager.setString(_keyUserId, userCredential.user!.uid);

      return user;
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'user-not-found':
          throw Exception('No user found for that email.');
        case 'wrong-password':
          throw Exception('Wrong password provided.');
        case 'invalid-email':
          throw Exception('The email address is invalid.');
        case 'user-disabled':
          throw Exception('This user account has been disabled.');
        default:
          throw Exception('Login failed: ${e.message}');
      }
    } catch (e) {
      throw Exception('Login failed. Please try again.');
    }
  }

  /// Register new user
  Future<UserModel> register({
    required String name,
    required String email,
    required String password,
    required String phone,
    required String avatar,
  }) async {
    try {
      // Create user in Firebase Auth
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email.trim().toLowerCase(),
        password: password,
      );

      if (userCredential.user == null) {
        throw Exception('Registration failed. Please try again.');
      }

      final userId = userCredential.user!.uid;

      // Create user profile in Firestore
      final userData = {
        'id': userId,
        'name': name.trim(),
        'email': email.trim().toLowerCase(),
        'phone': phone.trim(),
        'avatar': avatar,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await _firestore.collection('users').doc(userId).set(userData);

      // Save user ID locally
      await _prefsManager.setString(_keyUserId, userId);

      // Return user model
      return UserModel(
        id: userId,
        name: name.trim(),
        email: email.trim().toLowerCase(),
        phone: phone.trim(),
        avatar: avatar,
        token: null, // Firebase handles tokens internally
      );
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'weak-password':
          throw Exception('The password provided is too weak.');
        case 'email-already-in-use':
          throw Exception('An account already exists for that email.');
        case 'invalid-email':
          throw Exception('The email address is invalid.');
        default:
          throw Exception('Registration failed: ${e.message}');
      }
    } catch (e) {
      // If Firestore fails, delete the auth user
      try {
        await _auth.currentUser?.delete();
      } catch (_) {
        // Ignore deletion errors
      }
      throw Exception('Registration failed. Please try again.');
    }
  }

  /// Send password reset email
  Future<void> forgotPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim().toLowerCase());
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'user-not-found':
          throw Exception('No user found for that email.');
        case 'invalid-email':
          throw Exception('The email address is invalid.');
        default:
          throw Exception('Failed to send password reset email: ${e.message}');
      }
    } catch (e) {
      throw Exception('Failed to send password reset email.');
    }
  }

  /// Get current user
  Future<UserModel?> getCurrentUser() async {
    try {
      final currentAuthUser = _auth.currentUser;
      if (currentAuthUser == null) {
        await _clearUserData();
        return null;
      }

      // Get user profile from Firestore
      return await _getUserFromFirestore(currentAuthUser.uid);
    } catch (e) {
      await _clearUserData();
      return null;
    }
  }

  /// Get user profile from Firestore
  Future<UserModel> _getUserFromFirestore(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();

      if (!doc.exists) {
        // If profile doesn't exist, create a basic one
        final authUser = _auth.currentUser;
        if (authUser == null) {
          throw Exception('User not authenticated');
        }

        final userData = {
          'id': userId,
          'name': authUser.displayName ?? 'User',
          'email': authUser.email ?? '',
          'phone': '',
          'avatar': 'assets/images/avt_1.png',
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        };

        await _firestore.collection('users').doc(userId).set(userData);

        return UserModel(
          id: userId,
          name: authUser.displayName ?? 'User',
          email: authUser.email ?? '',
          phone: '',
          avatar: 'assets/images/avt_1.png',
          token: null,
        );
      }

      final data = doc.data()!;
      return UserModel(
        id: data['id'] as String? ?? userId,
        name: data['name'] as String? ?? 'User',
        email: data['email'] as String? ?? _auth.currentUser?.email ?? '',
        phone: data['phone'] as String? ?? '',
        avatar: data['avatar'] as String? ?? 'assets/images/avt_1.png',
        token: null,
      );
    } catch (e) {
      throw Exception('Failed to get user profile.');
    }
  }

  /// Update user profile
  Future<UserModel> updateProfile({
    required String name,
    String? phone,
    required String avatar,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      final userId = currentUser.uid;

      // Update profile in Firestore
      final updates = <String, dynamic>{
        'name': name.trim(),
        'avatar': avatar,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (phone != null && phone.isNotEmpty) {
        updates['phone'] = phone.trim();
      }

      await _firestore.collection('users').doc(userId).update(updates);

      // Return updated user
      return await _getUserFromFirestore(userId);
    } catch (e) {
      throw Exception('Failed to update profile: ${e.toString()}');
    }
  }

  /// Check if user is logged in
  bool isLoggedIn() {
    return _auth.currentUser != null;
  }

  /// Logout
  Future<void> logout() async {
    try {
      await _auth.signOut();
      await _clearUserData();
    } catch (e) {
      throw Exception('Failed to logout');
    }
  }

  /// Clear user data from local storage
  Future<void> _clearUserData() async {
    await _prefsManager.remove(_keyUserId);
  }
}

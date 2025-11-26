import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FavoritesProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Set<String> _favoriteMovieIds = {};
  List<String> _historyMovieIds = [];
  bool _isLoading = false;

  Set<String> get favoriteMovieIds => _favoriteMovieIds;
  List<String> get historyMovieIds => _historyMovieIds;
  bool get isLoading => _isLoading;

  FavoritesProvider() {
    _initializeData();
  }

  /// Initialize data when provider is created or user changes
  Future<void> _initializeData() async {
    final currentUser = _auth.currentUser;
    if (currentUser != null) {
      await loadUserData(currentUser.uid);
    } else {
      _favoriteMovieIds.clear();
      _historyMovieIds.clear();
      notifyListeners();
    }
  }

  /// Load favorites and history for the current user
  Future<void> loadUserData(String userId) async {
    if (_isLoading) return;

    _isLoading = true;
    notifyListeners();

    try {
      // Load favorites
      final favoritesDoc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('favorites')
          .doc('list')
          .get();

      if (favoritesDoc.exists && favoritesDoc.data() != null) {
        final data = favoritesDoc.data()!;
        final favorites = data['movieIds'] as List<dynamic>?;
        _favoriteMovieIds = favorites != null
            ? favorites.map((id) => id.toString()).toSet()
            : {};
      } else {
        _favoriteMovieIds = {};
      }

      // Load history
      final historyQuery = await _firestore
          .collection('users')
          .doc(userId)
          .collection('history')
          .orderBy('viewedAt', descending: true)
          .limit(100)
          .get();

      _historyMovieIds = historyQuery.docs
          .map((doc) => doc.data()['movieId']?.toString() ?? '')
          .where((id) => id.isNotEmpty)
          .toList();
    } catch (e) {
      debugPrint('Error loading user data: $e');
      _favoriteMovieIds = {};
      _historyMovieIds = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Clear all data (called on logout)
  void clearData() {
    _favoriteMovieIds.clear();
    _historyMovieIds.clear();
    notifyListeners();
  }

  /// Check if a movie is favorite
  bool isFavorite(String movieId) {
    return _favoriteMovieIds.contains(movieId);
  }

  /// Toggle favorite status for a movie
  Future<void> toggleFavorite(String movieId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      debugPrint('User not logged in');
      return;
    }

    try {
      if (_favoriteMovieIds.contains(movieId)) {
        _favoriteMovieIds.remove(movieId);
      } else {
        _favoriteMovieIds.add(movieId);
      }

      // Update in Firestore
      await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('favorites')
          .doc('list')
          .set({
            'movieIds': _favoriteMovieIds.toList(),
            'updatedAt': FieldValue.serverTimestamp(),
          });

      notifyListeners();
    } catch (e) {
      debugPrint('Error toggling favorite: $e');
      // Revert on error
      if (_favoriteMovieIds.contains(movieId)) {
        _favoriteMovieIds.remove(movieId);
      } else {
        _favoriteMovieIds.add(movieId);
      }
      notifyListeners();
    }
  }

  /// Add movie to favorites
  Future<void> addFavorite(String movieId) async {
    if (!_favoriteMovieIds.contains(movieId)) {
      await toggleFavorite(movieId);
    }
  }

  /// Remove movie from favorites
  Future<void> removeFavorite(String movieId) async {
    if (_favoriteMovieIds.contains(movieId)) {
      await toggleFavorite(movieId);
    }
  }

  /// Add movie to history
  Future<void> addToHistory(String movieId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return;
    }

    try {
      // Remove if already exists (to move to top)
      _historyMovieIds.remove(movieId);
      _historyMovieIds.insert(0, movieId);

      // Keep only last 100 items
      if (_historyMovieIds.length > 100) {
        _historyMovieIds = _historyMovieIds.sublist(0, 100);
      }

      // Update in Firestore
      await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('history')
          .doc(movieId)
          .set({'movieId': movieId, 'viewedAt': FieldValue.serverTimestamp()});

      notifyListeners();
    } catch (e) {
      debugPrint('Error adding to history: $e');
    }
  }

  /// Clear all favorites
  Future<void> clearFavorites() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return;
    }

    try {
      _favoriteMovieIds.clear();

      await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('favorites')
          .doc('list')
          .delete();

      notifyListeners();
    } catch (e) {
      debugPrint('Error clearing favorites: $e');
    }
  }

  /// Clear all history
  Future<void> clearHistory() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return;
    }

    try {
      // Delete all history documents
      final batch = _firestore.batch();
      final historyRef = _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('history');

      for (final movieId in _historyMovieIds) {
        batch.delete(historyRef.doc(movieId));
      }

      await batch.commit();
      _historyMovieIds.clear();
      notifyListeners();
    } catch (e) {
      debugPrint('Error clearing history: $e');
    }
  }

  /// Get history count
  int get historyCount => _historyMovieIds.length;
}

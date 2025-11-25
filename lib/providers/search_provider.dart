import 'package:flutter/foundation.dart';

import '../features/home/data/models/movie_model.dart';
import '../features/home/data/repositories/movie_repository.dart';

class SearchProvider with ChangeNotifier {
  SearchProvider(this._movieRepository);

  final MovieRepository _movieRepository;

  List<MovieModel> _results = [];
  bool _isLoading = false;
  String? _errorMessage;
  String _lastQuery = '';

  List<MovieModel> get results => _results;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get lastQuery => _lastQuery;
  bool get hasSearched => _lastQuery.isNotEmpty;

  Future<void> search(String query) async {
    final trimmedQuery = query.trim();
    if (trimmedQuery.isEmpty) {
      clear();
      return;
    }

    _lastQuery = trimmedQuery;
    _setLoading(true);
    _errorMessage = null;
    notifyListeners();

    try {
      _results = await _movieRepository.searchMovies(trimmedQuery);
      _errorMessage = null;
    } catch (error) {
      _errorMessage = error.toString();
      _results = [];
    } finally {
      _setLoading(false);
      notifyListeners();
    }
  }

  void clear() {
    _results = [];
    _errorMessage = null;
    _lastQuery = '';
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
  }
}

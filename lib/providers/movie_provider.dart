import 'package:flutter/foundation.dart';

import '../features/home/data/models/movie_model.dart';
import '../features/home/data/repositories/movie_repository.dart';

class MovieProvider with ChangeNotifier {
  MovieProvider(this._movieRepository);

  final MovieRepository _movieRepository;

  List<MovieModel> _availableNow = [];
  List<MovieModel> _actionMovies = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<MovieModel> get availableNow => _availableNow;
  List<MovieModel> get actionMovies => _actionMovies;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadHomeData() async {
    if (_isLoading) return;
    _setLoading(true);
    _errorMessage = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _movieRepository.getAvailableNowMovies(),
        _movieRepository.getMoviesByCategory('Action'),
      ]);
      _availableNow = results[0];
      _actionMovies = results[1];
      _errorMessage = null;
    } catch (error) {
      _errorMessage = error.toString();
    } finally {
      _setLoading(false);
      notifyListeners();
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
  }

  Future<void> refreshCategory(String category) async {
    try {
      _actionMovies = await _movieRepository.getMoviesByCategory(category);
      notifyListeners();
    } catch (error) {
      _errorMessage = error.toString();
      notifyListeners();
    }
  }
}

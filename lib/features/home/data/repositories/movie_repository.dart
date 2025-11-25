import 'package:movies_app_graduation_project/core/network/api_exception.dart';
import 'package:movies_app_graduation_project/features/home/data/datasources/yts_api_service.dart';
import 'package:movies_app_graduation_project/features/home/data/models/movie_model.dart';

class MovieRepository {
  final YtsApiService _apiService;

  MovieRepository(this._apiService);

  Future<List<MovieModel>> getAvailableNowMovies() async {
    final movies = await _apiService.listMovies(
      limit: 10,
      sortBy: 'date_added',
      orderBy: 'desc',
    );
    return movies
        .map((movie) => MovieModel.fromYtsJson(movie as Map<String, dynamic>))
        .toList();
  }

  Future<List<MovieModel>> getMoviesByCategory(String category) async {
    final movies = await _apiService.listMovies(
      limit: 20,
      genre: category,
      sortBy: 'like_count',
      orderBy: 'desc',
    );
    return movies
        .map((movie) => MovieModel.fromYtsJson(movie as Map<String, dynamic>))
        .toList();
  }

  Future<MovieModel> getMovieDetails(String movieId) async {
    final id = int.tryParse(movieId);
    if (id == null) {
      throw ApiException('Invalid movie id: $movieId');
    }
    final movie = await _apiService.movieDetails(movieId: id);
    return MovieModel.fromYtsJson(movie);
  }

  Future<List<MovieModel>> getSuggestions(String movieId) async {
    final id = int.tryParse(movieId);
    if (id == null) {
      throw ApiException('Invalid movie id: $movieId');
    }
    final movies = await _apiService.movieSuggestions(movieId: id);
    return movies
        .map((movie) => MovieModel.fromYtsJson(movie as Map<String, dynamic>))
        .toList();
  }

  Future<List<MovieModel>> searchMovies(String query) async {
    final movies = await _apiService.listMovies(
      query: query,
      limit: 30,
      sortBy: 'download_count',
      orderBy: 'desc',
    );
    return movies
        .map((movie) => MovieModel.fromYtsJson(movie as Map<String, dynamic>))
        .toList();
  }

  List<String> getCategories() {
    return const [
      'Action',
      'Adventure',
      'Animation',
      'Biography',
      'Comedy',
      'Crime',
      'Drama',
      'Fantasy',
      'Horror',
      'Sci-Fi',
    ];
  }
}

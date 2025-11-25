import 'package:dio/dio.dart';

import '../../../../core/network/api_exception.dart';

class YtsApiService {
  static const String _baseUrl = 'https://yts.lt/api/v2';

  final Dio _dio;

  YtsApiService({Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: _baseUrl,
              connectTimeout: const Duration(seconds: 20),
              receiveTimeout: const Duration(seconds: 20),
              responseType: ResponseType.json,
            ),
          );

  Future<List<dynamic>> listMovies({
    int limit = 20,
    int page = 1,
    String? quality,
    int? minimumRating,
    String? query,
    String? genre,
    String sortBy = 'date_added',
    String orderBy = 'desc',
    bool withRtRatings = false,
  }) async {
    final response = await _safeRequest(
      () => _dio.get(
        '/list_movies.json',
        queryParameters: <String, dynamic>{
          'limit': limit,
          'page': page,
          if (quality != null) 'quality': quality,
          if (minimumRating != null) 'minimum_rating': minimumRating,
          if (query != null) 'query_term': query,
          if (genre != null) 'genre': genre,
          'sort_by': sortBy,
          'order_by': orderBy,
          'with_rt_ratings': withRtRatings,
        },
      ),
    );

    final movies = response['movies'] as List<dynamic>? ?? [];
    return movies;
  }

  Future<Map<String, dynamic>> movieDetails({
    required int movieId,
    bool withImages = true,
    bool withCast = true,
  }) async {
    final response = await _safeRequest(
      () => _dio.get(
        '/movie_details.json',
        queryParameters: <String, dynamic>{
          'movie_id': movieId,
          'with_images': withImages,
          'with_cast': withCast,
        },
      ),
    );

    final movie = response['movie'] as Map<String, dynamic>?;
    if (movie == null) {
      throw ApiException('Movie details missing from response');
    }
    return movie;
  }

  Future<List<dynamic>> movieSuggestions({required int movieId}) async {
    final response = await _safeRequest(
      () => _dio.get(
        '/movie_suggestions.json',
        queryParameters: <String, dynamic>{'movie_id': movieId},
      ),
    );

    final movies = response['movies'] as List<dynamic>? ?? [];
    return movies;
  }

  Future<Map<String, dynamic>> _safeRequest(
    Future<Response<dynamic>> Function() request,
  ) async {
    try {
      final response = await request();
      final data = response.data as Map<String, dynamic>? ?? {};
      final status = data['status'] as String?;
      if (status != 'ok') {
        throw ApiException(
          data['status_message']?.toString() ?? 'Unknown API error',
          statusCode: response.statusCode,
          details: data,
        );
      }
      return data['data'] as Map<String, dynamic>? ?? {};
    } on DioException catch (dioError) {
      throw ApiException(
        dioError.message ?? 'Network error',
        statusCode: dioError.response?.statusCode,
        details: dioError.response?.data,
      );
    }
  }
}

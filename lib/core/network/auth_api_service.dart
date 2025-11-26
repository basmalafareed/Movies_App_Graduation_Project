import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'api_exception.dart';

class AuthApiService {
  static const String _baseUrl = 'https://route-movie-apis.vercel.app';

  final Dio _dio;

  AuthApiService({Dio? dio, String? baseUrl})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: baseUrl ?? _baseUrl,
              connectTimeout: const Duration(seconds: 30),
              receiveTimeout: const Duration(seconds: 30),
              responseType: ResponseType.json,
              headers: {
                'Content-Type': 'application/json',
                'Accept': 'application/json',
              },
            ),
          );

  void setAuthToken(String? token) {
    if (token != null) {
      _dio.options.headers['Authorization'] = 'Bearer $token';
    } else {
      _dio.options.headers.remove('Authorization');
    }
  }

  /// Login user
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        '/auth/login',
        data: {'email': email, 'password': password},
      );

      return _handleResponse(response);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Register new user
  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required String confirmPassword,
    required String phone,
    required int avatarId,
  }) async {
    try {
      // Ensure avatarId is always a valid positive number between 1-9
      final validAvatarId = avatarId > 0 && avatarId <= 9 ? avatarId : 1;

      // Debug: Print avatarId to verify it's being sent
      debugPrint(
        'Registering with avaterId: $validAvatarId (original: $avatarId)',
      );

      final response = await _dio.post(
        '/auth/register',
        data: {
          'name': name,
          'email': email,
          'password': password,
          'confirmPassword': confirmPassword,
          'phone': phone,
          // API expects 'avaterId' with typo (based on error message)
          // Try as number first, API might auto-convert
          'avaterId': validAvatarId,
        },
      );

      return _handleResponse(response);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Forgot password
  Future<void> forgotPassword(String email) async {
    try {
      await _dio.post('/auth/forgot-password', data: {'email': email});
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Get user profile
  Future<Map<String, dynamic>> getProfile() async {
    try {
      final response = await _dio.get('/auth/profile');
      return _handleResponse(response);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Update user profile
  Future<Map<String, dynamic>> updateProfile({
    String? name,
    String? phone,
    String? avatar,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (name != null) data['name'] = name;
      if (phone != null) data['phone'] = phone;
      if (avatar != null) data['avatar'] = avatar;

      final response = await _dio.put('/auth/profile', data: data);

      return _handleResponse(response);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Get user favorites
  Future<List<dynamic>> getFavorites() async {
    try {
      final response = await _dio.get('/favorites');
      final statusCode = response.statusCode ?? 0;

      if (statusCode >= 200 && statusCode < 300) {
        final data = response.data;

        // Handle different response structures
        if (data is List) {
          return data;
        } else if (data is Map<String, dynamic>) {
          if (data['favorites'] != null && data['favorites'] is List) {
            return data['favorites'] as List<dynamic>;
          } else if (data['data'] != null && data['data'] is List) {
            return data['data'] as List<dynamic>;
          } else if (data.containsKey('data') && data['data'] is Map) {
            final nestedData = data['data'] as Map<String, dynamic>;
            if (nestedData['favorites'] != null &&
                nestedData['favorites'] is List) {
              return nestedData['favorites'] as List<dynamic>;
            }
          }
        }
        return [];
      }

      throw ApiException(
        'Unexpected response status: $statusCode',
        statusCode: statusCode,
        details: response.data,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Add movie to favorites
  Future<void> addFavorite(String movieId) async {
    try {
      await _dio.post('/favorites', data: {'movie_id': movieId});
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Remove movie from favorites
  Future<void> removeFavorite(String movieId) async {
    try {
      await _dio.delete('/favorites/$movieId');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Check if movie is favorite
  Future<bool> isFavorite(String movieId) async {
    try {
      final response = await _dio.get('/favorites/$movieId');
      final data = _handleResponse(response);
      return data['is_favorite'] == true || data['favorite'] == true;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return false;
      }
      throw _handleError(e);
    }
  }

  Map<String, dynamic> _handleResponse(Response response) {
    final statusCode = response.statusCode ?? 0;

    if (statusCode >= 200 && statusCode < 300) {
      final data = response.data;

      // Debug: Print raw response
      if (kDebugMode) {
        debugPrint('API Response status: $statusCode');
        debugPrint('API Response data type: ${data.runtimeType}');
        debugPrint('API Response data: $data');
      }

      if (data is Map<String, dynamic>) {
        // For registration/login, return the full response to allow token extraction
        // Don't automatically extract 'data' or 'user' as token might be at root level
        return data;
      }
      return {'data': data};
    }

    throw ApiException(
      'Unexpected response status: $statusCode',
      statusCode: statusCode,
      details: response.data,
    );
  }

  ApiException _handleError(DioException error) {
    final statusCode = error.response?.statusCode;
    final data = error.response?.data;

    String message = 'An error occurred';

    // Handle network/connection errors first
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout) {
      message =
          'Connection timeout. Please check your internet connection and try again.';
    } else if (error.type == DioExceptionType.connectionError ||
        error.message?.contains('Failed host lookup') == true ||
        error.message?.contains('Network is unreachable') == true) {
      message =
          'Unable to connect to server. Please check your internet connection.';
    } else if (data is Map<String, dynamic>) {
      // Handle validation errors array
      if (data['message'] is List) {
        final errors = data['message'] as List;
        message = errors.map((e) => e.toString()).join(', ');
      } else {
        message =
            data['message']?.toString() ??
            data['error']?.toString() ??
            data['status_message']?.toString() ??
            message;
      }
    } else if (error.message != null) {
      // For other errors, use a more user-friendly message
      final errorMsg = error.message ?? '';
      if (errorMsg.contains('Failed host lookup')) {
        message =
            'Unable to connect to server. Please check your internet connection.';
      } else if (errorMsg.contains('SocketException')) {
        message = 'Network error. Please check your internet connection.';
      } else {
        message = errorMsg;
      }
    }

    // Handle HTTP status codes
    if (statusCode != null) {
      switch (statusCode) {
        case 400:
          message = message.contains('already') || message.isNotEmpty
              ? message
              : 'Invalid request. Please check your input.';
          break;
        case 401:
          message = 'Authentication failed. Please login again.';
          break;
        case 403:
          message = 'You do not have permission to perform this action.';
          break;
        case 404:
          message = 'Resource not found.';
          break;
        case 422:
          message = message.isNotEmpty
              ? message
              : 'Validation error. Please check your input.';
          break;
        case 500:
          message = 'Server error. Please try again later.';
          break;
      }
    }

    return ApiException(message, statusCode: statusCode, details: data);
  }
}

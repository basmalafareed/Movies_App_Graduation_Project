import 'package:flutter/foundation.dart';
import 'package:movies_app_graduation_project/core/prefs_manager/prefs_manager.dart';
import 'package:movies_app_graduation_project/core/network/auth_api_service.dart';
import 'package:movies_app_graduation_project/core/network/api_exception.dart';
import 'package:movies_app_graduation_project/features/auth/data/models/user_model.dart';

class AuthRepository {
  final PrefsManager _prefsManager;
  final AuthApiService _apiService;

  AuthRepository(this._prefsManager, {AuthApiService? apiService})
    : _apiService = apiService ?? AuthApiService();

  // Storage keys
  static const String _keyToken = 'auth_token';
  static const String _keyUserId = 'user_id';
  static const String _keyUserData = 'user_data';
  static const String _keyIsLoggedIn = 'is_logged_in';

  /// Initialize - load token and set it in API service
  void initialize() {
    final token = _prefsManager.getString(_keyToken);
    if (token != null && token.isNotEmpty) {
      _apiService.setAuthToken(token);
    }
  }

  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _apiService.login(
        email: email,
        password: password,
      );

      // Debug: Print full response to see structure
      if (kDebugMode) {
        debugPrint('Login response keys: ${response.keys.toList()}');
        debugPrint('Login response: $response');
      }

      // Extract token and user data from response
      // Try multiple possible locations for the token
      String? token;

      // Check root level - try case-insensitive key matching first
      final rootKeys = response.keys.toList();
      for (final key in rootKeys) {
        final lowerKey = key.toLowerCase();
        if ((lowerKey == 'token' ||
            lowerKey == 'accesstoken' ||
            lowerKey == 'access_token' ||
            lowerKey == 'authtoken' ||
            lowerKey == 'auth_token' ||
            lowerKey == 'jwt' ||
            lowerKey == 'jwttoken' ||
            lowerKey == 'bearertoken') &&
            response[key] != null) {
          token = response[key]?.toString();
          if (kDebugMode) {
            debugPrint('Found token at root level with key: $key');
          }
          break;
        }
      }
      
      // If still not found, try exact matches as fallback
      if (token == null || token.isEmpty) {
        token =
            response['token']?.toString() ??
            response['access_token']?.toString() ??
            response['auth_token']?.toString() ??
            response['accessToken']?.toString() ??
            response['authToken']?.toString() ??
            response['jwt']?.toString() ??
            response['jwtToken']?.toString() ??
            response['bearerToken']?.toString();
      }

      // Check inside 'data' object if token not found
      if ((token == null || token.isEmpty) && response.containsKey('data')) {
        final rawDataObj = response['data'];
        Map<String, dynamic>? dataObj;
        
        // Handle if data is a List
        if (rawDataObj is List && rawDataObj.isNotEmpty) {
          if (rawDataObj[0] is Map<String, dynamic>) {
            dataObj = rawDataObj[0] as Map<String, dynamic>;
          }
        } else if (rawDataObj is Map<String, dynamic>) {
          dataObj = rawDataObj;
        }
        
        if (dataObj != null) {
          // Try case-insensitive matching for nested data
          final dataKeys = dataObj.keys.toList();
          for (final key in dataKeys) {
            final lowerKey = key.toString().toLowerCase();
            if ((lowerKey == 'token' ||
                lowerKey == 'accesstoken' ||
                lowerKey == 'access_token' ||
                lowerKey == 'authtoken' ||
                lowerKey == 'auth_token' ||
                lowerKey == 'jwt' ||
                lowerKey == 'jwttoken' ||
                lowerKey == 'bearertoken') &&
                dataObj[key] != null) {
              token = dataObj[key]?.toString();
              if (kDebugMode) {
                debugPrint('Found token in data object with key: $key');
              }
              break;
            }
          }
          
          // Fallback to exact matches
          if (token == null || token.isEmpty) {
            token =
                dataObj['token']?.toString() ??
                dataObj['access_token']?.toString() ??
                dataObj['auth_token']?.toString() ??
                dataObj['accessToken']?.toString() ??
                dataObj['authToken']?.toString() ??
                dataObj['jwt']?.toString() ??
                dataObj['jwtToken']?.toString() ??
                dataObj['bearerToken']?.toString();
          }
        }
      }

      // Check inside 'user' object if token not found
      if ((token == null || token.isEmpty) && response.containsKey('user')) {
        final rawUserObj = response['user'];
        Map<String, dynamic>? userObj;
        
        // Handle if user is a List
        if (rawUserObj is List && rawUserObj.isNotEmpty) {
          if (rawUserObj[0] is Map<String, dynamic>) {
            userObj = rawUserObj[0] as Map<String, dynamic>;
          }
        } else if (rawUserObj is Map<String, dynamic>) {
          userObj = rawUserObj;
        }
        
        if (userObj != null) {
          // Try case-insensitive matching for nested user
          final userKeys = userObj.keys.toList();
          for (final key in userKeys) {
            final lowerKey = key.toString().toLowerCase();
            if ((lowerKey == 'token' ||
                lowerKey == 'accesstoken' ||
                lowerKey == 'access_token' ||
                lowerKey == 'authtoken' ||
                lowerKey == 'auth_token' ||
                lowerKey == 'jwt' ||
                lowerKey == 'jwttoken' ||
                lowerKey == 'bearertoken') &&
                userObj[key] != null) {
              token = userObj[key]?.toString();
              if (kDebugMode) {
                debugPrint('Found token in user object with key: $key');
              }
              break;
            }
          }
          
          // Fallback to exact matches
          if (token == null || token.isEmpty) {
            token =
                userObj['token']?.toString() ??
                userObj['access_token']?.toString() ??
                userObj['auth_token']?.toString() ??
                userObj['accessToken']?.toString() ??
                userObj['authToken']?.toString() ??
                userObj['jwt']?.toString() ??
                userObj['jwtToken']?.toString() ??
                userObj['bearerToken']?.toString();
          }
        }
      }

      // If token is not found, check if login was successful but token is in a different format
      if (token == null || token.isEmpty) {
        if (kDebugMode) {
          debugPrint('=== Token Extraction Failed (Login) ===');
          debugPrint('Response structure: $response');
          debugPrint('Available keys: ${response.keys.toList()}');
          debugPrint('Response type: ${response.runtimeType}');
          // Try to find any field that might contain a token
          response.forEach((key, value) {
            if (key.toString().toLowerCase().contains('token') ||
                key.toString().toLowerCase().contains('auth') ||
                key.toString().toLowerCase().contains('jwt')) {
              debugPrint('Found potential token field "$key": $value');
            }
          });
          debugPrint('======================================');
        }
        
        // Check if login was successful but token is missing
        final hasUserData = response.containsKey('user') || 
                           response.containsKey('data') ||
                           response.containsKey('id');
        
        if (hasUserData) {
          // Login successful but no token - might be a different auth mechanism
          if (kDebugMode) {
            debugPrint('Login appears successful but no token found. Attempting to proceed with user data.');
          }
          
          // Extract user data even without token - ensure it's a Map
          dynamic rawUserData = response['user'] ?? response['data'] ?? response;
          
          // Convert to Map if it's a List (take first item) or ensure it's a Map
          Map<String, dynamic> userData;
          if (rawUserData is List && rawUserData.isNotEmpty) {
            // If it's a list, take the first element
            userData = rawUserData[0] is Map<String, dynamic> 
                ? rawUserData[0] as Map<String, dynamic>
                : {};
          } else if (rawUserData is Map<String, dynamic>) {
            userData = rawUserData;
          } else {
            // Fallback to empty map if type is unexpected
            userData = {};
          }
          
          // Create user model with empty token - might need to handle differently
          final user = UserModel(
            id: userData['id']?.toString() ?? userData['_id']?.toString() ?? '',
            name: userData['name']?.toString() ?? 'User',
            email: userData['email']?.toString() ?? email.trim(),
            phone: userData['phone']?.toString() ?? '',
            avatar:
                userData['avatar']?.toString() ??
                userData['image']?.toString() ??
                'assets/images/avt_1.png',
            token: '', // Empty token - might need alternative auth
          );
          
          // Save user data (without token) - user might need to use session-based auth
          await _saveUserData(user);
          
          // Don't throw error - login was successful but token handling might be different
          return user;
        }
        
        throw ApiException(
          'No authentication token received from server. Response keys: ${response.keys.join(", ")}',
        );
      }

      // Extract user data - ensure it's a Map before accessing with string keys
      dynamic rawUserData = response['user'] ?? response['data'] ?? response;
      
      // Convert to Map if it's a List (take first item) or ensure it's a Map
      Map<String, dynamic> userData;
      if (rawUserData is List && rawUserData.isNotEmpty) {
        // If it's a list, take the first element
        userData = rawUserData[0] is Map<String, dynamic> 
            ? rawUserData[0] as Map<String, dynamic>
            : {};
      } else if (rawUserData is Map<String, dynamic>) {
        userData = rawUserData;
      } else {
        // Fallback to empty map if type is unexpected
        userData = {};
      }

      final user = UserModel(
        id: userData['id']?.toString() ?? userData['_id']?.toString() ?? '',
        name: userData['name']?.toString() ?? 'User',
        email: userData['email']?.toString() ?? email.trim(),
        phone: userData['phone']?.toString() ?? '',
        avatar:
            userData['avatar']?.toString() ??
            userData['image']?.toString() ??
            'assets/images/avt_1.png',
        token: token,
      );

      // Save user data and token
      await _saveUserData(user);

      // Set token in API service for subsequent requests
      _apiService.setAuthToken(token);

      return user;
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Login failed: ${e.toString()}');
    }
  }

  /// Register new user
  Future<UserModel> register({
    required String name,
    required String email,
    required String password,
    required String confirmPassword,
    required String phone,
    required int avatarId,
  }) async {
    try {
      final response = await _apiService.register(
        name: name,
        email: email,
        password: password,
        confirmPassword: confirmPassword,
        phone: phone,
        avatarId: avatarId,
      );

      // Debug: Print full response to see structure
      if (kDebugMode) {
        debugPrint('Registration response keys: ${response.keys.toList()}');
        debugPrint('Registration response: $response');
      }

      // Extract token and user data from response
      // Try multiple possible locations for the token
      String? token;

      // Check root level - try multiple possible field names
      token =
          response['token']?.toString() ??
          response['access_token']?.toString() ??
          response['auth_token']?.toString() ??
          response['accessToken']?.toString() ??
          response['authToken']?.toString() ??
          response['jwt']?.toString() ??
          response['jwtToken']?.toString() ??
          response['bearerToken']?.toString();

      // Check inside 'data' object if token not found
      if ((token == null || token.isEmpty) && response.containsKey('data')) {
        final dataObj = response['data'];
        if (dataObj is Map<String, dynamic>) {
          token =
              dataObj['token']?.toString() ??
              dataObj['access_token']?.toString() ??
              dataObj['auth_token']?.toString() ??
              dataObj['accessToken']?.toString() ??
              dataObj['authToken']?.toString() ??
              dataObj['jwt']?.toString() ??
              dataObj['jwtToken']?.toString() ??
              dataObj['bearerToken']?.toString();
        }
      }

      // Check inside 'user' object if token not found
      if ((token == null || token.isEmpty) && response.containsKey('user')) {
        final userObj = response['user'];
        if (userObj is Map<String, dynamic>) {
          token =
              userObj['token']?.toString() ??
              userObj['access_token']?.toString() ??
              userObj['auth_token']?.toString() ??
              userObj['accessToken']?.toString() ??
              userObj['authToken']?.toString() ??
              userObj['jwt']?.toString() ??
              userObj['jwtToken']?.toString() ??
              userObj['bearerToken']?.toString();
        }
      }

      // If token is not found, check if API might not require it immediately
      // Some APIs return token in a separate call or use session-based auth
      if (token == null || token.isEmpty) {
        if (kDebugMode) {
          debugPrint('=== Token Extraction Failed (Register) ===');
          debugPrint('Response structure: $response');
          debugPrint('Available keys: ${response.keys.toList()}');
          debugPrint('Response type: ${response.runtimeType}');
          // Try to find any field that might contain a token
          response.forEach((key, value) {
            if (key.toString().toLowerCase().contains('token') ||
                key.toString().toLowerCase().contains('auth') ||
                key.toString().toLowerCase().contains('jwt')) {
              debugPrint('Found potential token field "$key": $value');
            }
          });
          debugPrint('==========================================');
        }
        
        // Check if registration was successful but token is optional
        // Some APIs might require login after registration
        final hasUserData = response.containsKey('user') || 
                           response.containsKey('data') ||
                           response.containsKey('id');
        
        // If registration was successful (has user data) but no token,
        // some APIs require login after registration
        if (hasUserData) {
          if (kDebugMode) {
            debugPrint('Registration successful but no token found in response.');
            debugPrint('This might be expected - user may need to login separately.');
          }
          
          // Extract user data even without token - ensure it's a Map
          dynamic rawUserData = response['user'] ?? response['data'] ?? response;
          
          // Convert to Map if it's a List (take first item) or ensure it's a Map
          Map<String, dynamic> userData;
          if (rawUserData is List && rawUserData.isNotEmpty) {
            // If it's a list, take the first element
            userData = rawUserData[0] is Map<String, dynamic> 
                ? rawUserData[0] as Map<String, dynamic>
                : {};
          } else if (rawUserData is Map<String, dynamic>) {
            userData = rawUserData;
          } else {
            // Fallback to empty map if type is unexpected
            userData = {};
          }
          
          // Create user model with empty token - user will need to login
          final user = UserModel(
            id: userData['id']?.toString() ?? userData['_id']?.toString() ?? '',
            name: userData['name']?.toString() ?? name,
            email: userData['email']?.toString() ?? email.trim(),
            phone: userData['phone']?.toString() ?? phone,
            avatar:
                userData['avatar']?.toString() ??
                userData['image']?.toString() ??
                'assets/images/avt_${avatarId}.png',
            token: '', // Empty token - user needs to login
          );
          
          // Save user data (without token)
          await _saveUserData(user);
          
          // Return user without token - user will need to login separately
          return user;
        }
        
        throw ApiException(
          'No authentication token received from server. Response keys: ${response.keys.join(", ")}',
        );
      }

      // Extract user data - ensure it's a Map before accessing with string keys
      dynamic rawUserData = response['user'] ?? response['data'] ?? response;
      
      // Convert to Map if it's a List (take first item) or ensure it's a Map
      Map<String, dynamic> userData;
      if (rawUserData is List && rawUserData.isNotEmpty) {
        // If it's a list, take the first element
        userData = rawUserData[0] is Map<String, dynamic> 
            ? rawUserData[0] as Map<String, dynamic>
            : {};
      } else if (rawUserData is Map<String, dynamic>) {
        userData = rawUserData;
      } else {
        // Fallback to empty map if type is unexpected
        userData = {};
      }

      final user = UserModel(
        id: userData['id']?.toString() ?? userData['_id']?.toString() ?? '',
        name: userData['name']?.toString() ?? name,
        email: userData['email']?.toString() ?? email.trim(),
        phone: userData['phone']?.toString() ?? phone,
        avatar:
            userData['avatar']?.toString() ??
            userData['image']?.toString() ??
            'assets/images/avt_${avatarId}.png',
        token: token,
      );

      // Save user data and token
      await _saveUserData(user);

      // Set token in API service for subsequent requests
      _apiService.setAuthToken(token);

      return user;
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Registration failed: ${e.toString()}');
    }
  }

  /// Send password reset email
  Future<void> forgotPassword(String email) async {
    try {
      await _apiService.forgotPassword(email);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        'Failed to send password reset email: ${e.toString()}',
      );
    }
  }

  /// Get current user from API
  Future<UserModel?> getCurrentUser() async {
    try {
      final isLoggedIn = _prefsManager.getBool(_keyIsLoggedIn) ?? false;
      if (!isLoggedIn) {
        return null;
      }

      final token = _prefsManager.getString(_keyToken);
      if (token == null || token.isEmpty) {
        await _clearUserData();
        return null;
      }

      // Set token for API request
      _apiService.setAuthToken(token);

      // Fetch user profile from API
      final userData = await _apiService.getProfile();

      final user = UserModel(
        id: userData['id']?.toString() ?? userData['_id']?.toString() ?? '',
        name: userData['name']?.toString() ?? 'User',
        email: userData['email']?.toString() ?? '',
        phone: userData['phone']?.toString() ?? '',
        avatar:
            userData['avatar']?.toString() ??
            userData['image']?.toString() ??
            'assets/images/avt_1.png',
        token: token,
      );

      // Update stored user data
      await _saveUserData(user);

      return user;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error getting current user: $e');
      }
      // On error, try to load from local storage as fallback
      return _getCurrentUserFromLocal();
    }
  }

  /// Get current user from local storage (fallback)
  Future<UserModel?> _getCurrentUserFromLocal() async {
    try {
      final isLoggedIn = _prefsManager.getBool(_keyIsLoggedIn) ?? false;
      if (!isLoggedIn) {
        return null;
      }

      final userId = _prefsManager.getString(_keyUserId);
      final token = _prefsManager.getString(_keyToken);

      if (userId == null || token == null) {
        await _clearUserData();
        return null;
      }

      final userDataJson = _prefsManager.getString(_keyUserData);
      if (userDataJson == null) {
        await _clearUserData();
        return null;
      }

      // Parse stored user data (assuming it's stored as JSON string)
      // This is a fallback, so we'll construct a basic user model
      return UserModel(
        id: userId,
        name: 'User',
        email: '',
        phone: '',
        avatar: 'assets/images/avt_1.png',
        token: token,
      );
    } catch (e) {
      await _clearUserData();
      return null;
    }
  }

  /// Update user profile
  Future<UserModel> updateProfile({
    String? name,
    String? phone,
    String? avatar,
  }) async {
    try {
      final token = _prefsManager.getString(_keyToken);
      if (token == null || token.isEmpty) {
        throw ApiException('User not authenticated');
      }

      _apiService.setAuthToken(token);

      final userData = await _apiService.updateProfile(
        name: name,
        phone: phone,
        avatar: avatar,
      );

      final updatedUser = UserModel(
        id: userData['id']?.toString() ?? userData['_id']?.toString() ?? '',
        name: userData['name']?.toString() ?? name ?? '',
        email: userData['email']?.toString() ?? '',
        phone: userData['phone']?.toString() ?? phone ?? '',
        avatar:
            userData['avatar']?.toString() ??
            userData['image']?.toString() ??
            avatar ??
            'assets/images/avt_1.png',
        token: token,
      );

      // Update stored user data
      await _saveUserData(updatedUser);

      return updatedUser;
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Failed to update profile: ${e.toString()}');
    }
  }

  /// Check if user is logged in
  bool isLoggedIn() {
    return _prefsManager.getBool(_keyIsLoggedIn) ?? false;
  }

  /// Logout
  Future<void> logout() async {
    // Clear token from API service
    _apiService.setAuthToken(null);
    // Clear local data
    await _clearUserData();
  }

  /// Clear user data from local storage
  Future<void> _clearUserData() async {
    await _prefsManager.remove(_keyToken);
    await _prefsManager.remove(_keyUserId);
    await _prefsManager.remove(_keyUserData);
    await _prefsManager.setBool(_keyIsLoggedIn, false);
  }

  /// Save user data to local storage
  Future<void> _saveUserData(UserModel user) async {
    await _prefsManager.setString(_keyToken, user.token ?? '');
    await _prefsManager.setString(_keyUserId, user.id);
    await _prefsManager.setString(_keyUserData, user.toJson().toString());
    await _prefsManager.setBool(_keyIsLoggedIn, true);
  }
}

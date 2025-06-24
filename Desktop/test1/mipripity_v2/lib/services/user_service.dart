import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class UserService {
  static const String _baseUrl = 'https://mipripity-api-1.onrender.com';
  
  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
  };

  // Get authorization headers with token if available
  Future<Map<String, String>> _getAuthHeaders() async {
    final headers = Map<String, String>.from(_headers);
    final token = await getAuthToken();
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  // Get current user ID from shared preferences
  Future<int?> getCurrentUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt('user_id');
    } catch (e) {
      print('Error getting current user ID: $e');
      return null;
    }
  }

  // Save user ID to shared preferences
  Future<void> saveCurrentUserId(int userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('user_id', userId);
    } catch (e) {
      print('Error saving current user ID: $e');
    }
  }

  // Get auth token from shared preferences
  Future<String?> getAuthToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('auth_token');
    } catch (e) {
      print('Error getting auth token: $e');
      return null;
    }
  }

  // Save auth token to shared preferences
  Future<void> saveAuthToken(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', token);
    } catch (e) {
      print('Error saving auth token: $e');
    }
  }

  // Clear user session
  Future<void> clearUserSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user_id');
      await prefs.remove('auth_token');
      await prefs.remove('user_data');
    } catch (e) {
      print('Error clearing user session: $e');
    }
  }

  // Register a new user
  Future<Map<String, dynamic>?> registerUser({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String phoneNumber,
    String? whatsappLink,
    String? avatarUrl,
    String userType = 'regular',
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/register'),
        headers: _headers,
        body: jsonEncode({
          'email': email,
          'password': password,
          'firstName': firstName,
          'lastName': lastName,
          'phoneNumber': phoneNumber,
          'whatsappLink': whatsappLink,
          'avatarUrl': avatarUrl,
          'userType': userType,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final userData = jsonDecode(response.body);
        
        // Save user data if registration successful
        if (userData['user'] != null) {
          await saveCurrentUserId(userData['user']['id']);
          if (userData['token'] != null) {
            await saveAuthToken(userData['token']);
          }
        }
        
        return userData;
      } else {
        print('Error registering user: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('Exception registering user: $e');
      return null;
    }
  }

  // Login user
  Future<Map<String, dynamic>?> loginUser({
    required String email,
    required String password,
    bool rememberMe = false,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/login'),
        headers: _headers,
        body: jsonEncode({
          'email': email,
          'password': password,
          'rememberMe': rememberMe,
        }),
      );

      if (response.statusCode == 200) {
        final userData = jsonDecode(response.body);
        
        // Save user data if login successful
        if (userData['user'] != null) {
          await saveCurrentUserId(userData['user']['id']);
          if (userData['token'] != null) {
            await saveAuthToken(userData['token']);
          }
        }
        
        return userData;
      } else {
        print('Error logging in user: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('Exception logging in user: $e');
      return null;
    }
  }

  // Create a new user (alternative method for direct user creation)
  Future<Map<String, dynamic>?> createUser({
    required String email,
    required String passwordHash,
    required String firstName,
    required String lastName,
    required String phoneNumber,
    String? whatsappLink,
    String? avatarUrl,
    String userType = 'regular',
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/users'),
        headers: await _getAuthHeaders(),
        body: jsonEncode({
          'email': email,
          'password_hash': passwordHash,
          'firstName': firstName,
          'lastName': lastName,
          'phoneNumber': phoneNumber,
          'whatsappLink': whatsappLink,
          'avatarUrl': avatarUrl,
          'userType': userType,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        print('Error creating user: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('Exception creating user: $e');
      return null;
    }
  }

  // Get user by email
  Future<Map<String, dynamic>?> getUserByEmail(String email) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/users/email/$email'),
        headers: await _getAuthHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return data['user'];
        }
      }
      return null;
    } catch (e) {
      print('Error fetching user by email: $e');
      return null;
    }
  }

  // Get user by ID
  Future<Map<String, dynamic>?> getUserById(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/users/$userId'),
        headers: await _getAuthHeaders(),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print('Error getting user by ID: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('Exception getting user by ID: $e');
      return null;
    }
  }

  // Update user profile
  Future<Map<String, dynamic>?> updateUserProfile({
    required int userId,
    String? firstName,
    String? lastName,
    String? phoneNumber,
    String? whatsappLink,
    String? avatarUrl,
  }) async {
    try {
      final updateData = <String, dynamic>{};
      if (firstName != null) updateData['firstName'] = firstName;
      if (lastName != null) updateData['lastName'] = lastName;
      if (phoneNumber != null) updateData['phoneNumber'] = phoneNumber;
      if (whatsappLink != null) updateData['whatsappLink'] = whatsappLink;
      if (avatarUrl != null) updateData['avatarUrl'] = avatarUrl;

      final response = await http.patch(
        Uri.parse('$_baseUrl/users/$userId'),
        headers: await _getAuthHeaders(),
        body: jsonEncode(updateData),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print('Error updating user profile: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('Exception updating user profile: $e');
      return null;
    }
  }

  // Get current user profile
  Future<Map<String, dynamic>?> getCurrentUserProfile() async {
    try {
      final userId = await getCurrentUserId();
      if (userId == null) return null;
      
      return await getUserById(userId);
    } catch (e) {
      print('Exception getting current user profile: $e');
      return null;
    }
  }

  // Logout user
  Future<bool> logoutUser() async {
    try {
      final userId = await getCurrentUserId();
      if (userId != null) {
        // Log the logout on the server
        final response = await http.post(
          Uri.parse('$_baseUrl/auth/logout/$userId'),
          headers: await _getAuthHeaders(),
        );

        // Clear local session regardless of API response
        await clearUserSession();
        
        return response.statusCode == 200;
      } else {
        // No user ID, just clear local session
        await clearUserSession();
        return true;
      }
    } catch (e) {
      print('Exception logging out user: $e');
      // Still clear local session
      await clearUserSession();
      return false;
    }
  }
  
  // Get user settings
  Future<Map<String, dynamic>?> getUserSettings(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/users/$userId/settings'),
        headers: await _getAuthHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['settings'] != null) {
          return data['settings'];
        }
      }
      print('Error getting user settings: ${response.statusCode} - ${response.body}');
      return null;
    } catch (e) {
      print('Exception getting user settings: $e');
      return null;
    }
  }

  // Get current user settings
  Future<Map<String, dynamic>?> getCurrentUserSettings() async {
    try {
      final userId = await getCurrentUserId();
      if (userId == null) return null;
      
      return await getUserSettings(userId);
    } catch (e) {
      print('Exception getting current user settings: $e');
      return null;
    }
  }

  // Update user settings
  Future<Map<String, dynamic>?> updateUserSettings(
    int userId, 
    Map<String, dynamic> settings
  ) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/users/$userId/settings'),
        headers: await _getAuthHeaders(),
        body: jsonEncode(settings),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['settings'] != null) {
          return data['settings'];
        }
      }
      print('Error updating user settings: ${response.statusCode} - ${response.body}');
      return null;
    } catch (e) {
      print('Exception updating user settings: $e');
      return null;
    }
  }

  // Update notification preferences
  Future<Map<String, dynamic>?> updateNotificationPreferences(
    int userId,
    Map<String, dynamic> notificationSettings
  ) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/users/$userId/notifications'),
        headers: await _getAuthHeaders(),
        body: jsonEncode(notificationSettings),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['notifications'] != null) {
          return data['notifications'];
        }
      }
      print('Error updating notification preferences: ${response.statusCode} - ${response.body}');
      return null;
    } catch (e) {
      print('Exception updating notification preferences: $e');
      return null;
    }
  }

  // Update security settings
  Future<Map<String, dynamic>?> updateSecuritySettings(
    int userId,
    Map<String, dynamic> securitySettings
  ) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/users/$userId/security'),
        headers: await _getAuthHeaders(),
        body: jsonEncode(securitySettings),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['security'] != null) {
          return data['security'];
        }
      }
      print('Error updating security settings: ${response.statusCode} - ${response.body}');
      return null;
    } catch (e) {
      print('Exception updating security settings: $e');
      return null;
    }
  }

  // Change user password
  Future<bool> changePassword({
    required int userId,
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/users/$userId/password'),
        headers: await _getAuthHeaders(),
        body: jsonEncode({
          'current_password': currentPassword,
          'new_password': newPassword,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['success'] == true;
      }
      print('Error changing password: ${response.statusCode} - ${response.body}');
      return false;
    } catch (e) {
      print('Exception changing password: $e');
      return false;
    }
  }

  // Check if user is authenticated
  Future<bool> isAuthenticated() async {
    try {
      final token = await getAuthToken();
      final userId = await getCurrentUserId();
      
      if (token == null || userId == null) return false;
      
      // Optionally verify token with server
      final response = await http.get(
        Uri.parse('$_baseUrl/auth/verify'),
        headers: await _getAuthHeaders(),
      );
      
      return response.statusCode == 200;
    } catch (e) {
      print('Exception checking authentication: $e');
      return false;
    }
  }

  // For demo purposes, create a default user if none exists
  Future<int> getOrCreateDefaultUser() async {
    try {
      // First check if we have a current user
      final currentUserId = await getCurrentUserId();
      if (currentUserId != null) {
        return currentUserId;
      }

      // Try to get existing demo user
      final existingUser = await getUserByEmail('demo@mipripity.com');
      if (existingUser != null) {
        final userId = existingUser['id'] as int;
        await saveCurrentUserId(userId);
        return userId;
      }

      // Create default user via registration
      final registrationResult = await registerUser(
        email: 'demo@mipripity.com',
        password: 'demo123', // In real app, use proper password
        firstName: 'Demo',
        lastName: 'User',
        phoneNumber: '+2348000000000',
        whatsappLink: 'https://wa.me/2348000000000',
        userType: 'regular',
      );

      if (registrationResult != null && registrationResult['user'] != null) {
        final userId = registrationResult['user']['id'] as int;
        return userId;
      }

      // Fallback: try to create user directly
      final newUser = await createUser(
        email: 'demo@mipripity.com',
        passwordHash: 'demo_hash',
        firstName: 'Demo',
        lastName: 'User',
        phoneNumber: '+2348000000000',
        whatsappLink: 'https://wa.me/2348000000000',
        userType: 'regular',
      );

      if (newUser != null) {
        final userId = newUser['id'] as int;
        await saveCurrentUserId(userId);
        return userId;
      }

      // Final fallback to ID 1
      await saveCurrentUserId(1);
      return 1;
    } catch (e) {
      print('Exception getting or creating default user: $e');
      // Fallback to ID 1
      await saveCurrentUserId(1);
      return 1;
    }
  }

  // Get all users (admin function)
  Future<List<Map<String, dynamic>>> getAllUsers() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/users'),
        headers: await _getAuthHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data);
      } else {
        print('Error getting all users: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Exception getting all users: $e');
      return [];
    }
  }
}
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart' as app_models;
import '../services/firebase_auth_service.dart';
import '../services/user_service.dart';
import '../api/user_api.dart';

class UserProvider extends ChangeNotifier {
  final FirebaseAuthService _authService = FirebaseAuthService();
  final UserService _userService = UserService();
  final UserApi _userApi = UserApi();
  User? _firebaseUser;
  app_models.User? _appUser;
  bool _isLoading = false;
  String? _error;

  UserProvider() {
    // Listen to Firebase auth state changes and update user accordingly
    _authService.authStateChange.listen((user) {
      _firebaseUser = user;
      if (_firebaseUser != null && _appUser == null) {
        _createAppUserFromFirebase();
      }
      notifyListeners();
    });
    // Initialize user on provider creation
    _firebaseUser = _authService.currentUser;
    _loadUserFromPrefs();
  }

  // Save user data to shared preferences
  Future<void> _saveUserToPrefs(app_models.User user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_data', jsonEncode(user.toJson()));
    } catch (e) {
      print('Error saving user to preferences: $e');
    }
  }

  // Load user data from shared preferences
  Future<void> _loadUserFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userData = prefs.getString('user_data');
      if (userData != null) {
        final Map<String, dynamic> userMap = jsonDecode(userData);
        _appUser = app_models.User.fromJson(userMap);
        notifyListeners();
      } else if (_firebaseUser != null) {
        await _createAppUserFromFirebase();
      }
    } catch (e) {
      print('Error loading user from preferences: $e');
    }
  }

  // Clear user data from shared preferences
  Future<void> _clearUserFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user_data');
    } catch (e) {
      print('Error clearing user from preferences: $e');
    }
  }

  // Create app user from Firebase user data
  Future<void> _createAppUserFromFirebase() async {
    if (_firebaseUser == null) return;

    try {
      final userEmail = _firebaseUser!.email;
      if (userEmail == null) return;

      // Firebase displayName may contain both first and last name
      final displayName = _firebaseUser!.displayName ?? '';
      final names = displayName.split(' ');
      final firstName = names.isNotEmpty ? names.first : '';
      final lastName = names.length > 1 ? names.sublist(1).join(' ') : '';
      final phoneNumber = _firebaseUser!.phoneNumber ?? '';
      // Get photo URL from Firebase user if available
      final avatarUrl = _firebaseUser!.photoURL;

      // First try to get the PostgreSQL ID from UserService
      final postgresId = await _userService.getCurrentUserId();
      
      // Use PostgreSQL ID if available, otherwise use a placeholder ID
      // We'll update this with the correct ID later when we get it from the backend
      final userId = postgresId ?? 0;

      _appUser = app_models.User(
        id: userId, // This will be updated when we get the real ID from PostgreSQL
        email: userEmail,
        firstName: firstName,
        lastName: lastName,
        phoneNumber: phoneNumber,
        whatsappLink: '', // Set if you store it elsewhere
        avatarUrl: avatarUrl,
      );

      await _saveUserToPrefs(_appUser!);
      notifyListeners();
    } catch (e) {
      print('Error creating app user from Firebase metadata: $e');
    }
  }

  // Getters
  User? get user => _firebaseUser;
  app_models.User? get appUser => _appUser;
  bool get isLoggedIn => _appUser != null || _firebaseUser != null;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Login with email and password
  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Step 1: Authenticate with Firebase
      final userCredential = await _authService.loginUser(
        email: email,
        password: password,
      );
      
      _firebaseUser = userCredential?.user;
      
      if (_firebaseUser != null) {
        // Step 2: Fetch complete user profile from PostgreSQL
        final userData = await _userService.getUserByEmail(email);
        
        if (userData != null) {
          // Make sure we're getting a proper PostgreSQL ID
          final postgresId = userData['id'];
          if (postgresId == null) {
            print('⚠️ Warning: User data from backend has no ID');
          } else {
            // Ensure it's an integer
            final userId = postgresId is String ? int.parse(postgresId) : postgresId;
            
            // Step 3: Create complete user profile with PostgreSQL ID
            _appUser = app_models.User(
              id: userId,
              email: email,
              firstName: userData['first_name'] ?? '',
              lastName: userData['last_name'] ?? '',
              phoneNumber: userData['phone_number'] ?? '',
              whatsappLink: userData['whatsapp_link'] ?? '',
              avatarUrl: userData['avatar_url'],
            );
            
            // Save the PostgreSQL ID to UserService for future use
            await _userService.saveCurrentUserId(userId);
            print('✅ User profile loaded with PostgreSQL ID: $userId');
            
            // Step 4: Save to local storage
            await _saveUserToPrefs(_appUser!);
          }
        } else {
          // Fallback: Create user from Firebase data if not found in database
          print('⚠️ User not found in database, using Firebase data');
          await _createAppUserFromFirebase();
        }
      }
      
      _isLoading = false;
      notifyListeners();
      return _appUser != null;
      
    } catch (e) {
      _error = 'Login failed: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
  
  // Fetch full user profile from backend using email
  Future<void> _fetchFullUserProfile(String email) async {
    try {
      // Get user data from backend API
      final userData = await _userService.getUserByEmail(email);
      
      if (userData != null) {
        // Get PostgreSQL ID from backend response
        final postgresId = userData['id'] ?? userData['user_id'];
        
        if (postgresId == null) {
          print('⚠️ Warning: User data from backend has no PostgreSQL ID');
          // Fallback to placeholder ID only if necessary
          await _createAppUserFromFirebase();
          return;
        }
        
        // Ensure it's an integer
        final userId = postgresId is String ? int.parse(postgresId) : postgresId;
        
        // Convert backend user data to app user model
        // Handle different field naming conventions
        final firstName = userData['first_name'] ?? userData['firstName'] ?? '';
        final lastName = userData['last_name'] ?? userData['lastName'] ?? '';
        final phoneNumber = userData['phone_number'] ?? userData['phoneNumber'] ?? '';
        final whatsappLink = userData['whatsapp_link'] ?? userData['whatsappLink'] ?? '';
        final avatarUrl = userData['avatar_url'] ?? userData['avatarUrl'] ?? userData['profile_picture'] ?? '';
        
        // Create app user with complete profile data
        _appUser = app_models.User(
          id: userId,
          email: email,
          firstName: firstName,
          lastName: lastName,
          phoneNumber: phoneNumber,
          whatsappLink: whatsappLink,
          avatarUrl: avatarUrl.isNotEmpty ? avatarUrl : null,
        );
        
        // Save the PostgreSQL ID to UserService for future use
        await _userService.saveCurrentUserId(userId);
        
        // Save complete user data to preferences
        await _saveUserToPrefs(_appUser!);
        
        print('✅ Full user profile fetched and saved with PostgreSQL ID: $userId');
      } else {
        // If backend fetch fails, fallback to Firebase data
        print('Could not fetch user profile from backend. Using Firebase data.');
        await _createAppUserFromFirebase();
      }
    } catch (e) {
      print('Error fetching full user profile: $e');
      // Fallback to Firebase data if API call fails
      await _createAppUserFromFirebase();
    }
  }

  // Login with Google
  Future<bool> loginWithGoogle() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final userCredential = await _authService.signInWithGoogle();
      
      // User canceled the sign-in
      if (userCredential == null) {
        _isLoading = false;
        notifyListeners();
        return false;
      }
      
      _firebaseUser = userCredential.user;
      
      // If we have an email, fetch full user profile from backend
      if (_firebaseUser != null && _firebaseUser!.email != null) {
        await _fetchFullUserProfile(_firebaseUser!.email!);
      } else {
        // Fallback to Firebase data if no email available
        await _createAppUserFromFirebase();
      }
      
      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _error = e.message ?? 'Google sign-in failed. Please try again.';
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Google sign-in failed. Please try again.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Register with email and password
  Future<bool> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String phoneNumber,
    required String whatsappLink,
    String? avatarUrl,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final userCredential = await _authService.registerUser(
        email: email,
        password: password,
      );
      _firebaseUser = userCredential?.user;

      // Update display name
      await _authService.updateUserProfile(
        displayName: '$firstName $lastName',
      );
      
      // Save user data to PostgreSQL database via API call
      if (_firebaseUser != null) {
        // Create temporary user object with temporary ID
        // We'll update this with the real PostgreSQL ID after API call
        _appUser = app_models.User(
          id: 0, // Temporary ID
          email: email,
          firstName: firstName,
          lastName: lastName,
          phoneNumber: phoneNumber,
          whatsappLink: whatsappLink,
          avatarUrl: avatarUrl,
        );
        
        // Make direct API call to PostgreSQL database
        final apiResult = await _userApi.saveUserToDatabase(
          firebaseUid: _firebaseUser!.uid,
          email: email,
          password: password,
          firstName: firstName,
          lastName: lastName,
          phoneNumber: phoneNumber,
          whatsappLink: whatsappLink,
          avatarUrl: avatarUrl,
        );
        
        if (apiResult['success']) {
          // Extract the PostgreSQL ID from the API response
          if (apiResult['body'] != null && apiResult['body']['id'] != null) {
            final postgresId = apiResult['body']['id'];
            // Update the user object with the real PostgreSQL ID
            _appUser = app_models.User(
              id: postgresId is String ? int.parse(postgresId) : postgresId,
              email: email,
              firstName: firstName,
              lastName: lastName,
              phoneNumber: phoneNumber,
              whatsappLink: whatsappLink,
              avatarUrl: avatarUrl,
            );
            
            // Save the PostgreSQL ID to UserService for future use
            await _userService.saveCurrentUserId(_appUser!.id);
            print('✅ Saved PostgreSQL ID: ${_appUser!.id}');
          }
        } else {
          print('Warning: Failed to save user to database: ${apiResult['body']['error']}');
          // We continue even if the API call fails, as Firebase registration was successful
        }
        
        // Save the user to preferences (with PostgreSQL ID if available)
        await _saveUserToPrefs(_appUser!);
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        _error = 'This email is already registered. Please try signing in instead.';
      } else if (e.code == 'network-request-failed') {
        _error = 'Network error. Please check your internet connection and try again.';
      } else if (e.code == 'weak-password') {
        _error = 'Password is too weak. Please use a stronger password.';
      } else {
        _error = e.message ?? 'Registration failed. Please try again.';
      }
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Registration failed. Please try again.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    _appUser = null;
    await _clearUserFromPrefs();

    try {
      await _authService.logout();
      _firebaseUser = null;
    } catch (e) {
      print('Firebase sign-out error: $e');
    }
    notifyListeners();
  }

  app_models.User? getCurrentUser() {
    return _appUser;
  }

  bool isAuthenticated() {
    return _appUser != null || _authService.isAuthenticated;
  }

  Stream<User?> get authStateChange {
    return _authService.authStateChange;
  }
}
// ignore: depend_on_referenced_packages
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class UserApi {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Register user with Firebase Auth
  Future<Map<String, dynamic>> registerUser({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String phoneNumber,
    required String whatsappLink,
  }) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      // Optionally, update display name or store extra info in Firestore
      await userCredential.user?.updateDisplayName('$firstName $lastName');
      // You can also store phoneNumber and whatsappLink in Firestore if needed

      return {
        'success': true,
        'body': {
          'uid': userCredential.user?.uid,
          'email': userCredential.user?.email,
          'displayName': userCredential.user?.displayName,
        },
        'statusCode': 200,
      };
    } on FirebaseAuthException catch (e) {
      return {
        'success': false,
        'body': {'error': e.message ?? 'Registration failed'},
        'statusCode': 400,
      };
    } catch (e) {
      return {
        'success': false,
        'body': {'error': e.toString()},
        'statusCode': 400,
      };
    }
  }

  // Login user with Firebase Auth
  Future<Map<String, dynamic>> loginUser({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return {
        'success': true,
        'body': {
          'uid': userCredential.user?.uid,
          'email': userCredential.user?.email,
          'displayName': userCredential.user?.displayName,
        },
        'statusCode': 200,
      };
    } on FirebaseAuthException catch (e) {
      return {
        'success': false,
        'body': {'error': e.message ?? 'Login failed'},
        'statusCode': 400,
      };
    } catch (e) {
      return {
        'success': false,
        'body': {'error': e.toString()},
        'statusCode': 400,
      };
    }
  }

  // Google login (stub, implement with google_sign_in if needed)
  static Future<Map<String, dynamic>> loginWithGoogle({
    String? idToken,
    String? accessToken,
    String? email,
    String? displayName,
  }) async {
    return {
      'success': false,
      'body': {'error': 'Google login not implemented in this example.'},
      'statusCode': 501,
    };
  }

  // Google register (stub, implement with google_sign_in if needed)
  static Future<Map<String, dynamic>> registerWithGoogle({
    String? idToken,
    String? accessToken,
    String? email,
    String? displayName,
    String? phoneNumber,
    String? whatsappLink,
  }) async {
    return {
      'success': false,
      'body': {'error': 'Google register not implemented in this example.'},
      'statusCode': 501,
    };
  }

  // Save user data to PostgreSQL database
  Future<Map<String, dynamic>> saveUserToDatabase({
    required String firebaseUid,
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String phoneNumber,
    required String whatsappLink,
    String? avatarUrl,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('https://mipripity-api-1.onrender.com/users'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
          'first_name': firstName,
          'last_name': lastName,
          'phone_number': phoneNumber,
          'whatsapp_link': whatsappLink,
          'avatar_url': avatarUrl,
        }),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {
          'success': true,
          'body': jsonDecode(response.body),
          'statusCode': response.statusCode,
        };
      } else {
        return {
          'success': false,
          'body': {'error': 'Failed to save user data to database: ${response.body}'},
          'statusCode': response.statusCode,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'body': {'error': 'Exception saving user data: $e'},
        'statusCode': 500,
      };
    }
  }

  // Get user profile (from Firebase Auth)
  Future<Map<String, dynamic>> getUserProfile(String userId) async {
    try {
      final user = _auth.currentUser;
      if (user != null && user.uid == userId) {
        return {
          'success': true,
          'body': {
            'uid': user.uid,
            'email': user.email,
            'displayName': user.displayName,
            'phoneNumber': user.phoneNumber,
          },
          'statusCode': 200,
        };
      } else {
        return {
          'success': false,
          'body': {'error': 'User not found or not logged in.'},
          'statusCode': 404,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'body': {'error': e.toString()},
        'statusCode': 400,
      };
    }
  }

  // Find user by email (from Firebase Auth)
  Future<Map<String, dynamic>> findUserByEmail(String email) async {
    try {
      // Firebase Auth does not support searching users by email client-side for security.
      // This should be implemented server-side if needed.
      return {
        'success': false,
        'body': {'error': 'Finding user by email is not supported client-side in Firebase Auth.'},
        'statusCode': 501,
      };
    } catch (e) {
      return {
        'success': false,
        'body': {'error': e.toString()},
        'statusCode': 400,
      };
    }
  }
}
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../database_helper.dart';

// Maximum number of retries for network requests
const int _MAX_RETRIES = 3;
// Cache key for storing listings locally
const String _LISTINGS_CACHE_KEY = 'cached_user_listings';
// Cache expiration time in minutes
const int _CACHE_EXPIRATION_MINUTES = 15;

/// A class representing a property/listing with all necessary information
class Listing {
  final String id;
  final String title;
  final String description;
  final double price;
  final String location;
  final String city;
  final String state;
  final String country;
  final String category;
  final String status;
  final String createdAt;
  final int views;
  final String image;
  final String latitude;
  final String longitude;

  Listing({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.location,
    required this.city,
    required this.state,
    required this.country,
    required this.category,
    required this.status,
    required this.createdAt,
    required this.views,
    required this.image,
    required this.latitude,
    required this.longitude,
  });

  /// Factory constructor to create a Listing from a JSON object
  factory Listing.fromJson(Map<String, dynamic> json) {
    try {
      // Set default values for image path based on category
      String defaultImagePath = 'assets/images/residential1.jpg';
      final category = json['category']?.toString().toLowerCase() ?? 'residential';
      
      if (category == 'commercial') {
        defaultImagePath = 'assets/images/commercial1.jpg';
      } else if (category == 'land') {
        defaultImagePath = 'assets/images/land1.jpeg';
      } else if (category == 'material') {
        defaultImagePath = 'assets/images/material1.jpg';
      }

      return Listing(
        id: json['id']?.toString() ?? '',
        title: json['title']?.toString() ?? 'Unknown Property',
        description: json['description']?.toString() ?? '',
        price: json['price'] is num 
            ? (json['price'] as num).toDouble() 
            : double.tryParse(json['price']?.toString() ?? '0') ?? 0.0,
        location: json['location']?.toString() ?? 'Unknown Location',
        city: json['city']?.toString() ?? '',
        state: json['state']?.toString() ?? '',
        country: json['country']?.toString() ?? 'Nigeria',
        category: json['category']?.toString() ?? 'residential',
        status: json['status']?.toString() ?? 'active',
        createdAt: json['created_at']?.toString() ?? DateTime.now().toIso8601String(),
        views: json['views'] is num 
            ? (json['views'] as num).toInt() 
            : int.tryParse(json['views']?.toString() ?? '0') ?? 0,
        image: json['image']?.toString() ?? defaultImagePath,
        latitude: json['latitude']?.toString() ?? '0',
        longitude: json['longitude']?.toString() ?? '0',
      );
    } catch (e) {
      print('Error parsing Listing from JSON: $e');
      print('Problematic JSON: $json');
      // Return a default listing on error to avoid app crashes
      return Listing(
        id: json['id']?.toString() ?? '',
        title: 'Error parsing listing data',
        description: '',
        price: 0.0,
        location: 'Unknown Location',
        city: '',
        state: '',
        country: 'Nigeria',
        category: 'residential',
        status: 'active',
        createdAt: DateTime.now().toIso8601String(),
        views: 0,
        image: 'assets/images/residential1.jpg',
        latitude: '0',
        longitude: '0',
      );
    }
  }

  /// Convert this Listing to a JSON object
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'price': price,
      'location': location,
      'city': city,
      'state': state,
      'country': country,
      'category': category,
      'status': status,
      'created_at': createdAt,
      'views': views,
      'image': image,
      'latitude': latitude,
      'longitude': longitude,
    };
  }
}

/// API class for handling listing-related operations
class ListingsApi {
  // Production URL for the API
  static const String _apiBaseUrl = 'https://mipripity-api-1.onrender.com';
  
  // HTTP client with persistent connection for better performance
  static final http.Client _httpClient = http.Client();
  
  // Database helper for local storage
  static final DatabaseHelper _dbHelper = DatabaseHelper();
  
  // Dispose client when done
  static void dispose() {
    _httpClient.close();
  }
  
  // Enhanced headers with User-Agent and better error handling
  static Map<String, String> _getHeaders() {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'User-Agent': 'MipripityApp/1.0',
      'Connection': 'keep-alive',
    };
  }

  // Check network connectivity using a lightweight HTTP request
  static Future<bool> _hasNetworkConnection() async {
    try {
      // Make a lightweight request to a reliable endpoint
      final response = await _httpClient.head(
        Uri.parse('https://www.google.com'),
        headers: _getHeaders(),
      ).timeout(const Duration(seconds: 5));
      
      return response.statusCode >= 200 && response.statusCode < 500;
    } on SocketException catch (_) {
      print('Network connectivity check failed: No internet connection');
      return false;
    } on TimeoutException catch (_) {
      print('Network connectivity check timed out');
      return false;
    } catch (e) {
      print('Error checking network connectivity: $e');
      // Default to assuming connectivity is available if we can't check
      return true;
    }
  }
  
  // Save listings to local cache
  static Future<void> _saveToCache(List<Listing> listings) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      final jsonData = jsonEncode({
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'data': listings.map((l) => l.toJson()).toList(),
      });
      
      await prefs.setString(_LISTINGS_CACHE_KEY, jsonData);
      print('Successfully saved ${listings.length} listings to cache');
    } catch (e) {
      print('Error saving listings to cache: $e');
    }
  }
  
  // Load listings from local cache
  static Future<List<Listing>?> _loadFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonData = prefs.getString(_LISTINGS_CACHE_KEY);
      
      if (jsonData == null) {
        print('No cached listings found');
        return null;
      }
      
      final cacheData = jsonDecode(jsonData) as Map<String, dynamic>;
      final timestamp = cacheData['timestamp'] as int;
      final currentTime = DateTime.now().millisecondsSinceEpoch;
      
      // Check if cache is expired
      final cacheAgeMinutes = (currentTime - timestamp) / (1000 * 60);
      if (cacheAgeMinutes > _CACHE_EXPIRATION_MINUTES) {
        print('Cached listings expired (${cacheAgeMinutes.toStringAsFixed(1)} minutes old)');
        return null;
      }
      
      // Parse listings from cache
      final List<dynamic> data = cacheData['data'];
      final listings = data.map((json) => Listing.fromJson(json)).toList();
      print('Loaded ${listings.length} listings from cache');
      
      return listings;
    } catch (e) {
      print('Error loading listings from cache: $e');
      return null;
    }
  }

  // Wake up the service (useful for cold starts on Render.com)
  static Future<bool> _wakeUpService() async {
    try {
      print('Attempting to wake up Render.com service...');
      
      // Use the root endpoint
      final response = await _httpClient.get(
        Uri.parse(_apiBaseUrl),
        headers: _getHeaders(),
      ).timeout(
        const Duration(seconds: 90), // Longer timeout for cold starts
      );
      
      print('Wake up response status: ${response.statusCode}');
      
      // Consider 404 as an acceptable response since the main goal is to wake up the service
      return response.statusCode >= 200 && response.statusCode < 500 || response.statusCode == 404;
    } catch (e) {
      print('Service wake up failed: $e');
      // Return true to let the main request attempt continue
      return true;
    }
  }

  // Make a single API request with proper error handling
  static Future<List<Listing>> _makeApiRequest(String endpoint, {Map<String, String>? queryParams}) async {
    try {
      String url = '$_apiBaseUrl/$endpoint';
      
      // Add query parameters if provided
      if (queryParams != null && queryParams.isNotEmpty) {
        url += '?';
        queryParams.forEach((key, value) {
          url += '$key=${Uri.encodeComponent(value)}&';
        });
        url = url.substring(0, url.length - 1); // Remove the trailing &
      }
      
      print('Fetching listings from: $url');
      
      final response = await _httpClient.get(
        Uri.parse(url),
        headers: _getHeaders(),
      ).timeout(
        const Duration(seconds: 60),
        onTimeout: () {
          throw TimeoutException('Request timed out after 60 seconds');
        },
      );
      
      print('API response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final responseBody = response.body;
        print('Response received, length: ${responseBody.length} bytes');
        
        if (responseBody.isEmpty) {
          print('Empty response body - returning empty list');
          return [];
        }
        
        final dynamic decodedData = jsonDecode(responseBody);
        
        // Handle the server response format
        List<dynamic> data;
        if (decodedData is List) {
          // Direct array response from server
          data = decodedData;
        } else if (decodedData is Map<String, dynamic>) {
          // If the response is wrapped in an object, look for common keys
          if (decodedData.containsKey('data')) {
            data = decodedData['data'] as List<dynamic>;
          } else if (decodedData.containsKey('listings')) {
            data = decodedData['listings'] as List<dynamic>;
          } else if (decodedData.containsKey('results')) {
            data = decodedData['results'] as List<dynamic>;
          } else if (decodedData.containsKey('properties')) {
            data = decodedData['properties'] as List<dynamic>;
          } else {
            // Single object response, wrap in array
            data = [decodedData];
          }
        } else {
          print('Unexpected response format: ${decodedData.runtimeType}');
          throw Exception('Unexpected response format: ${decodedData.runtimeType}');
        }
        
        print('Successfully decoded JSON with ${data.length} items');
        
        if (data.isEmpty) {
          print('No listings found in response');
          return [];
        }
        
        // Parse each listing item
        final listings = <Listing>[];
        for (int i = 0; i < data.length; i++) {
          try {
            final listingData = data[i];
            if (listingData is Map<String, dynamic>) {
              final listing = Listing.fromJson(listingData);
              listings.add(listing);
            } else {
              print('Skipping invalid listing data at index $i: ${listingData.runtimeType}');
            }
          } catch (e) {
            print('Error parsing listing at index $i: $e');
            // Continue with other listings instead of failing completely
          }
        }
        
        print('Successfully parsed ${listings.length} listings out of ${data.length} items');
        return listings;
      } else {
        final errorBody = response.body;
        print('HTTP error ${response.statusCode}: $errorBody');
        throw HttpException('HTTP ${response.statusCode}: $errorBody');
      }
    } catch (e) {
      print('API request error: $e');
      rethrow;
    }
  }

  // Get all listings for the current user
  static Future<List<Listing>> getUserListings({bool forceRefresh = false}) async {
    print('Getting user listings (forceRefresh: $forceRefresh)');
    
    // Check network connectivity first
    final hasConnection = await _hasNetworkConnection();
    if (!hasConnection) {
      print('No network connection available');
      throw Exception('No internet connection. Please check your network and try again.');
    }
    
    // Check if we should try to use cache first
    if (!forceRefresh) {
      final cachedListings = await _loadFromCache();
      if (cachedListings != null && cachedListings.isNotEmpty) {
        print('Using cached listings (${cachedListings.length} items)');
        return cachedListings;
      }
    }
    
    // Try to wake up the service first (for Render.com cold starts)
    await _wakeUpService();
    
    // Implement retry logic with exponential backoff
    Exception? lastException;
    
    for (int attempt = 0; attempt < _MAX_RETRIES; attempt++) {
      try {
        if (attempt > 0) {
          print('Retry attempt $attempt/$_MAX_RETRIES for user listings');
          // Exponential backoff: 2s, 4s, 8s
          final delaySeconds = math.pow(2, attempt).toInt();
          await Future.delayed(Duration(seconds: delaySeconds));
        }
        
        // Get the current user ID
        final userId = await _getUserId();
        print('Fetching listings for user ID: $userId');
        
        // Fetch user listings from API - IMPORTANT: user_id is the parameter expected by the backend
        final listings = await _makeApiRequest('properties/user', 
          queryParams: {'user_id': userId}
        );
        
        // Save to cache for offline use
        if (listings.isNotEmpty) {
          await _saveToCache(listings);
          print('Successfully fetched and cached ${listings.length} listings');
        }
        
        return listings;
      } catch (e) {
        print('Error on attempt ${attempt + 1}/$_MAX_RETRIES: $e');
        lastException = e is Exception ? e : Exception('Network error: $e');
        
        // Don't retry on certain errors
        if (e is FormatException) {
          print('Format error, stopping retries');
          break;
        }
      }
    }
    
    // All retries failed, try to use cached data as fallback
    print('All API attempts failed, trying cache as fallback');
    final cachedListings = await _loadFromCache();
    if (cachedListings != null && cachedListings.isNotEmpty) {
      print('Using cached listings after API failure');
      return cachedListings;
    }
    
    // No data available anywhere - throw the last exception
    throw lastException ?? Exception('Failed to fetch listings from server. Please try again later.');
  }

  // Delete a listing
  static Future<bool> deleteListing(String listingId) async {
    print('Deleting listing $listingId');
    
    // Check network connectivity first
    if (!await _hasNetworkConnection()) {
      print('No network connection for deleting listing');
      throw Exception('No internet connection. Please check your network and try again.');
    }
    
    try {
      // Send the delete request to the API
      final response = await _httpClient.delete(
        Uri.parse('$_apiBaseUrl/properties/$listingId'),
        headers: _getHeaders(),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw TimeoutException('Request timed out after 30 seconds');
        },
      );
      
      print('Delete listing response status: ${response.statusCode}');
      
      if (response.statusCode == 200 || response.statusCode == 204) {
        // Clear the cache to force a refresh
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(_LISTINGS_CACHE_KEY);
        
        return true;
      } else {
        print('Failed to delete listing: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to delete listing. Server returned: ${response.statusCode}');
      }
    } catch (e) {
      print('Error deleting listing: $e');
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Failed to delete listing: $e');
    }
  }

  // Get authenticated user ID or generate a temporary one if not available
  static Future<String> _getUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // First try to get the user data saved by UserProvider
      final userData = prefs.getString('user_data');
      if (userData != null && userData.isNotEmpty) {
        try {
          // Parse the user data JSON
          final Map<String, dynamic> userMap = jsonDecode(userData);
          
          // Extract the user ID and convert it to string
          if (userMap.containsKey('id')) {
            final userId = userMap['id'];
            // Convert to string regardless of original type (int or String)
            return userId.toString();
          }
        } catch (e) {
          print('Error parsing user data: $e');
          // Continue to fallback methods
        }
      }
      
      // Fallback 1: Check if we have a currentUserId saved by UserService
      final currentUserId = prefs.getInt('currentUserId');
      if (currentUserId != null) {
        return currentUserId.toString();
      }
      
      // Fallback 2: Check if we have a standalone user_id saved
      String? userId = prefs.getString('user_id');
      if (userId != null && userId.isNotEmpty) {
        return userId;
      }
      
      // Last resort: Generate a temporary ID
      final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final randomPart = math.Random().nextInt(10000).toString();
      userId = 'temp_${timestamp}_$randomPart';
      
      // No need to save temporary IDs
      print('Using temporary user ID: $userId');
      return userId;
    } catch (e) {
      print('Error getting/generating user ID: $e');
      // Return a temporary ID if all methods fail
      final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final randomPart = math.Random().nextInt(10000).toString();
      return 'temp_${timestamp}_$randomPart';
    }
  }

  // Clear all cached data
  static Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_LISTINGS_CACHE_KEY);
      print('Cache cleared successfully');
    } catch (e) {
      print('Error clearing cache: $e');
    }
  }
}
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../database_helper.dart';

// Maximum number of retries for network requests
const int _MAX_RETRIES = 3;
// Cache key for storing bids locally
const String _BIDS_CACHE_KEY = 'cached_user_bids';
// Cache expiration time in minutes
const int _CACHE_EXPIRATION_MINUTES = 15;

/// A class representing a bid with all necessary information
class Bid {
  final String id;
  final String listingId;
  final String listingTitle;
  final String listingImage;
  final String listingCategory;
  final String listingLocation;
  final double listingPrice;
  final double bidAmount;
  final String status; // 'pending', 'accepted', 'rejected', 'expired', 'withdrawn'
  final String createdAt;
  final String? responseMessage;
  final String? responseDate;
  final String? userId;

  Bid({
    required this.id,
    required this.listingId,
    required this.listingTitle,
    required this.listingImage,
    required this.listingCategory,
    required this.listingLocation,
    required this.listingPrice,
    required this.bidAmount,
    required this.status,
    required this.createdAt,
    this.responseMessage,
    this.responseDate,
    this.userId,
  });

  /// Factory constructor to create a Bid from a JSON object
  factory Bid.fromJson(Map<String, dynamic> json) {
    try {
      // Set default values for image path based on category
      String defaultImagePath = 'assets/images/residential1.jpg';
      final category = json['listing_category']?.toString()?.toLowerCase() ?? 'residential';
      
      if (category == 'commercial') {
        defaultImagePath = 'assets/images/commercial1.jpg';
      } else if (category == 'land') {
        defaultImagePath = 'assets/images/land1.jpeg';
      } else if (category == 'material') {
        defaultImagePath = 'assets/images/material1.jpg';
      }

      return Bid(
        id: json['id']?.toString() ?? json['bid_id']?.toString() ?? '0',
        listingId: json['listing_id']?.toString() ?? json['property_id']?.toString() ?? '0',
        listingTitle: json['listing_title']?.toString() ?? json['property_title']?.toString() ?? 'Unknown Property',
        listingImage: json['listing_image']?.toString() ?? json['property_image']?.toString() ?? defaultImagePath,
        listingCategory: json['listing_category']?.toString() ?? json['property_category']?.toString() ?? 'residential',
        listingLocation: json['listing_location']?.toString() ?? json['property_location']?.toString() ?? 'Unknown Location',
        listingPrice: json['listing_price'] is num 
            ? (json['listing_price'] as num).toDouble() 
            : double.tryParse(json['listing_price']?.toString() ?? '0') ?? 0.0,
        bidAmount: json['bid_amount'] is num 
            ? (json['bid_amount'] as num).toDouble() 
            : double.tryParse(json['bid_amount']?.toString() ?? '0') ?? 0.0,
        status: json['status']?.toString() ?? 'pending',
        createdAt: json['created_at']?.toString() ?? DateTime.now().toIso8601String(),
        responseMessage: json['response_message']?.toString(),
        responseDate: json['response_date']?.toString(),
        userId: json['user_id']?.toString(),
      );
    } catch (e) {
      print('Error parsing Bid: $e');
      // Return a default bid on error to avoid app crashes
      return Bid(
        id: json['id']?.toString() ?? '0',
        listingId: json['listing_id']?.toString() ?? '0',
        listingTitle: 'Error parsing bid data',
        listingImage: 'assets/images/residential1.jpg',
        listingCategory: 'residential',
        listingLocation: 'Unknown Location',
        listingPrice: 0.0,
        bidAmount: 0.0,
        status: 'pending',
        createdAt: DateTime.now().toIso8601String(),
      );
    }
  }

  /// Convert this Bid to a JSON object
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'listing_id': listingId,
      'listing_title': listingTitle,
      'listing_image': listingImage,
      'listing_category': listingCategory,
      'listing_location': listingLocation,
      'listing_price': listingPrice,
      'bid_amount': bidAmount,
      'status': status,
      'created_at': createdAt,
      'response_message': responseMessage,
      'response_date': responseDate,
      'user_id': userId,
    };
  }
}

/// API class for handling bid-related operations
class BidsApi {
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

  // Check network connectivity
  static Future<bool> _hasNetworkConnection() async {
    try {
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 5));
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
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
  
  // Save bids to local cache
  static Future<void> _saveToCache(List<Bid> bids) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      final jsonData = jsonEncode({
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'data': bids.map((b) => b.toJson()).toList(),
      });
      
      await prefs.setString(_BIDS_CACHE_KEY, jsonData);
      print('Successfully saved ${bids.length} bids to cache');
    } catch (e) {
      print('Error saving bids to cache: $e');
    }
  }
  
  // Load bids from local cache
  static Future<List<Bid>?> _loadFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonData = prefs.getString(_BIDS_CACHE_KEY);
      
      if (jsonData == null) {
        print('No cached bids found');
        return null;
      }
      
      final cacheData = jsonDecode(jsonData) as Map<String, dynamic>;
      final timestamp = cacheData['timestamp'] as int;
      final currentTime = DateTime.now().millisecondsSinceEpoch;
      
      // Check if cache is expired
      final cacheAgeMinutes = (currentTime - timestamp) / (1000 * 60);
      if (cacheAgeMinutes > _CACHE_EXPIRATION_MINUTES) {
        print('Cached bids expired (${cacheAgeMinutes.toStringAsFixed(1)} minutes old)');
        return null;
      }
      
      // Parse bids from cache
      final List<dynamic> data = cacheData['data'];
      final bids = data.map((json) => Bid.fromJson(json)).toList();
      print('Loaded ${bids.length} bids from cache');
      
      return bids;
    } catch (e) {
      print('Error loading bids from cache: $e');
      return null;
    }
  }

  // Wake up the service (useful for cold starts on Render.com)
  static Future<bool> _wakeUpService() async {
    try {
      print('Attempting to wake up Render.com service...');
      
      final response = await _httpClient.get(
        Uri.parse('$_apiBaseUrl/health'),
        headers: _getHeaders(),
      ).timeout(
        const Duration(seconds: 90), // Longer timeout for cold starts
      );
      
      print('Wake up response status: ${response.statusCode}');
      return response.statusCode >= 200 && response.statusCode < 500;
    } catch (e) {
      print('Service wake up failed: $e');
      // Return true to let the main request attempt continue
      return true;
    }
  }

  // Make a single API request with proper error handling
  static Future<List<Bid>> _makeApiRequest(String endpoint, {Map<String, String>? queryParams}) async {
    try {
      String url = '$_apiBaseUrl/$endpoint';
      
      // Add query parameters if provided
      if (queryParams != null && queryParams.isNotEmpty) {
        url += '?';
        queryParams.forEach((key, value) {
          url += '$key=$value&';
        });
        url = url.substring(0, url.length - 1); // Remove the trailing &
      }
      
      print('Fetching bids from: $url');
      
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
          throw Exception('Empty response body received');
        }
        
        final dynamic decodedData = jsonDecode(responseBody);
        
        // Handle both array and object responses
        List<dynamic> data;
        if (decodedData is List) {
          data = decodedData;
        } else if (decodedData is Map<String, dynamic>) {
          // If the response is wrapped in an object, look for common keys
          if (decodedData.containsKey('data')) {
            data = decodedData['data'] as List<dynamic>;
          } else if (decodedData.containsKey('bids')) {
            data = decodedData['bids'] as List<dynamic>;
          } else if (decodedData.containsKey('results')) {
            data = decodedData['results'] as List<dynamic>;
          } else {
            // Single object response, wrap in array
            data = [decodedData];
          }
        } else {
          throw Exception('Unexpected response format: ${decodedData.runtimeType}');
        }
        
        print('Successfully decoded JSON with ${data.length} bids');
        
        if (data.isEmpty) {
          print('No bids found in response');
          return [];
        }
        
        final bids = data.map((json) {
          try {
            return Bid.fromJson(json as Map<String, dynamic>);
          } catch (e) {
            print('Error parsing individual bid: $e');
            return null;
          }
        }).where((bid) => bid != null).cast<Bid>().toList();
        
        print('Successfully parsed ${bids.length} bids');
        return bids;
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

  // Get all bids for the current user
  static Future<List<Bid>> getUserBids({bool forceRefresh = false}) async {
    print('Getting user bids (forceRefresh: $forceRefresh)');
    
    // Check if we should try to use cache first
    if (!forceRefresh) {
      final cachedBids = await _loadFromCache();
      if (cachedBids != null && cachedBids.isNotEmpty) {
        print('Using cached bids (${cachedBids.length} items)');
        return cachedBids;
      }
    }
    
    // Check network connectivity
    final hasConnection = await _hasNetworkConnection();
    if (!hasConnection) {
      print('No network connection available, trying to load from cache');
      final cachedBids = await _loadFromCache();
      if (cachedBids != null && cachedBids.isNotEmpty) {
        print('Using cached bids due to no network');
        return cachedBids;
      }
      
      // Try to get bids from local database
      try {
        final dbBids = await _dbHelper.getBids();
        if (dbBids.isNotEmpty) {
          print('Using database bids due to no network');
          return dbBids.map((bidMap) => Bid.fromJson(bidMap)).toList();
        }
      } catch (e) {
        print('Error fetching bids from database: $e');
      }
      
      // Return mock data as last resort for no network
      return _getMockBids();
    }
    
    // Try to wake up the service first (for Render.com cold starts)
    await _wakeUpService();
    
    // Implement retry logic with exponential backoff
    Exception? lastException;
    
    for (int attempt = 0; attempt < _MAX_RETRIES; attempt++) {
      try {
        if (attempt > 0) {
          print('Retry attempt $attempt/$_MAX_RETRIES for user bids');
          // Exponential backoff: 2s, 4s, 8s
          final delaySeconds = math.pow(2, attempt).toInt();
          await Future.delayed(Duration(seconds: delaySeconds));
        }
        
        // Get the current user ID
        final userId = await _getUserId();
        
        // Fetch user bids from API
        final bids = await _makeApiRequest('bids', 
          queryParams: {'user_id': userId}
        );
        
        // Save to cache for offline use
        if (bids.isNotEmpty) {
          await _saveToCache(bids);
          
          // Also save to local database
          for (final bid in bids) {
            await _dbHelper.saveBid(bid.toJson());
          }
          
          print('Successfully fetched and cached ${bids.length} bids');
        }
        
        return bids;
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
    final cachedBids = await _loadFromCache();
    if (cachedBids != null && cachedBids.isNotEmpty) {
      print('Using cached bids after API failure');
      return cachedBids;
    }
    
    // Try to get bids from local database
    try {
      final dbBids = await _dbHelper.getBids();
      if (dbBids.isNotEmpty) {
        print('Using database bids after API failure');
        return dbBids.map((bidMap) => Bid.fromJson(bidMap)).toList();
      }
    } catch (e) {
      print('Error fetching bids from database: $e');
    }
    
    // No cached data available, use mock data as final fallback
    return _getMockBids();
  }

  // Create a new bid
  static Future<bool> createBid({
    required String listingId,
    required String listingTitle,
    required String listingImage,
    required String listingCategory,
    required String listingLocation,
    required double listingPrice,
    required double bidAmount,
  }) async {
    print('Creating bid for listing $listingId');
    
    // Check network connectivity first
    if (!await _hasNetworkConnection()) {
      print('No network connection for creating bid');
      return false;
    }
    
    try {
      // Get the current user ID
      final userId = await _getUserId();
      
      // Create the bid request body
      final requestBody = {
        'user_id': userId,
        'listing_id': listingId,
        'listing_title': listingTitle,
        'listing_image': listingImage,
        'listing_category': listingCategory,
        'listing_location': listingLocation,
        'listing_price': listingPrice,
        'bid_amount': bidAmount,
        'status': 'pending',
        'created_at': DateTime.now().toIso8601String(),
      };
      
      // Send the bid to the API
      final response = await _httpClient.post(
        Uri.parse('$_apiBaseUrl/bids'),
        headers: _getHeaders(),
        body: jsonEncode(requestBody),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw TimeoutException('Request timed out after 30 seconds');
        },
      );
      
      print('Create bid response status: ${response.statusCode}');
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        final bidId = responseData['id']?.toString() ?? '';
        
        // Save the bid to the local database
        final bidMap = {
          ...requestBody,
          'id': bidId,
        };
        await _dbHelper.saveBid(bidMap);
        
        // Clear the cache to force a refresh
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(_BIDS_CACHE_KEY);
        
        return true;
      } else {
        print('Failed to create bid: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error creating bid: $e');
      return false;
    }
  }

  // Update an existing bid
  static Future<bool> updateBid({
    required String bidId,
    required double bidAmount,
  }) async {
    print('Updating bid $bidId');
    
    // Check network connectivity first
    if (!await _hasNetworkConnection()) {
      print('No network connection for updating bid');
      return false;
    }
    
    try {
      // Create the update request body
      final requestBody = {
        'bid_amount': bidAmount,
      };
      
      // Send the update to the API
      final response = await _httpClient.put(
        Uri.parse('$_apiBaseUrl/bids/$bidId'),
        headers: _getHeaders(),
        body: jsonEncode(requestBody),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw TimeoutException('Request timed out after 30 seconds');
        },
      );
      
      print('Update bid response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        // Update the bid in the local database
        await _dbHelper.updateBidAmount(bidId, bidAmount);
        
        // Clear the cache to force a refresh
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(_BIDS_CACHE_KEY);
        
        return true;
      } else {
        print('Failed to update bid: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error updating bid: $e');
      return false;
    }
  }

  // Cancel a bid (change status to 'withdrawn')
  static Future<bool> cancelBid(String bidId) async {
    print('Cancelling bid $bidId');
    
    // Check network connectivity first
    if (!await _hasNetworkConnection()) {
      print('No network connection for cancelling bid');
      return false;
    }
    
    try {
      // Create the cancel request body
      final requestBody = {
        'status': 'withdrawn',
      };
      
      // Send the cancel request to the API
      final response = await _httpClient.put(
        Uri.parse('$_apiBaseUrl/bids/$bidId'),
        headers: _getHeaders(),
        body: jsonEncode(requestBody),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw TimeoutException('Request timed out after 30 seconds');
        },
      );
      
      print('Cancel bid response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        // Update the bid status in the local database
        await _dbHelper.updateBidStatus(bidId, 'withdrawn');
        
        // Clear the cache to force a refresh
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(_BIDS_CACHE_KEY);
        
        return true;
      } else {
        print('Failed to cancel bid: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error cancelling bid: $e');
      return false;
    }
  }

  // Get or generate a user ID for creating bids
  static Future<String> _getUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? userId = prefs.getString('user_id');
      
      // If no user ID exists, generate one and save it
      if (userId == null || userId.isEmpty) {
        userId = 'user_${DateTime.now().millisecondsSinceEpoch}_${math.Random().nextInt(10000)}';
        await prefs.setString('user_id', userId);
        print('Generated new user ID: $userId');
      }
      
      return userId;
    } catch (e) {
      print('Error getting/generating user ID: $e');
      // Return a temporary ID if SharedPreferences fails
      return 'temp_${DateTime.now().millisecondsSinceEpoch}_${math.Random().nextInt(10000)}';
    }
  }

  // Generate mock bids for offline mode or initial app launch
  static List<Bid> _getMockBids() {
    print('Generating mock bids data');
    return [
      Bid(
        id: 'mock-1',
        listingId: 'listing-1',
        listingTitle: 'Beautiful 3 Bedroom Apartment',
        listingImage: 'assets/images/residential1.jpg',
        listingCategory: 'residential',
        listingLocation: 'Victoria Island, Lagos',
        listingPrice: 350000,
        bidAmount: 320000,
        status: 'pending',
        createdAt: DateTime.now().subtract(const Duration(hours: 5)).toIso8601String(),
      ),
      Bid(
        id: 'mock-2',
        listingId: 'listing-2',
        listingTitle: 'Commercial Office Space',
        listingImage: 'assets/images/commercial1.jpg',
        listingCategory: 'commercial',
        listingLocation: 'Ikeja, Lagos',
        listingPrice: 500000,
        bidAmount: 500000,
        status: 'accepted',
        createdAt: DateTime.now().subtract(const Duration(days: 2)).toIso8601String(),
        responseMessage: 'Thank you for your bid. We are pleased to accept your offer.',
        responseDate: DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
      ),
      Bid(
        id: 'mock-3',
        listingId: 'listing-3',
        listingTitle: 'Land Property with C of O',
        listingImage: 'assets/images/land1.jpeg',
        listingCategory: 'land',
        listingLocation: 'Lekki, Lagos',
        listingPrice: 250000,
        bidAmount: 200000,
        status: 'rejected',
        createdAt: DateTime.now().subtract(const Duration(days: 5)).toIso8601String(),
        responseMessage: 'Thank you for your interest. Unfortunately, your bid was too low for consideration.',
        responseDate: DateTime.now().subtract(const Duration(days: 3)).toIso8601String(),
      ),
    ];
  }
}
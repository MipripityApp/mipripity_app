import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// Maximum number of retries for network requests
const int _MAX_RETRIES = 3;
// Cache key for storing poll properties locally
const String _POLL_PROPERTIES_CACHE_KEY = 'cached_poll_properties';
// Cache expiration time in minutes
const int _CACHE_EXPIRATION_MINUTES = 30;

class PollSuggestion {
  final String suggestion;
  int votes;

  PollSuggestion({
    required this.suggestion,
    required this.votes,
  });

  factory PollSuggestion.fromJson(Map<String, dynamic> json) {
    return PollSuggestion(
      suggestion: json['suggestion']?.toString() ?? '',
      votes: json['votes'] is int ? json['votes'] : int.tryParse(json['votes']?.toString() ?? '0') ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'suggestion': suggestion,
      'votes': votes,
    };
  }
}

class PollProperty {
  final String id;
  final String title;
  final String location;
  final String imageUrl;
  final List<PollSuggestion> suggestions;

  PollProperty({
    required this.id,
    required this.title,
    required this.location,
    required this.imageUrl,
    required this.suggestions,
  });

  factory PollProperty.fromJson(Map<String, dynamic> json) {
    List<PollSuggestion> suggestionsList = [];
    
    try {
      // Handle different formats of suggestions
      if (json['suggestions'] is Map) {
        // API format: {"suggestion1": voteCount1, "suggestion2": voteCount2, ...}
        final suggestionsMap = json['suggestions'] as Map<String, dynamic>;
        
        suggestionsList = suggestionsMap.entries.map((entry) {
          return PollSuggestion(
            suggestion: entry.key,
            votes: entry.value is int ? entry.value : int.tryParse(entry.value.toString()) ?? 0,
          );
        }).toList();
      } else if (json['suggestions'] is List) {
        // Handle list format
        final suggestionsListData = json['suggestions'] as List;
        suggestionsList = suggestionsListData.map((suggestion) {
          if (suggestion is Map<String, dynamic>) {
            return PollSuggestion.fromJson(suggestion);
          } else {
            return PollSuggestion(suggestion: suggestion.toString(), votes: 0);
          }
        }).toList();
      } else if (json['poll_suggestions'] is List) {
        // Use poll_suggestions as fallback
        final pollSuggestions = json['poll_suggestions'] as List;
        final pollUserVotes = json['poll_user_votes'] as Map<String, dynamic>?;
        
        // Create suggestions list from poll_suggestions
        suggestionsList = pollSuggestions.map((suggestion) {
          final suggestionName = suggestion.toString();
          // Count votes by checking how many users voted for this suggestion
          int voteCount = 0;
          if (pollUserVotes != null) {
            voteCount = pollUserVotes.values.where((vote) => vote == suggestionName).length;
          }
          return PollSuggestion(suggestion: suggestionName, votes: voteCount);
        }).toList();
      }
      
      // Make string conversions for id if needed
      final propertyId = json['id']?.toString() ?? '0';
      
      return PollProperty(
        id: propertyId,
        title: json['title']?.toString() ?? 'Untitled Poll Property',
        location: json['location']?.toString() ?? 'Unknown Location',
        imageUrl: json['image_url']?.toString() ?? '',
        suggestions: suggestionsList.isEmpty 
            ? [PollSuggestion(suggestion: 'No suggestions available', votes: 0)]
            : suggestionsList,
      );
    } catch (e) {
      // Log the error but provide a valid object
      print('Error parsing PollProperty: $e');
      return PollProperty(
        id: json['id']?.toString() ?? '0',
        title: json['title']?.toString() ?? 'Untitled Poll Property',
        location: json['location']?.toString() ?? 'Unknown Location',
        imageUrl: json['image_url']?.toString() ?? '',
        suggestions: [PollSuggestion(suggestion: 'Error loading suggestions', votes: 0)],
      );
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'location': location,
      'image_url': imageUrl,
      'suggestions': suggestions.map((s) => s.toJson()).toList(),
    };
  }
}

class PollPropertyApi {
  // Use only production URL as the project is in production stage
  static const String _apiBaseUrl = 'https://mipripity-api-1.onrender.com';
  
  // HTTP client for connection reuse and better performance
  static http.Client? _client;
  
  // Get or create HTTP client with persistent connection
  static http.Client _getClient() {
    _client ??= http.Client();
    return _client!;
  }
  
  // Dispose client when done
  static void dispose() {
    _client?.close();
    _client = null;
  }
  
  // Enhanced headers with User-Agent and better error handling
  static Map<String, String> _getHeaders() {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'User-Agent': 'Flutter-App/1.0',
      'Connection': 'keep-alive',
    };
  }

  // Improved network connectivity check
  static Future<bool> _hasNetworkConnection() async {
    try {
      // First try a quick DNS lookup
      final addresses = await InternetAddress.lookup('google.com');
      if (addresses.isNotEmpty && addresses[0].rawAddress.isNotEmpty) {
        return true;
      }
      return false;
    } catch (e) {
      print('Network connectivity check failed: $e');
      // Fallback to HTTP check if DNS lookup fails
      try {
        final response = await http.head(
          Uri.parse('https://www.google.com'),
        ).timeout(const Duration(seconds: 5));
        return response.statusCode >= 200 && response.statusCode < 400;
      } catch (e2) {
        print('HTTP connectivity check also failed: $e2');
        return false;
      }
    }
  }
  
  // Save poll properties to local cache
  static Future<void> _saveToCache(List<PollProperty> properties) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      final jsonData = jsonEncode({
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'data': properties.map((p) => p.toJson()).toList(),
      });
      
      await prefs.setString(_POLL_PROPERTIES_CACHE_KEY, jsonData);
      print('Successfully saved ${properties.length} poll properties to cache');
    } catch (e) {
      print('Error saving poll properties to cache: $e');
    }
  }
  
  // Load poll properties from local cache
  static Future<List<PollProperty>?> _loadFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonData = prefs.getString(_POLL_PROPERTIES_CACHE_KEY);
      
      if (jsonData == null) {
        print('No cached poll properties found');
        return null;
      }
      
      final cacheData = jsonDecode(jsonData) as Map<String, dynamic>;
      final timestamp = cacheData['timestamp'] as int;
      final currentTime = DateTime.now().millisecondsSinceEpoch;
      
      // Check if cache is expired
      final cacheAgeMinutes = (currentTime - timestamp) / (1000 * 60);
      if (cacheAgeMinutes > _CACHE_EXPIRATION_MINUTES) {
        print('Cached poll properties expired (${cacheAgeMinutes.toStringAsFixed(1)} minutes old)');
        return null;
      }
      
      // Parse properties from cache
      final List<dynamic> data = cacheData['data'];
      final properties = data.map((json) => PollProperty.fromJson(json)).toList();
      print('Loaded ${properties.length} poll properties from cache');
      
      return properties;
    } catch (e) {
      print('Error loading poll properties from cache: $e');
      return null;
    }
  }

  // Wake up the Render.com service with longer timeout for cold starts
  static Future<bool> _wakeUpService() async {
    try {
      print('Attempting to wake up Render.com service...');
      
      // Use a simple health check endpoint or the main API endpoint
      final response = await _getClient().get(
        Uri.parse('$_apiBaseUrl/health'), // Try health endpoint first
        headers: _getHeaders(),
      ).timeout(
        const Duration(seconds: 60), // Longer timeout for cold starts
        onTimeout: () {
          print('Health check timeout, trying main endpoint...');
          // If health endpoint times out, try the main endpoint
          return _getClient().get(
            Uri.parse('$_apiBaseUrl/poll_properties'),
            headers: _getHeaders(),
          ).timeout(const Duration(seconds: 30));
        },
      );
      
      print('Wake up response status: ${response.statusCode}');
      return response.statusCode >= 200 && response.statusCode < 500;
    } catch (e) {
      print('Service wake up failed: $e');
      return false;
    }
  }

  // Enhanced fetch with better error handling and cold start detection
  static Future<List<PollProperty>> getPollProperties({bool forceRefresh = false}) async {
    // First try to load from cache if not forcing refresh
    if (!forceRefresh) {
      final cachedProperties = await _loadFromCache();
      if (cachedProperties != null && cachedProperties.isNotEmpty) {
        print('Using cached poll properties (${cachedProperties.length} items)');
        
        // Attempt to refresh in background if we have cached data
        _refreshInBackground();
        
        return cachedProperties;
      }
    }
    
    // Prepare mock data for demo/development
    final mockPollProperties = _getMockPollProperties();
    
    // Check network connectivity first
    bool hasConnection = await _hasNetworkConnection();
    
    if (!hasConnection) {
      print('No network connection available, trying to load from cache');
      final cachedProperties = await _loadFromCache();
      if (cachedProperties != null && cachedProperties.isNotEmpty) {
        print('Using cached poll properties due to no network');
        return cachedProperties;
      }
      
      // Return mock data if no cache and no network
      if (mockPollProperties.isNotEmpty) {
        print('Using mock poll properties due to no network and no cache');
        return mockPollProperties;
      }
      
      throw Exception('No network connection and no cached data available');
    }
    
    // Try to wake up the service first (for Render.com cold starts)
    await _wakeUpService();
    
    // Implement retry logic with exponential backoff
    Exception? lastException;
    
    for (int attempt = 0; attempt < _MAX_RETRIES; attempt++) {
      try {
        if (attempt > 0) {
          print('Retry attempt $attempt/$_MAX_RETRIES for poll properties');
          // Exponential backoff with jitter: 2s, 4s, 8s + random 0-1s
          final delaySeconds = math.pow(2, attempt).toInt() + math.Random().nextInt(1000);
          await Future.delayed(Duration(milliseconds: delaySeconds * 1000));
        }
        
        final url = '$_apiBaseUrl/poll_properties';
        print('Fetching poll properties from: $url (attempt ${attempt + 1})');
        
        final response = await _getClient().get(
          Uri.parse(url),
          headers: _getHeaders(),
        ).timeout(
          // Longer timeout for first attempt (cold start), shorter for retries
          Duration(seconds: attempt == 0 ? 60 : 30),
        );
        
        print('API response status: ${response.statusCode}');
        
        if (response.statusCode == 200) {
          final responseBody = response.body;
          print('Response received, length: ${responseBody.length} bytes');
          
          if (responseBody.isEmpty) {
            print('Empty response body received');
            final cachedProperties = await _loadFromCache();
            if (cachedProperties != null && cachedProperties.isNotEmpty) {
              return cachedProperties;
            }
            return mockPollProperties;
          }
          
          try {
            final dynamic decodedData = jsonDecode(responseBody);
            
            // Handle both array and object responses
            List<dynamic> data;
            if (decodedData is List) {
              data = decodedData;
            } else if (decodedData is Map && decodedData.containsKey('data')) {
              data = decodedData['data'] as List<dynamic>;
            } else if (decodedData is Map && decodedData.containsKey('poll_properties')) {
              data = decodedData['poll_properties'] as List<dynamic>;
            } else {
              print('Unexpected response format: ${decodedData.runtimeType}');
              print('Response sample: ${responseBody.substring(0, math.min(200, responseBody.length))}');
              
              // Try to fall back to cache
              final cachedProperties = await _loadFromCache();
              if (cachedProperties != null && cachedProperties.isNotEmpty) {
                return cachedProperties;
              }
              return mockPollProperties;
            }
            
            print('Successfully decoded JSON with ${data.length} poll properties');
            
            if (data.isEmpty) {
              print('No poll properties found in response');
              return mockPollProperties;
            }
            
            final properties = data.map((json) {
              try {
                return PollProperty.fromJson(json as Map<String, dynamic>);
              } catch (e) {
                print('Error parsing individual poll property: $e');
                return null;
              }
            }).where((property) => property != null).cast<PollProperty>().toList();
            
            print('Successfully parsed ${properties.length} poll properties');
            
            // Save to cache for offline use
            if (properties.isNotEmpty) {
              await _saveToCache(properties);
            }
            
            return properties;
          } catch (parseError) {
            print('JSON parsing error: $parseError');
            print('Response preview: ${responseBody.substring(0, math.min(500, responseBody.length))}');
            
            // Try to fall back to cache if parsing fails
            final cachedProperties = await _loadFromCache();
            if (cachedProperties != null && cachedProperties.isNotEmpty) {
              print('Using cached data due to parsing error');
              return cachedProperties;
            }
            
            lastException = Exception('Failed to parse poll properties data: $parseError');
            if (attempt == _MAX_RETRIES - 1) {
              throw lastException!;
            }
          }
        } else if (response.statusCode == 503 || response.statusCode == 502) {
          // Service unavailable or bad gateway - likely cold start
          print('Service temporarily unavailable (${response.statusCode}), retrying...');
          lastException = Exception('Service temporarily unavailable: ${response.statusCode}');
          
          if (attempt == _MAX_RETRIES - 1) {
            // On final attempt, return cached data if available
            final cachedProperties = await _loadFromCache();
            if (cachedProperties != null && cachedProperties.isNotEmpty) {
              print('Using cached data due to service unavailability');
              return cachedProperties;
            }
            return mockPollProperties;
          }
        } else {
          print('API request failed with status: ${response.statusCode}');
          print('Error response: ${response.body}');
          
          // Don't retry on client errors (400-499) except 408 (timeout)
          if (response.statusCode >= 400 && response.statusCode < 500 && response.statusCode != 408) {
            lastException = Exception('Client error: ${response.statusCode}');
            break;
          }
          
          lastException = Exception('Server error: ${response.statusCode}');
          
          // Continue retrying on server errors (500+) and timeouts
          if (attempt == _MAX_RETRIES - 1) {
            final cachedProperties = await _loadFromCache();
            if (cachedProperties != null && cachedProperties.isNotEmpty) {
              print('Using cached data due to server error');
              return cachedProperties;
            }
            return mockPollProperties;
          }
        }
      } catch (e) {
        print('Error on attempt ${attempt + 1}/$_MAX_RETRIES: $e');
        lastException = e is Exception ? e : Exception('Network error: $e');
        
        // If this is the last attempt, try cache before giving up
        if (attempt == _MAX_RETRIES - 1) {
          final cachedProperties = await _loadFromCache();
          if (cachedProperties != null && cachedProperties.isNotEmpty) {
            print('Using cached poll properties after all attempts failed');
            return cachedProperties;
          }
          
          // Return mock data as final fallback
          if (mockPollProperties.isNotEmpty) {
            print('Using mock data as final fallback');
            return mockPollProperties;
          }
        }
      }
    }
    
    // If we get here, all retries failed
    if (lastException != null) {
      throw lastException!;
    }
    
    throw Exception('Failed to fetch poll properties after all attempts');
  }

  // Helper to refresh data in background without blocking UI
  static void _refreshInBackground() {
    // Don't await this, let it run in background
    Timer(const Duration(seconds: 2), () async {
      try {
        print('Refreshing poll properties in background...');
        await getPollProperties(forceRefresh: true);
      } catch (e) {
        print('Background refresh failed: $e');
      }
    });
  }

  // Refresh all poll properties - force fresh data from database
  static Future<List<PollProperty>> refreshPollProperties() async {
    print('Force refreshing poll properties from database...');
    try {
      return await getPollProperties(forceRefresh: true);
    } catch (e) {
      print('Error refreshing poll properties: $e');
      
      // Fallback to cache on refresh failure
      final cachedProperties = await _loadFromCache();
      if (cachedProperties != null && cachedProperties.isNotEmpty) {
        return cachedProperties;
      }
      
      // Return mock data as last resort
      final mockProperties = _getMockPollProperties();
      if (mockProperties.isNotEmpty) {
        return mockProperties;
      }
      
      // If all else fails, return empty list instead of throwing
      return [];
    }
  }
  
  // Generate mock poll properties for development/demo when offline
  static List<PollProperty> _getMockPollProperties() {
    try {
      return [
        PollProperty(
          id: 'mock-1',
          title: 'Luxury Apartment in Lekki',
          location: 'Lekki, Lagos',
          imageUrl: 'assets/images/residential1.jpg',
          suggestions: [
            PollSuggestion(suggestion: 'Modern Design', votes: 12),
            PollSuggestion(suggestion: 'Open Floor Plan', votes: 8),
            PollSuggestion(suggestion: 'Large Windows', votes: 15),
          ],
        ),
        PollProperty(
          id: 'mock-2',
          title: 'Commercial Space in Victoria Island',
          location: 'Victoria Island, Lagos',
          imageUrl: 'assets/images/commercial1.jpg',
          suggestions: [
            PollSuggestion(suggestion: 'Office Partitions', votes: 7),
            PollSuggestion(suggestion: 'Reception Area', votes: 10),
            PollSuggestion(suggestion: 'Conference Rooms', votes: 6),
          ],
        ),
      ];
    } catch (e) {
      print('Error creating mock data: $e');
      return [];
    }
  }

  // Enhanced create poll property with better error handling
  static Future<String?> createPollProperty({
    required String title,
    required String location,
    required String imageUrl,
    required List<String> suggestions,
  }) async {
    try {
      print('Creating poll property...');
      
      // Check network connectivity first
      if (!await _hasNetworkConnection()) {
        print('No network connection for creating poll property');
        return null;
      }
      
      final requestBody = {
        'title': title,
        'location': location,
        'image_url': imageUrl,
        'suggestions': suggestions,
      };
      
      print('Request body: ${jsonEncode(requestBody)}');
      
      final response = await _getClient().post(
        Uri.parse('$_apiBaseUrl/poll_properties'),
        headers: _getHeaders(),
        body: jsonEncode(requestBody),
      ).timeout(
        const Duration(seconds: 45), // Longer timeout for creation
      );

      print('Create response status: ${response.statusCode}');
      print('Create response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return data['id']?.toString();
      } else {
        print('Failed to create poll property: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error creating poll property: $e');
      return null;
    }
  }

  // Enhanced vote with better error handling
  static Future<bool> voteForSuggestion({
    required String pollPropertyId,
    required String suggestion,
  }) async {
    try {
      // Check network connectivity first
      if (!await _hasNetworkConnection()) {
        print('No network connection for voting');
        return false;
      }
      
      final userId = await _getUserId();
      
      final requestBody = {
        'suggestion': suggestion,
        'user_id': userId,
      };
      
      print('Voting for suggestion: ${jsonEncode(requestBody)}');
      
      final response = await _getClient().post(
        Uri.parse('$_apiBaseUrl/poll_properties/$pollPropertyId/vote'),
        headers: _getHeaders(),
        body: jsonEncode(requestBody),
      ).timeout(
        const Duration(seconds: 30),
      );
      
      print('Vote response status: ${response.statusCode}');
      print('Vote response body: ${response.body}');
      
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print('Error voting for suggestion: $e');
      return false;
    }
  }

  // Get or generate a user ID for voting
  static Future<String> _getUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? userId = prefs.getString('poll_user_id');
      if (userId == null) {
        userId = 'user-${DateTime.now().millisecondsSinceEpoch}';
        await prefs.setString('poll_user_id', userId);
      }
      return userId;
    } catch (e) {
      return 'temp-${DateTime.now().millisecondsSinceEpoch}';
    }
  }
}
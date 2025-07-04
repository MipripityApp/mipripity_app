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
      print('Parsing poll property JSON: ${json.toString()}');
      
      // Primary parsing logic based on your database structure
      if (json['poll_suggestions'] != null) {
        // This matches your database structure
        final pollSuggestions = json['poll_suggestions'];
        final pollUserVotes = json['poll_user_votes'];
        
        List<String> suggestions = [];
        
        // Parse poll_suggestions (could be List or JSON string)
        if (pollSuggestions is List) {
          suggestions = pollSuggestions.map((s) => s.toString()).toList();
        } else if (pollSuggestions is String) {
          try {
            // Try to parse as JSON array
            final decoded = jsonDecode(pollSuggestions);
            if (decoded is List) {
              suggestions = decoded.map((s) => s.toString()).toList();
            } else {
              // If not a JSON array, treat as single suggestion
              suggestions = [pollSuggestions];
            }
          } catch (e) {
            print('Error parsing poll_suggestions JSON: $e');
            suggestions = [pollSuggestions];
          }
        }
        
        // Parse poll_user_votes to count votes per suggestion
        Map<String, int> voteCounts = {};
        if (pollUserVotes != null) {
          if (pollUserVotes is Map) {
            // Count votes for each suggestion
            for (String suggestion in suggestions) {
              voteCounts[suggestion] = 0;
            }
            
            // Count votes from poll_user_votes
            final votes = pollUserVotes as Map<String, dynamic>;
            for (var vote in votes.values) {
              final voteStr = vote.toString();
              if (voteCounts.containsKey(voteStr)) {
                voteCounts[voteStr] = voteCounts[voteStr]! + 1;
              }
            }
          } else if (pollUserVotes is String) {
            try {
              final decodedVotes = jsonDecode(pollUserVotes) as Map<String, dynamic>;
              // Initialize vote counts
              for (String suggestion in suggestions) {
                voteCounts[suggestion] = 0;
              }
              
              // Count votes
              for (var vote in decodedVotes.values) {
                final voteStr = vote.toString();
                if (voteCounts.containsKey(voteStr)) {
                  voteCounts[voteStr] = voteCounts[voteStr]! + 1;
                }
              }
            } catch (e) {
              print('Error parsing poll_user_votes JSON: $e');
              // Initialize with zero votes
              for (String suggestion in suggestions) {
                voteCounts[suggestion] = 0;
              }
            }
          }
        } else {
          // No votes data, initialize with zero votes
          for (String suggestion in suggestions) {
            voteCounts[suggestion] = 0;
          }
        }
        
        // Create PollSuggestion objects
        suggestionsList = suggestions.map((suggestion) {
          return PollSuggestion(
            suggestion: suggestion,
            votes: voteCounts[suggestion] ?? 0,
          );
        }).toList();
      } 
      // Fallback: Handle legacy 'suggestions' field format
      else if (json['suggestions'] is Map) {
        final suggestionsMap = json['suggestions'] as Map<String, dynamic>;
        suggestionsList = suggestionsMap.entries.map((entry) {
          return PollSuggestion(
            suggestion: entry.key,
            votes: entry.value is int ? entry.value : int.tryParse(entry.value.toString()) ?? 0,
          );
        }).toList();
      } else if (json['suggestions'] is List) {
        final suggestionsListData = json['suggestions'] as List;
        suggestionsList = suggestionsListData.map((suggestion) {
          if (suggestion is Map<String, dynamic>) {
            return PollSuggestion.fromJson(suggestion);
          } else {
            return PollSuggestion(suggestion: suggestion.toString(), votes: 0);
          }
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
      print('JSON data: ${json.toString()}');
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
  
  // HTTP client with persistent connection for better performance
  static final http.Client _httpClient = http.Client();
  
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

  // Simplified but reliable network connectivity check
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

  // Improved wake up method for Render.com service with better error handling
  static Future<bool> _wakeUpService() async {
    try {
      print('Attempting to wake up Render.com service...');
      
      // Start with a simple ping request to main endpoint
      final response = await _httpClient.get(
        Uri.parse('$_apiBaseUrl/poll_properties'),
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
  static Future<List<PollProperty>> _makeApiRequest() async {
    try {
      const url = '$_apiBaseUrl/poll_properties';
      print('Fetching poll properties from: $url');
      
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
          } else if (decodedData.containsKey('poll_properties')) {
            data = decodedData['poll_properties'] as List<dynamic>;
          } else if (decodedData.containsKey('properties')) {
            data = decodedData['properties'] as List<dynamic>;
          } else {
            // Single object response, wrap in array
            data = [decodedData];
          }
        } else {
          throw Exception('Unexpected response format: ${decodedData.runtimeType}');
        }
        
        print('Successfully decoded JSON with ${data.length} poll properties');
        
        if (data.isEmpty) {
          print('No poll properties found in response');
          return [];
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
        return properties;
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

  // Enhanced fetch with better error handling and cold start detection
  static Future<List<PollProperty>> getPollProperties({bool forceRefresh = false}) async {
    print('Getting poll properties (forceRefresh: $forceRefresh)');
    
    // Check if we should try to use cache first
    if (!forceRefresh) {
      final cachedProperties = await _loadFromCache();
      if (cachedProperties != null && cachedProperties.isNotEmpty) {
        print('Using cached poll properties (${cachedProperties.length} items)');
        
        // Attempt to refresh in background if we have cached data
        _refreshInBackground();
        
        return cachedProperties;
      }
    }
    
    // Check network connectivity
    final hasConnection = await _hasNetworkConnection();
    if (!hasConnection) {
      print('No network connection available, trying to load from cache');
      final cachedProperties = await _loadFromCache();
      if (cachedProperties != null && cachedProperties.isNotEmpty) {
        print('Using cached poll properties due to no network');
        return cachedProperties;
      }
      
      // Return mock data as last resort for no network
      final mockPollProperties = _getMockPollProperties();
      print('Using mock poll properties due to no network and no cache');
      return mockPollProperties;
    }
    
    // Try to wake up the service first (for Render.com cold starts)
    await _wakeUpService();
    
    // Implement retry logic with exponential backoff
    Exception? lastException;
    
    for (int attempt = 0; attempt < _MAX_RETRIES; attempt++) {
      try {
        if (attempt > 0) {
          print('Retry attempt $attempt/$_MAX_RETRIES for poll properties');
          // Exponential backoff: 2s, 4s, 8s
          final delaySeconds = math.pow(2, attempt).toInt();
          await Future.delayed(Duration(seconds: delaySeconds));
        }
        
        final properties = await _makeApiRequest();
        
        // Save to cache for offline use
        if (properties.isNotEmpty) {
          await _saveToCache(properties);
          print('Successfully fetched and cached ${properties.length} poll properties');
        }
        
        return properties;
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
    final cachedProperties = await _loadFromCache();
    if (cachedProperties != null && cachedProperties.isNotEmpty) {
      print('Using cached poll properties after API failure');
      return cachedProperties;
    }
    
    // No cached data available, use mock data as final fallback
    final mockPollProperties = _getMockPollProperties();
    print('Using mock data as final fallback after all attempts failed');
    return mockPollProperties;
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
      
      // Match your database structure
      final requestBody = {
        'title': title,
        'location': location,
        'image_url': imageUrl,
        'poll_suggestions': suggestions, // Changed from 'suggestions' to 'poll_suggestions'
      };
      
      print('Request body: ${jsonEncode(requestBody)}');
      
      final response = await _httpClient.post(
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

  // Enhanced vote with better error handling - updated to use new endpoint
  static Future<bool> voteForSuggestion({
    required String pollPropertyId, // Still keeping for backward compatibility
    required String suggestion,
  }) async {
    try {
      // Check network connectivity first
      if (!await _hasNetworkConnection()) {
        print('No network connection for voting');
        return false;
      }
      
      final userId = await _getUserId();
      
      // Updated request body for new vote endpoint
      final requestBody = {
        'user_id': userId,
        'suggestion': suggestion,
      };
      
      print('Voting for suggestion: ${jsonEncode(requestBody)}');
      
      // Using the new /poll_properties/vote endpoint
      final response = await _httpClient.post(
        Uri.parse('$_apiBaseUrl/poll_properties/vote'),
        headers: _getHeaders(),
        body: jsonEncode(requestBody),
      ).timeout(
        const Duration(seconds: 30),
      );
      
      print('Vote response status: ${response.statusCode}');
      print('Vote response body: ${response.body}');
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        // Clear cache to force refresh of updated data
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(_POLL_PROPERTIES_CACHE_KEY);
        return true;
      } else if (response.statusCode == 403) {
        // User has already voted
        print('User has already voted for this suggestion');
        return false;
      } else if (response.statusCode == 400) {
        // Bad request - invalid suggestion
        print('Invalid suggestion for voting');
        return false;
      }
      
      return false;
    } catch (e) {
      print('Error voting for suggestion: $e');
      return false;
    }
  }

  // Get or generate a user ID for voting - FIXED VERSION
  static Future<String> _getUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? userId = prefs.getString('poll_user_id');
      
      // If no user ID exists, generate one and save it
      if (userId == null || userId.isEmpty) {
        userId = 'user_${DateTime.now().millisecondsSinceEpoch}_${math.Random().nextInt(10000)}';
        await prefs.setString('poll_user_id', userId);
        print('Generated new user ID: $userId');
      }
      
      return userId; // Now guaranteed to be non-null
    } catch (e) {
      print('Error getting/generating user ID: $e');
      // Return a temporary ID if SharedPreferences fails
      return 'temp_${DateTime.now().millisecondsSinceEpoch}_${math.Random().nextInt(10000)}';
    }
  }
}
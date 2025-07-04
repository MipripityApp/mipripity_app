import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// Maximum number of retries for network requests
const int _MAX_RETRIES = 3;
// Cache key for storing poll properties locally
const String _HOME_POLL_PROPERTIES_CACHE_KEY = 'home_cached_poll_properties';
// Cache expiration time in minutes
const int _CACHE_EXPIRATION_MINUTES = 15;

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
            votes: entry.value is int ? entry.value : int.tryParse(entry.value?.toString() ?? '0') ?? 0,
          );
        }).toList();
      } else if (json['suggestions'] is List) {
        // Handle list format
        suggestionsList = (json['suggestions'] as List)
            .map((suggestion) {
              if (suggestion is Map<String, dynamic>) {
                return PollSuggestion.fromJson(suggestion);
              } else {
                return PollSuggestion(suggestion: suggestion?.toString() ?? '', votes: 0);
              }
            })
            .toList();
      } else if (json['poll_suggestions'] is List) {
        // Use poll_suggestions as fallback
        final pollSuggestions = json['poll_suggestions'] as List;
        final pollUserVotes = json['poll_user_votes'] as Map<String, dynamic>?;
        
        // Create suggestions list from poll_suggestions
        suggestionsList = pollSuggestions.map((suggestion) {
          final suggestionName = suggestion?.toString() ?? '';
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
        suggestions: suggestionsList,
      );
    } catch (e) {
      // Log the error but provide a valid object
      print('Error parsing PollProperty: $e');
      return PollProperty(
        id: json['id']?.toString() ?? '0',
        title: json['title']?.toString() ?? 'Untitled Poll Property',
        location: json['location']?.toString() ?? 'Unknown Location',
        imageUrl: json['image_url']?.toString() ?? '',
        suggestions: suggestionsList.isEmpty 
            ? [PollSuggestion(suggestion: 'No suggestions available', votes: 0)]
            : suggestionsList,
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

class HomePollPropertyApi {
  // Use only production URL as the project is in production stage
  static const String _apiBaseUrl = 'https://mipripity-api-1.onrender.com';
  
  // HTTP client with proper configuration
  static final http.Client _httpClient = http.Client();
  
  // Generate standard headers for API requests
  static Map<String, String> _getStandardHeaders() {
    return {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      'User-Agent': 'MipriyApp/1.0',
    };
  }

  // Check network connectivity using a simple DNS lookup
  static Future<bool> _hasNetworkConnection() async {
    try {
      // Try to resolve a well-known domain to check for internet connectivity
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 5));
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      print('Home API: Network connectivity check failed: No internet connection');
      return false;
    } on TimeoutException catch (_) {
      print('Home API: Network connectivity check timed out');
      return false;
    } catch (e) {
      print('Home API: Error checking network connectivity: $e');
      // Default to assuming connectivity is available if we can't check
      return true;
    }
  }
  
  // Save poll properties to local cache
  static Future<void> _saveToCache(List<PollProperty> properties) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Convert poll properties to JSON string
      final jsonData = jsonEncode({
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'data': properties.map((p) => p.toJson()).toList(),
      });
      
      // Save to SharedPreferences
      await prefs.setString(_HOME_POLL_PROPERTIES_CACHE_KEY, jsonData);
      print('Home API: Successfully saved ${properties.length} poll properties to cache');
    } catch (e) {
      print('Home API: Error saving poll properties to cache: $e');
    }
  }
  
  // Load poll properties from local cache
  static Future<List<PollProperty>?> _loadFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonData = prefs.getString(_HOME_POLL_PROPERTIES_CACHE_KEY);
      
      if (jsonData == null) {
        print('Home API: No cached poll properties found');
        return null;
      }
      
      final cacheData = jsonDecode(jsonData) as Map<String, dynamic>;
      final timestamp = cacheData['timestamp'] as int;
      final currentTime = DateTime.now().millisecondsSinceEpoch;
      
      // Check if cache is expired
      final cacheAgeMinutes = (currentTime - timestamp) / (1000 * 60);
      if (cacheAgeMinutes > _CACHE_EXPIRATION_MINUTES) {
        print('Home API: Cached poll properties expired (${cacheAgeMinutes.toStringAsFixed(1)} minutes old)');
        return null;
      }
      
      // Parse properties from cache
      final List<dynamic> data = cacheData['data'];
      final properties = data.map((json) => PollProperty.fromJson(json)).toList();
      print('Home API: Loaded ${properties.length} poll properties from cache (${cacheAgeMinutes.toStringAsFixed(1)} minutes old)');
      
      return properties;
    } catch (e) {
      print('Home API: Error loading poll properties from cache: $e');
      return null;
    }
  }

  // Make a single API request with proper error handling
  static Future<List<PollProperty>> _makeApiRequest() async {
    try {
      const url = '$_apiBaseUrl/poll_properties';
      print('Home API: Making request to: $url');
      
      final response = await _httpClient.get(
        Uri.parse(url),
        headers: _getStandardHeaders(),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw TimeoutException('Request timed out after 30 seconds');
        },
      );
      
      print('Home API: Response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final responseBody = response.body;
        print('Home API: Response body length: ${responseBody.length} bytes');
        
        if (responseBody.isEmpty) {
          throw Exception('Empty response body received');
        }
        
        try {
          final dynamic decodedData = jsonDecode(responseBody);
          
          // Handle both array and object responses
          List<dynamic> dataList;
          if (decodedData is List) {
            dataList = decodedData;
          } else if (decodedData is Map<String, dynamic>) {
            // If the response is wrapped in an object, look for common keys
            if (decodedData.containsKey('data')) {
              dataList = decodedData['data'] as List<dynamic>;
            } else if (decodedData.containsKey('poll_properties')) {
              dataList = decodedData['poll_properties'] as List<dynamic>;
            } else {
              // Single object response, wrap in array
              dataList = [decodedData];
            }
          } else {
            throw Exception('Unexpected response format: ${decodedData.runtimeType}');
          }
          
          print('Home API: Successfully parsed ${dataList.length} poll properties');
          
          if (dataList.isEmpty) {
            print('Home API: Warning - Empty poll properties list received');
            return [];
          }
          
          final properties = dataList.map((json) {
            try {
              return PollProperty.fromJson(json as Map<String, dynamic>);
            } catch (e) {
              print('Home API: Error parsing individual poll property: $e');
              // Return a default property to avoid breaking the entire list
              return PollProperty(
                id: json['id']?.toString() ?? '0',
                title: json['title']?.toString() ?? 'Parse Error',
                location: json['location']?.toString() ?? 'Unknown',
                imageUrl: json['image_url']?.toString() ?? '',
                suggestions: [PollSuggestion(suggestion: 'Data parsing error', votes: 0)],
              );
            }
          }).toList();
          
          return properties;
        } catch (jsonError) {
          print('Home API: JSON parsing error: $jsonError');
          print('Home API: Response preview: ${responseBody.substring(0, math.min(200, responseBody.length))}...');
          throw Exception('Failed to parse JSON response: $jsonError');
        }
      } else {
        final errorBody = response.body;
        print('Home API: HTTP error ${response.statusCode}: $errorBody');
        throw HttpException('HTTP ${response.statusCode}: $errorBody');
      }
    } catch (e) {
      print('Home API: Request error: $e');
      rethrow;
    }
  }

  // Fetch poll properties with retries and caching
  static Future<List<PollProperty>> getPollProperties({bool forceRefresh = false}) async {
    print('Home API: Getting poll properties (forceRefresh: $forceRefresh)');
    
    // Check if we should try to use cache first
    if (!forceRefresh) {
      final cachedProperties = await _loadFromCache();
      if (cachedProperties != null && cachedProperties.isNotEmpty) {
        print('Home API: Using cached poll properties (${cachedProperties.length} items)');
        return cachedProperties;
      }
    }
    
    // Check network connectivity
    final hasConnection = await _hasNetworkConnection();
    if (!hasConnection) {
      print('Home API: No network connection available, trying to load from cache');
      final cachedProperties = await _loadFromCache();
      if (cachedProperties != null && cachedProperties.isNotEmpty) {
        print('Home API: Using cached poll properties due to no network (${cachedProperties.length} items)');
        return cachedProperties;
      }
      throw Exception('No network connection and no cached data available');
    }
    
    // Try to fetch from API with retries
    Exception? lastException;
    
    for (int retryCount = 0; retryCount < _MAX_RETRIES; retryCount++) {
      try {
        if (retryCount > 0) {
          print('Home API: Retry attempt $retryCount/$_MAX_RETRIES');
          // Exponential backoff: 1s, 2s, 4s
          final delayMs = 1000 * math.pow(2, retryCount - 1).toInt();
          await Future.delayed(Duration(milliseconds: delayMs));
        }
        
        final properties = await _makeApiRequest();
        
        // Save to cache for future use
        if (properties.isNotEmpty) {
          await _saveToCache(properties);
        }
        
        print('Home API: Successfully fetched ${properties.length} poll properties');
        return properties;
        
      } catch (e) {
        lastException = e is Exception ? e : Exception(e.toString());
        print('Home API: Attempt ${retryCount + 1} failed: $e');
        
        // Don't retry on certain errors
        if (e is FormatException || e is HttpException && e.toString().contains('404')) {
          print('Home API: Non-retryable error encountered, stopping retries');
          break;
        }
      }
    }
    
    // All retries failed, try to use cached data as fallback
    print('Home API: All API attempts failed, trying cache as fallback');
    final cachedProperties = await _loadFromCache();
    if (cachedProperties != null && cachedProperties.isNotEmpty) {
      print('Home API: Using cached poll properties after API failure (${cachedProperties.length} items)');
      return cachedProperties;
    }
    
    // No cached data available, throw the last exception
    throw lastException ?? Exception('Failed to fetch poll properties after multiple attempts');
  }

  // Refresh all poll properties - force fresh data from database
  static Future<List<PollProperty>> refreshPollProperties() async {
    print('Home API: Force refreshing poll properties from database...');
    return await getPollProperties(forceRefresh: true);
  }
  
  // Clean up resources
  static void dispose() {
    _httpClient.close();
  }
}
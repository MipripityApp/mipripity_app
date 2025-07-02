import 'dart:convert';
import 'dart:math' as math;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class PollSuggestion {
  final String suggestion;
  int votes;

  PollSuggestion({
    required this.suggestion,
    required this.votes,
  });

  factory PollSuggestion.fromJson(Map<String, dynamic> json) {
    return PollSuggestion(
      suggestion: json['suggestion'],
      votes: json['votes'],
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
        // Handle older format if it exists
        suggestionsList = (json['suggestions'] as List)
            .map((suggestion) => suggestion is Map<String, dynamic> 
                ? PollSuggestion.fromJson(suggestion)
                : PollSuggestion(suggestion: suggestion.toString(), votes: 0))
            .toList();
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
      final propertyId = json['id'] is int 
          ? json['id'].toString() 
          : (json['id'] ?? '0').toString();
      
      return PollProperty(
        id: propertyId,
        title: json['title'] ?? 'Untitled Poll Property',
        location: json['location'] ?? 'Unknown Location',
        imageUrl: json['image_url'] ?? '',
        suggestions: suggestionsList,
      );
    } catch (e) {
      // Log the error but provide a valid object
      print('Error parsing PollProperty: $e for data: ${json.toString().substring(0, 100)}...');
      return PollProperty(
        id: (json['id'] ?? '0').toString(),
        title: json['title'] ?? 'Untitled Poll Property',
        location: json['location'] ?? 'Unknown Location',
        imageUrl: json['image_url'] ?? '',
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

class PollPropertyApi {
  // Use only production URL as the project is in production stage
  static const String _apiBaseUrl = 'https://mipripity-api-1.onrender.com';
  
  // Production mode - no sample data methods needed

  // Fetch all poll properties with improved logging
  static Future<List<PollProperty>> getPollProperties() async {
    try {
      print('Fetching poll properties from $_apiBaseUrl/poll_properties');
      
      final response = await http.get(
        Uri.parse('$_apiBaseUrl/poll_properties'),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw Exception('Request timed out'),
      );

      print('API response status code: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        // Log response for debugging
        final responseBody = response.body;
        print('Received API response length: ${responseBody.length} bytes');
        
        try {
          final List<dynamic> data = jsonDecode(responseBody);
          print('Successfully decoded JSON with ${data.length} poll properties');
          
          final properties = data.map((json) => PollProperty.fromJson(json)).toList();
          print('Successfully parsed ${properties.length} poll properties');
          
          return properties;
        } catch (parseError) {
          print('JSON parsing error: $parseError');
          print('Response body: ${responseBody.substring(0, math.min(300, responseBody.length))}...');
          return [];
        }
      } else {
        print('API request failed with status: ${response.statusCode}');
        print('Response body: ${response.body}');
        return []; // Return empty list instead of sample data
      }
    } catch (e) {
      print('Error fetching poll properties: $e');
      return []; // Return empty list instead of sample data
    }
  }

  // Create a new poll property
  static Future<String?> createPollProperty({
    required String title,
    required String location,
    required String imageUrl,
    required List<String> suggestions,
  }) async {
    try {
      print('Creating poll property at $_apiBaseUrl/poll_properties');
      
      // Prepare suggestions data in the format expected by the backend
      final suggestionsList = suggestions.map((suggestion) => {
        'suggestion': suggestion,
        'votes': 0
      }).toList();
      
      final response = await http.post(
        Uri.parse('$_apiBaseUrl/poll_properties'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'title': title,
          'location': location,
          'image_url': imageUrl,
          'suggestions': suggestionsList,
        }),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw Exception('Request timed out'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['id'] as String?;
      } else {
        throw Exception('Failed to create poll property: ${response.statusCode}');
      }
    } catch (e) {
      print('Error creating poll property: $e');
      return null;
    }
  }

  // Vote for a suggestion
  static Future<bool> voteForSuggestion({
    required String pollPropertyId,
    required String suggestion,
  }) async {
    try {
      // Get user ID from shared preferences or generate a temporary one
      final userId = await _getUserId();
      
      print('Voting for poll property at $_apiBaseUrl/poll_properties/$pollPropertyId/vote');
      print('Voting data: suggestion=$suggestion, user_id=$userId');
      
      final response = await http.post(
        Uri.parse('$_apiBaseUrl/poll_properties/$pollPropertyId/vote'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'suggestion': suggestion,
          'user_id': userId,
        }),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw Exception('Request timed out'),
      );
      
      print('Vote response status: ${response.statusCode}');
      print('Vote response body: ${response.body}');

      if (response.statusCode == 200) {
        return true;
      } else {
        throw Exception('Failed to vote for suggestion: ${response.statusCode}');
      }
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
        // Generate a new user ID if none exists
        userId = 'user-${DateTime.now().millisecondsSinceEpoch}';
        await prefs.setString('poll_user_id', userId);
      }

      return userId;
    } catch (e) {
      // Fallback to a temporary ID if storage fails
      return 'temp-${DateTime.now().millisecondsSinceEpoch}';
    }
  }
}
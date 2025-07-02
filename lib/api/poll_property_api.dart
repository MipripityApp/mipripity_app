import 'dart:convert';
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
    final suggestionsList = (json['suggestions'] as List)
        .map((suggestion) => PollSuggestion.fromJson(suggestion))
        .toList();

    return PollProperty(
      id: json['id'],
      title: json['title'],
      location: json['location'],
      imageUrl: json['image_url'] ?? '',
      suggestions: suggestionsList,
    );
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
  
  // Get sample poll properties for demo/testing
  static Future<List<PollProperty>> _getSamplePollProperties() {
    // Create sample poll properties for testing
    return Future.value([
      PollProperty(
        id: 'sample-poll-1',
        title: 'Uncompleted Duplex',
        location: 'Ikeja, Lagos',
        imageUrl: 'assets/images/residential1.jpg',
        suggestions: [
          PollSuggestion(suggestion: 'Mini Mall', votes: 8),
          PollSuggestion(suggestion: 'Shortlet Apartment', votes: 12),
          PollSuggestion(suggestion: 'Open Event Space', votes: 5),
          PollSuggestion(suggestion: 'Private School', votes: 3),
        ],
      ),
      PollProperty(
        id: 'sample-poll-2',
        title: 'Corner Piece Land',
        location: 'Lekki, Lagos',
        imageUrl: 'assets/images/land1.jpeg',
        suggestions: [
          PollSuggestion(suggestion: 'Shopping Complex', votes: 15),
          PollSuggestion(suggestion: 'Residential Estate', votes: 9),
          PollSuggestion(suggestion: 'Hotel', votes: 7),
          PollSuggestion(suggestion: 'Office Space', votes: 4),
        ],
      ),
    ]);
  }

  // Fetch all poll properties
  static Future<List<PollProperty>> getPollProperties() async {
    try {
      print('Fetching poll properties from $_apiBaseUrl/poll_properties');
      
      final response = await http.get(
        Uri.parse('$_apiBaseUrl/poll_properties'),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw Exception('Request timed out'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        if (data.isNotEmpty) {
          return data.map((json) => PollProperty.fromJson(json)).toList();
        }
      }
      
      // If API fails or returns empty data, return sample data
      print('Using sample poll properties data');
      return _getSamplePollProperties();
    } catch (e) {
      print('Error fetching poll properties: $e');
      // Return sample data if error occurs
      return _getSamplePollProperties();
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
        // Generate a unique ID using timestamp + random
        userId = '${DateTime.now().millisecondsSinceEpoch}-${(1000 + (DateTime.now().microsecond % 9000)).toString()}';
        await prefs.setString('poll_user_id', userId);
      }

      return userId;
    } catch (e) {
      // Fallback to a temporary ID if storage fails
      return 'temp-${DateTime.now().millisecondsSinceEpoch}';
    }
  }
}
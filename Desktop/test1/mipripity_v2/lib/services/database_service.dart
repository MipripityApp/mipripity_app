import 'dart:convert';
import 'package:http/http.dart' as http;
import '../api/property_api.dart';


class DatabaseService {
  static const String baseUrl = 'https://mipripity-api-1.onrender.com';
  
  // Submit complete form data
  Future<bool> submitCompleteListing({
    required Map<String, dynamic> formData,
    required int userId,
  }) async {
    try {
      // Validate required fields
      if (formData['title'] == null || formData['title'].toString().trim().isEmpty) {
        print('Title is required');
        return false;
      }
      
      if (formData['description'] == null || formData['description'].toString().trim().isEmpty) {
        print('Description is required');
        return false;
      }
      
      if (formData['price'] == null || formData['price'].toString().trim().isEmpty) {
        print('Price is required');
        return false;
      }
      
      if (formData['location'] == null || formData['location'].toString().trim().isEmpty) {
        print('Location is required');
        return false;
      }
      
      // Parse location to extract city, state, country
      final locationParts = formData['location'].toString().split(',');
      String city = '';
      String state = '';
      String country = 'Nigeria'; // Default
      
      if (locationParts.isNotEmpty) city = locationParts[0].trim();
      if (locationParts.length >= 2) state = locationParts[1].trim();
      if (locationParts.length >= 3) country = locationParts[2].trim();
      
      // Format data to match database schema
      final propertyData = {
        'title': formData['title'],
        'description': formData['description'],
        'price': formData['price'],
        'quantity': formData['quantity'] ?? 1,
        'category': formData['category'] ?? '',
        'type': formData['type'] ?? 'residential',
        'condition': formData['condition'] ?? 'New',
        'year_built': formData['year_built'] ?? DateTime.now().year.toString(),
        'area': formData['area'] ?? '',
        'land_size': formData['landSize'] ?? formData['land_size'] ?? '',
        'land_title': formData['landTitle'] ?? formData['land_title'] ?? '',
        'bedrooms': formData['bedrooms'] ?? 0,
        'bathrooms': formData['bathrooms'] ?? 0,
        'toilets': formData['toilets'] ?? 0,
        'parking_spaces': formData['parkingSpaces'] ?? formData['parking_spaces'] ?? 0,
        'has_internet': formData['hasInternet'] ?? formData['has_internet'] ?? false,
        'has_electricity': formData['hasElectricity'] ?? formData['has_electricity'] ?? false,
        'is_verified': false,
        'is_active': true,
        'status': formData['status'] ?? 'Available',
        'urgency_period': formData['isUrgent'] == true ? (formData['urgencyData']?['deadline'] ?? '') : '',
        'views': 0,
        'location': formData['location'],
        'city': city,
        'state': state,
        'country': country,
        'latitude': formData['latitude'] ?? 0,
        'longitude': formData['longitude'] ?? 0,
        'images': formData['images'] ?? [],
        'lister_name': formData['listerName'] ?? '',
        'lister_email': formData['listerEmail'] ?? '',
        'lister_whatsapp': formData['whatsappNumber'] ?? '',
        'lister_dp': formData['listerDp'] ?? '',
        'user_id': userId,
      };
      
      // Submit form data to backend API
      final response = await http.post(
        Uri.parse('$baseUrl/properties'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(propertyData),
      );
      
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print('Exception submitting complete listing: $e');
      return false;
    }
  }
  
  // Get category ID by name
  Future<int?> getCategoryIdByName(String categoryName) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/categories?name=$categoryName'),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List && data.isNotEmpty) {
          return data.first['id'];
        }
      }
      return 1; // Default fallback
    } catch (e) {
      print('Error getting category ID: $e');
      return 1;
    }
  }
  
  // Get user's listings
  Future<List<Map<String, dynamic>>> getUserListings(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/users/$userId/listings'),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data);
      }
      return [];
    } catch (e) {
      print('Error getting user listings: $e');
      return [];
    }
  }
  
  // Get listing details
  Future<Map<String, dynamic>?> getListingDetails(int listingId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/listings/$listingId'),
      );
      
      if (response.statusCode == 200) {
        return Map<String, dynamic>.from(jsonDecode(response.body));
      }
      return null;
    } catch (e) {
      print('Error getting listing details: $e');
      return null;
    }
  }
  
  // Update listing status
  Future<bool> updateListingStatus(int listingId, String status) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/listings/$listingId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'status': status}),
      );
      
      return response.statusCode == 200;
    } catch (e) {
      print('Error updating listing status: $e');
      return false;
    }
  }
  
  // Delete listing
  Future<bool> deleteListing(int listingId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/listings/$listingId'),
      );
      
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      print('Error deleting listing: $e');
      return false;
    }
  }
  
  // Get residential properties for listing
  Future<List<Map<String, dynamic>>> getResidentialProperties() async {
    try {
      final properties = await PropertyApi.getResidentialProperties();
      return List<Map<String, dynamic>>.from(properties);
    } catch (e) {
      print('Error getting residential properties: $e');
      return [];
    }
  }
  
  // Get commercial properties for listing
  Future<List<Map<String, dynamic>>> getCommercialProperties() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/properties/commercial'),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data);
      }
      return [];
    } catch (e) {
      print('Error getting commercial properties: $e');
      return [];
    }
  }

  // Get land properties
  Future<List<Map<String, dynamic>>> getLandProperties() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/properties/land'),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data);
      }
      return [];
    } catch (e) {
      print('Error getting land properties: $e');
      return [];
    }
  }

  // Get material properties
  Future<List<Map<String, dynamic>>> getMaterialProperties() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/properties/materials'),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data);
      }
      return [];
    } catch (e) {
      print('Error getting material properties: $e');
      return [];
    }
  }
  
  // Helper methods to extract city and state from location
  String _extractCity(String location) {
    final parts = location.split(',');
    return parts.isNotEmpty ? parts.first.trim() : location;
  }

  String _extractState(String location) {
    final parts = location.split(',');
    return parts.length > 1 ? parts.last.trim() : '';
  }
  
  // NOTE: Authentication is now handled by Supabase
  // The custom authentication endpoints have been removed

  // Get or create default user
  Future<int> getOrCreateDefaultUser() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/users/default'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['id'] ?? 1;
      }
      
      // If no default user exists, create one
      final createResponse = await http.post(
        Uri.parse('$baseUrl/users/default'),
        headers: {'Content-Type': 'application/json'},
      );

      if (createResponse.statusCode == 200 || createResponse.statusCode == 201) {
        final data = jsonDecode(createResponse.body);
        return data['id'] ?? 1;
      }
      
      return 1; // Fallback
    } catch (e) {
      print('Error getting/creating default user: $e');
      return 1;
    }
  }

  // Add property creation methods
  Future<bool> createResidentialProperty({
    required Map<String, dynamic> propertyData,
    required int userId,
  }) async {
    try {
      propertyData['user_id'] = userId;
      propertyData['type'] = 'residential';
      return await PropertyApi.createResidentialProperty(propertyData);
    } catch (e) {
      print('Error creating residential property: $e');
      return false;
    }
  }

  Future<bool> createCommercialProperty({
    required Map<String, dynamic> propertyData,
    required int userId,
  }) async {
    try {
      propertyData['user_id'] = userId;
      propertyData['type'] = 'commercial';
      
      final response = await http.post(
        Uri.parse('$baseUrl/properties'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(propertyData),
      );
      
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print('Error creating commercial property: $e');
      return false;
    }
  }

  Future<bool> createLandProperty({
    required Map<String, dynamic> propertyData,
    required int userId,
  }) async {
    try {
      propertyData['user_id'] = userId;
      propertyData['type'] = 'land';
      
      final response = await http.post(
        Uri.parse('$baseUrl/properties'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(propertyData),
      );
      
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print('Error creating land property: $e');
      return false;
    }
  }

  Future<bool> createMaterialProperty({
    required Map<String, dynamic> propertyData,
    required int userId,
  }) async {
    try {
      propertyData['user_id'] = userId;
      propertyData['type'] = 'material';
      
      final response = await http.post(
        Uri.parse('$baseUrl/properties'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(propertyData),
      );
      
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print('Error creating material property: $e');
      return false;
    }
  }

  // Get featured properties by category
  Future<List<Map<String, dynamic>>> getFeaturedPropertiesByCategory(String category, {required int limit}) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/properties/featured?category=$category&limit=$limit'),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data);
      }
      
      // If no featured properties, get recent properties
      final recentResponse = await http.get(
        Uri.parse('$baseUrl/properties/recent?category=$category&limit=$limit'),
      );
      
      if (recentResponse.statusCode == 200) {
        final data = jsonDecode(recentResponse.body);
        return List<Map<String, dynamic>>.from(data);
      }
      
      return [];
    } catch (e) {
      print('Error getting featured properties for $category: $e');
      return [];
    }
  }

  // Get all featured properties
  Future<List<Map<String, dynamic>>> getAllProperties({int limit = 20}) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/properties'),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data);
      }
      return [];
    } catch (e) {
      print('Error getting all properties: $e');
      return [];
    }
  }

  // Additional utility methods for API calls
  Future<Map<String, String>> _getAuthHeaders([String? token]) async {
    final headers = {'Content-Type': 'application/json'};
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  // Handle API errors
  void _handleApiError(http.Response response, String operation) {
    print('API Error during $operation:');
    print('Status Code: ${response.statusCode}');
    print('Response Body: ${response.body}');
  }
}
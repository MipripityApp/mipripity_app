import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../api/property_api.dart';

class DatabaseService {
  static const String baseUrl = 'https://mipripity-api-1.onrender.com';
  static const int apiTimeoutSeconds = 15; // Increased timeout for poor connectivity
  
  // Storage keys for local data
  static const String pendingListingsKey = 'pending_listings';
  static const String submittedListingsKey = 'submitted_listings';
  
  // Submit complete form data with enhanced error handling and local storage
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
      
      // Add timestamp for tracking
      formData['submittedAt'] = DateTime.now().toIso8601String();
      
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
        'submittedAt': DateTime.now().toIso8601String(),
      };
      
      // Try online submission first
      try {
        // Set a timeout for the API request
        final response = await http.post(
          Uri.parse('$baseUrl/properties'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(propertyData),
        ).timeout(const Duration(seconds: apiTimeoutSeconds));
        
        if (response.statusCode == 200 || response.statusCode == 201) {
          // Successfully submitted, save to local submitted listings
          await _saveToSubmittedListings(propertyData);
          return true;
        } else {
          // API returned error, fall back to local storage
          print('API returned error: ${response.statusCode}, saving locally for later sync');
          await _saveToPendingListings(propertyData);
          return true; // Still return true since we saved locally
        }
      } on TimeoutException {
        // Request timed out, save locally
        print('API request timed out, saving locally for later sync');
        await _saveToPendingListings(propertyData);
        return true; // Return true since we saved locally
      } on http.ClientException {
        // Network error, save locally
        print('Network error, saving locally for later sync');
        await _saveToPendingListings(propertyData);
        return true; // Return true since we saved locally
      } catch (e) {
        // Other error, try local storage
        print('Exception during API submission: $e, saving locally');
        await _saveToPendingListings(propertyData);
        return true; // Return true since we saved locally
      }
    } catch (e) {
      print('Exception in submitCompleteListing: $e');
      
      // Even if we encounter an error, try to save locally as last resort
      try {
        await _saveToPendingListings(formData);
        return true;
      } catch (localSaveError) {
        print('Failed to save locally: $localSaveError');
        return false;
      }
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
  // Save listing to pending queue for later sync
  Future<bool> _saveToPendingListings(Map<String, dynamic> propertyData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Get existing pending listings
      List<String> pendingListings = prefs.getStringList(pendingListingsKey) ?? [];
      
      // Add new listing
      pendingListings.add(jsonEncode(propertyData));
      
      // Save updated list
      await prefs.setStringList(pendingListingsKey, pendingListings);
      
      print('Saved listing to pending queue (${pendingListings.length} total pending)');
      return true;
    } catch (e) {
      print('Error saving to pending listings: $e');
      return false;
    }
  }
  
  // Save listing to submitted history
  Future<bool> _saveToSubmittedListings(Map<String, dynamic> propertyData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Get existing submitted listings
      List<String> submittedListings = prefs.getStringList(submittedListingsKey) ?? [];
      
      // Add new listing (with timestamp)
      propertyData['submittedAt'] = DateTime.now().toIso8601String();
      submittedListings.add(jsonEncode(propertyData));
      
      // Keep only the last 50 submissions to avoid storage issues
      if (submittedListings.length > 50) {
        submittedListings = submittedListings.sublist(submittedListings.length - 50);
      }
      
      // Save updated list
      await prefs.setStringList(submittedListingsKey, submittedListings);
      
      return true;
    } catch (e) {
      print('Error saving to submitted listings: $e');
      return false;
    }
  }
  
  // Sync pending listings with the server (can be called when connectivity is restored)
  Future<int> syncPendingListings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Get pending listings
      List<String> pendingListings = prefs.getStringList(pendingListingsKey) ?? [];
      
      if (pendingListings.isEmpty) {
        return 0; // No pending listings to sync
      }
      
      int successCount = 0;
      List<String> remainingListings = [];
      
      // Try to submit each pending listing
      for (String listingJson in pendingListings) {
        try {
          final listingData = jsonDecode(listingJson) as Map<String, dynamic>;
          
          // Try to submit to API
          final response = await http.post(
            Uri.parse('$baseUrl/properties'),
            headers: {'Content-Type': 'application/json'},
            body: listingJson,
          ).timeout(const Duration(seconds: apiTimeoutSeconds));
          
          if (response.statusCode == 200 || response.statusCode == 201) {
            // Successfully synced
            successCount++;
            await _saveToSubmittedListings(listingData);
          } else {
            // Failed to sync this listing
            remainingListings.add(listingJson);
          }
        } catch (e) {
          // Error syncing this listing, keep it in the queue
          remainingListings.add(listingJson);
          print('Error syncing listing: $e');
        }
      }
      
      // Update pending listings with remaining ones
      await prefs.setStringList(pendingListingsKey, remainingListings);
      
      print('Synced $successCount/${pendingListings.length} pending listings');
      return successCount;
    } catch (e) {
      print('Error syncing pending listings: $e');
      return 0;
    }
  }
  
  // Get count of pending listings
  Future<int> getPendingListingsCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final pendingListings = prefs.getStringList(pendingListingsKey) ?? [];
      return pendingListings.length;
    } catch (e) {
      print('Error getting pending listings count: $e');
      return 0;
    }
  }
  // Get land properties
  Future<List<Map<String, dynamic>>> getLandProperties() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/properties/land'),
      ).timeout(const Duration(seconds: apiTimeoutSeconds));
      
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
      ).timeout(const Duration(seconds: apiTimeoutSeconds));
      
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
      ).timeout(const Duration(seconds: apiTimeoutSeconds));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['id'] ?? 1;
      }
      
      // If no default user exists, create one
      final createResponse = await http.post(
        Uri.parse('$baseUrl/users/default'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: apiTimeoutSeconds));

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
      ).timeout(const Duration(seconds: apiTimeoutSeconds));
      
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
      ).timeout(const Duration(seconds: apiTimeoutSeconds));
      
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
      ).timeout(const Duration(seconds: apiTimeoutSeconds));
      
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
      ).timeout(const Duration(seconds: apiTimeoutSeconds));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data);
      }
      
      // If no featured properties, get recent properties
      final recentResponse = await http.get(
        Uri.parse('$baseUrl/properties/recent?category=$category&limit=$limit'),
      ).timeout(const Duration(seconds: apiTimeoutSeconds));
      
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
      ).timeout(const Duration(seconds: apiTimeoutSeconds));
      
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
  // Utility method to check the network connectivity
  Future<bool> isNetworkAvailable() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/ping'),
      ).timeout(const Duration(seconds: 5));
      
      return response.statusCode == 200;
    } catch (e) {
      print('Network connectivity check failed: $e');
      return false;
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

  // Get residential properties by filter - with offline fallback
  Future<List<Map<String, dynamic>>> getResidentialPropertiesByFilter({
    String? status,
    String? category,
    double? minPrice,
    double? maxPrice,
    String? searchQuery,
  }) async {
    try {
      // Try API first
      try {
        final properties = await PropertyApi.getResidentialPropertiesWithFilter(
          status: status,
          category: category,
          minPrice: minPrice,
          maxPrice: maxPrice,
          searchQuery: searchQuery,
        );
        return properties;
      } catch (e) {
        print('API filter failed, using local data: $e');
        
        // Fall back to local data from SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        final submittedListings = prefs.getStringList(submittedListingsKey) ?? [];
        final pendingListings = prefs.getStringList(pendingListingsKey) ?? [];
        
        // Combine and convert all listings
        final allListings = [...submittedListings, ...pendingListings]
          .map((json) => jsonDecode(json) as Map<String, dynamic>)
          .where((p) => p['type'] == 'residential')
          .toList();
        
        // Apply filters manually
        return allListings.where((property) {
          bool matches = true;
          
          if (status != null && status != 'all') {
            matches = matches && property['status'] == status;
          }
          
          if (category != null && category != 'all') {
            matches = matches && property['category'] == category;
          }
          
          if (minPrice != null) {
            final propertyPrice = property['price'] is double 
                ? property['price'] 
                : double.tryParse(property['price']?.toString() ?? '0') ?? 0;
            matches = matches && propertyPrice >= minPrice;
          }
          
          if (maxPrice != null) {
            final propertyPrice = property['price'] is double 
                ? property['price'] 
                : double.tryParse(property['price']?.toString() ?? '0') ?? 0;
            matches = matches && propertyPrice <= maxPrice;
          }
          
          if (searchQuery != null && searchQuery.isNotEmpty) {
            final title = property['title']?.toString().toLowerCase() ?? '';
            final location = property['location']?.toString().toLowerCase() ?? '';
            final query = searchQuery.toLowerCase();
            matches = matches && (title.contains(query) || location.contains(query));
          }
          
          return matches;
        }).toList();
      }
    } catch (e) {
      print('Error in getResidentialPropertiesByFilter: $e');
      return [];
    }
  }

  // Similar methods for other property types...
  Future<List<Map<String, dynamic>>> getCommercialPropertiesByFilter({
    String? status,
    String? propertyType,
    double? minPrice,
    double? maxPrice,
    String? searchQuery,
  }) async {
    // Implementation similar to getResidentialPropertiesByFilter but for commercial properties
    try {
      // Use local fallback if needed
      final prefs = await SharedPreferences.getInstance();
      final allListings = prefs.getStringList(submittedListingsKey) ?? [];
      
      return allListings
        .map((json) => jsonDecode(json) as Map<String, dynamic>)
        .where((p) => p['type'] == 'commercial')
        .toList();
    } catch (e) {
      print('Error in getCommercialPropertiesByFilter: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getLandPropertiesByFilter({
    String? landType,
    String? searchQuery,
  }) async {
    // Implementation similar to getResidentialPropertiesByFilter but for land properties
    try {
      // Use local fallback if needed
      final prefs = await SharedPreferences.getInstance();
      final allListings = prefs.getStringList(submittedListingsKey) ?? [];
      
      return allListings
        .map((json) => jsonDecode(json) as Map<String, dynamic>)
        .where((p) => p['type'] == 'land')
        .toList();
    } catch (e) {
      print('Error in getLandPropertiesByFilter: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getMaterialPropertiesByFilter({
    String? materialType,
    String? condition,
    String? searchQuery,
  }) async {
    // Implementation similar to getResidentialPropertiesByFilter but for material properties
    try {
      // Use local fallback if needed
      final prefs = await SharedPreferences.getInstance();
      final allListings = prefs.getStringList(submittedListingsKey) ?? [];
      
      return allListings
        .map((json) => jsonDecode(json) as Map<String, dynamic>)
        .where((p) => p['type'] == 'material')
        .toList();
    } catch (e) {
      print('Error in getMaterialPropertiesByFilter: $e');
      return [];
    }
  }
  // Handle API errors
  void _handleApiError(http.Response response, String operation) {
    print('API Error during $operation:');
    print('Status Code: ${response.statusCode}');
    print('Response Body: ${response.body}');
  }
}
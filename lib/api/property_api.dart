import 'dart:convert';
import 'package:http/http.dart' as http;
import '../database_helper.dart';

class PropertyApi {
  static const String baseUrl = 'https://mipripity-api-1.onrender.com';
  static final DatabaseHelper _dbHelper = DatabaseHelper();

  // Fetch residential properties from the PostgreSQL database
  static Future<List<Map<String, dynamic>>> getResidentialProperties() async {
    try {
      return await _dbHelper.getResidentialProperties();
    } catch (e) {
      print('Error fetching residential properties from database: $e');
      // Fallback to API if database fails
      return _fetchResidentialPropertiesFromApi();
    }
  }

  // Fetch properties by category (residential, commercial, land, material, etc.)
  static Future<List<Map<String, dynamic>>> getPropertiesByCategory(String category) async {
    try {
      // First try to fetch from API
      return await _fetchPropertiesByCategoryFromApi(category);
    } catch (e) {
      print('Error fetching $category properties from API: $e');
      // Fallback to database if API fails
      try {
        switch (category) {
          case 'residential':
            return await _dbHelper.getResidentialProperties();
          case 'commercial':
            return await _dbHelper.getCommercialProperties();
          case 'land':
            return await _dbHelper.getLandProperties();
          case 'material':
            return await _dbHelper.getMaterialProperties();
          default:
            throw Exception('Unknown property category: $category');
        }
      } catch (dbError) {
        print('Error fetching $category properties from database: $dbError');
        // If both API and database fail, rethrow the API error
        throw e;
      }
    }
  }

  // Private fallback methods to fetch from API
  static Future<List<Map<String, dynamic>>> _fetchResidentialPropertiesFromApi() async {
    final response = await http.get(Uri.parse('$baseUrl/properties/residential'));
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    } else {
      throw Exception('Failed to fetch residential properties from API');
    }
  }

  static Future<List<Map<String, dynamic>>> _fetchPropertiesByCategoryFromApi(String category) async {
    final response = await http.get(Uri.parse('$baseUrl/properties/$category'));
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    } else {
      throw Exception('Failed to fetch $category properties from API');
    }
  }

  // Create a new residential property
  static Future<bool> createResidentialProperty(Map<String, dynamic> propertyData) async {
    final response = await http.post(
      Uri.parse('$baseUrl/properties'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(propertyData),
    );
    return response.statusCode == 200;
  }
  
  // Post any type of property to the backend with improved error handling and timeouts
  static Future<bool> postProperty(Map<String, dynamic> propertyData) async {
    try {
      // Set a timeout for the request to prevent hanging
      final response = await http.post(
        Uri.parse('$baseUrl/properties'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(propertyData),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          // Return a fake response object on timeout
          print('API request timed out. Treating as offline.');
          throw Exception('API request timed out');
        },
      );
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        // Try to parse the response to get the property ID
        try {
          final responseData = jsonDecode(response.body);
          print('Property posted successfully: ${responseData['id'] ?? 'No ID returned'}');
        } catch (e) {
          print('Property posted successfully but could not parse response: $e');
        }
        return true;
      } else {
        print('Failed to post property. Status code: ${response.statusCode}, Response: ${response.body}');
        return false;
      }
    } on http.ClientException catch (e) {
      // This happens when there's a network connectivity issue
      print('Network connection error posting property: $e');
      // Don't throw, just return false to allow fallbacks
      return false;
    } catch (e) {
      print('Exception posting property: $e');
      return false;
    }
  }
  // Fetch property details by ID
  static Future<Map<String, dynamic>> getPropertyDetails(String propertyId) async {
  final response = await http.get(Uri.parse('$baseUrl/properties/$propertyId'));
  if (response.statusCode == 200) {
    return jsonDecode(response.body);
  } else {
    throw Exception('Failed to fetch property details');
  }
}
  // Update an existing property
  static Future<bool> updateProperty(int id, Map<String, dynamic> propertyData) async {
    final response = await http.put(
      Uri.parse('$baseUrl/properties/$id'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(propertyData),
    );
    return response.statusCode == 200;
  }
  // Delete a property
  static Future<bool> deleteProperty(int id) async {
    final response = await http.delete(Uri.parse('$baseUrl/properties/$id'));
    return response.statusCode == 200;
  }
  // Fetch all properties
  static Future<List<Map<String, dynamic>>> getAllProperties() async {
    final response = await http.get(Uri.parse('$baseUrl/properties'));
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    } else {
      throw Exception('Failed to fetch all properties');
    }
  }
  // Fetch properties by type (residential, commercial, land, etc.)
  static Future<List<Map<String, dynamic>>> getPropertiesByType(String type) async {
    final response = await http.get(Uri.parse('$baseUrl/properties/$type'));
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    } else {
      throw Exception('Failed to fetch properties of type $type');
    }
  }

  // Get residential properties with filtering
  static Future<List<Map<String, dynamic>>> getResidentialPropertiesWithFilter({
    String? status,
    String? category,
    double? minPrice,
    double? maxPrice,
    String? searchQuery,
  }) async {
    try {
      // Try API first - using general endpoint and filtering in memory
      final allProperties = await _fetchPropertiesByCategoryFromApi('residential');
      
      // Apply filters to the fetched data
      return allProperties.where((property) {
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
    } catch (e) {
      print('Error filtering residential properties from API: $e');
      // Fallback to database if API fails
      try {
        return await _dbHelper.getResidentialPropertiesByFilter(
          status: status,
          category: category,
          minPrice: minPrice,
          maxPrice: maxPrice,
          searchQuery: searchQuery,
        );
      } catch (dbError) {
        print('Error filtering residential properties from database: $dbError');
        throw e;
      }
    }
  }

  // Get commercial properties with filtering
  static Future<List<Map<String, dynamic>>> getCommercialPropertiesWithFilter({
    String? status,
    String? propertyType,
    double? minPrice,
    double? maxPrice,
    String? searchQuery,
  }) async {
    try {
      // Try API first - using general endpoint and filtering in memory
      final allProperties = await _fetchPropertiesByCategoryFromApi('commercial');
      
      // Apply filters to the fetched data
      return allProperties.where((property) {
        bool matches = true;
        
        if (status != null && status != 'all') {
          matches = matches && property['status'] == status;
        }
        
        if (propertyType != null && propertyType != 'all') {
          matches = matches && property['propertyType'] == propertyType;
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
    } catch (e) {
      print('Error filtering commercial properties from API: $e');
      // Fallback to database if API fails
      try {
        return await _dbHelper.getCommercialPropertiesByFilter(
          status: status,
          propertyType: propertyType,
          minPrice: minPrice,
          maxPrice: maxPrice,
          searchQuery: searchQuery,
        );
      } catch (dbError) {
        print('Error filtering commercial properties from database: $dbError');
        throw e;
      }
    }
  }

  // Get land properties with filtering
  static Future<List<Map<String, dynamic>>> getLandPropertiesWithFilter({
    String? landType,
    String? areaFilter,
    String? searchQuery,
  }) async {
    try {
      // Try API first - using general endpoint and filtering in memory
      final allProperties = await _fetchPropertiesByCategoryFromApi('land');
      
      // Apply filters to the fetched data
      return allProperties.where((property) {
        bool matches = true;
        
        if (landType != null && landType != 'all') {
          matches = matches && property['landType'] == landType;
        }
        
        if (searchQuery != null && searchQuery.isNotEmpty) {
          final title = property['title']?.toString().toLowerCase() ?? '';
          final location = property['location']?.toString().toLowerCase() ?? '';
          final query = searchQuery.toLowerCase();
          matches = matches && (title.contains(query) || location.contains(query));
        }
        
        // Handle area filter if specified
        if (areaFilter != null && areaFilter != 'all') {
          final double area = property['area'] is double 
              ? property['area'] 
              : double.tryParse(property['area']?.toString() ?? '0') ?? 0;
          
          final String areaUnit = property['areaUnit']?.toString() ?? 'sqm';
          
          switch (areaFilter) {
            case 'small':
              if (areaUnit == 'acres') {
                matches = matches && area <= 2;
              } else {
                matches = matches && area <= 600;
              }
              break;
            case 'medium':
              if (areaUnit == 'acres') {
                matches = matches && area > 2 && area <= 10;
              } else {
                matches = matches && area > 600 && area <= 1500;
              }
              break;
            case 'large':
              if (areaUnit == 'acres') {
                matches = matches && area > 10;
              } else {
                matches = matches && area > 1500;
              }
              break;
          }
        }
        
        return matches;
      }).toList();
    } catch (e) {
      print('Error filtering land properties from API: $e');
      // Fallback to database if API fails
      try {
        return await _dbHelper.getLandPropertiesByFilter(
          landType: landType,
          searchQuery: searchQuery,
        );
      } catch (dbError) {
        print('Error filtering land properties from database: $dbError');
        throw e;
      }
    }
  }

  // Get material properties with filtering
  static Future<List<Map<String, dynamic>>> getMaterialPropertiesWithFilter({
    String? materialType,
    String? condition,
    String? searchQuery,
  }) async {
    try {
      // Try API first - using general endpoint and filtering in memory
      final allProperties = await _fetchPropertiesByCategoryFromApi('material');
      
      // Apply filters to the fetched data
      return allProperties.where((property) {
        bool matches = true;
        
        if (materialType != null && materialType != 'all') {
          matches = matches && property['materialType'] == materialType;
        }
        
        if (condition != null && condition != 'all') {
          matches = matches && property['condition'] == condition;
        }
        
        if (searchQuery != null && searchQuery.isNotEmpty) {
          final title = property['title']?.toString().toLowerCase() ?? '';
          final location = property['location']?.toString().toLowerCase() ?? '';
          final brand = property['brand']?.toString().toLowerCase() ?? '';
          final query = searchQuery.toLowerCase();
          matches = matches && (title.contains(query) || location.contains(query) || brand.contains(query));
        }
        
        return matches;
      }).toList();
    } catch (e) {
      print('Error filtering material properties from API: $e');
      // Fallback to database if API fails
      try {
        return await _dbHelper.getMaterialPropertiesByFilter(
          materialType: materialType,
          condition: condition,
          searchQuery: searchQuery,
        );
      } catch (dbError) {
        print('Error filtering material properties from database: $dbError');
        throw e;
      }
    }
  }

  // Fetch properties by location (using database)
  static Future<List<Map<String, dynamic>>> getPropertiesByLocation(String location) async {
    try {
      // Here we simply use the search functionality to filter by location
      // This would be better with a dedicated database method
      final residential = await _dbHelper.getResidentialPropertiesByFilter(searchQuery: location);
      final commercial = await _dbHelper.getCommercialPropertiesByFilter(searchQuery: location);
      final land = await _dbHelper.getLandPropertiesByFilter(searchQuery: location);
      final material = await _dbHelper.getMaterialPropertiesByFilter(searchQuery: location);
      
      return [...residential, ...commercial, ...land, ...material];
    } catch (e) {
      print('Error fetching properties by location from database: $e');
      // Fallback to API
      final response = await http.get(Uri.parse('$baseUrl/properties/location/$location'));
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else {
        throw Exception('Failed to fetch properties in $location');
      }
    }
  }

  // Fetch properties by price range (using database filtering)
  static Future<List<Map<String, dynamic>>> getPropertiesByPriceRange(double minPrice, double maxPrice) async {
    try {
      final residential = await _dbHelper.getResidentialPropertiesByFilter(
        minPrice: minPrice,
        maxPrice: maxPrice,
      );
      final commercial = await _dbHelper.getCommercialPropertiesByFilter(
        minPrice: minPrice,
        maxPrice: maxPrice,
      );
      
      // For other property types we'll need to filter in memory since the method doesn't support price filtering
      final land = await _dbHelper.getLandProperties();
      final material = await _dbHelper.getMaterialProperties();
      
      final filteredLand = land.where((p) {
        final price = p['price'] is double ? p['price'] : double.tryParse(p['price'].toString()) ?? 0.0;
        return price >= minPrice && price <= maxPrice;
      }).toList();
      
      final filteredMaterial = material.where((p) {
        final price = p['price'] is double ? p['price'] : double.tryParse(p['price'].toString()) ?? 0.0;
        return price >= minPrice && price <= maxPrice;
      }).toList();
      
      return [...residential, ...commercial, ...filteredLand, ...filteredMaterial];
    } catch (e) {
      print('Error fetching properties by price range from database: $e');
      // Fallback to API
      final response = await http.get(Uri.parse('$baseUrl/properties/price-range?min=$minPrice&max=$maxPrice'));
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else {
        throw Exception('Failed to fetch properties in price range $minPrice - $maxPrice');
      }
    }
  }
  // Fetch properties by size range
  static Future<List<Map<String, dynamic>>> getPropertiesBySizeRange(double minSize, double maxSize) async {
    final response = await http.get(Uri.parse('$baseUrl/properties/size-range?min=$minSize&max=$maxSize'));
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    } else {
      throw Exception('Failed to fetch properties in size range $minSize - $maxSize');
    }
  }
  // Fetch properties by amenities
  static Future<List<Map<String, dynamic>>> getPropertiesByAmenities(List<String> amenities) async {
    final response = await http.post(
      Uri.parse('$baseUrl/properties/amenities'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'amenities': amenities}),
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    } else {
      throw Exception('Failed to fetch properties with specified amenities');
    }
  }
  // Fetch properties by features
  static Future<List<Map<String, dynamic>>> getPropertiesByFeatures(List<String> features) async {
    final response = await http.post(
      Uri.parse('$baseUrl/properties/features'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'features': features}),
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    } else {
      throw Exception('Failed to fetch properties with specified features');
    }
  }
  // Fetch properties by owner
  static Future<List<Map<String, dynamic>>> getPropertiesByOwner(int ownerId) async {
    final response = await http.get(Uri.parse('$baseUrl/properties/owner/$ownerId'));
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    } else {
      throw Exception('Failed to fetch properties owned by user with ID $ownerId');
    }
  }
  // Fetch properties by status (available, sold, rented, etc.)
  static Future<List<Map<String, dynamic>>> getPropertiesByStatus(String status) async {
    final response = await http.get(Uri.parse('$baseUrl/properties/status/$status'));
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    } else {
      throw Exception('Failed to fetch properties with status $status');
    }
  }
  // Fetch properties by date added
  static Future<List<Map<String, dynamic>>> getPropertiesByDateAdded(DateTime date) async {
    final response = await http.get(Uri.parse('$baseUrl/properties/date-added/${date.toIso8601String()}'));
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    } else {
      throw Exception('Failed to fetch properties added on $date');
    }
  }
  // Fetch properties by last updated date
  static Future<List<Map<String, dynamic>>> getPropertiesByLastUpdated(DateTime date) async {
    final response = await http.get(Uri.parse('$baseUrl/properties/last-updated/${date.toIso8601String()}'));
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    } else {
      throw Exception('Failed to fetch properties last updated on $date');
    }
  }
  // Fetch properties by custom filters
  static Future<List<Map<String, dynamic>>> getPropertiesByFilters(Map<String, dynamic> filters) async {
    final response = await http.post(
      Uri.parse('$baseUrl/properties/filters'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(filters),
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    } else {
      throw Exception('Failed to fetch properties with specified filters');
    }
  }
  // Fetch properties by search query
  static Future<List<Map<String, dynamic>>> searchProperties(String query) async {
    final response = await http.get(Uri.parse('$baseUrl/properties/search?query=$query'));
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    } else {
      throw Exception('Failed to search properties with query: $query');
    }
  }
}
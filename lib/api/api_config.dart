import 'dart:io';

/// Configuration class for API endpoints
class ApiConfig {
  /// Base URL for the API
  /// In development, this can point to a local server (e.g. http://localhost:8080)
  /// In production, this can point to the deployed server (e.g. https://mipripity-api-1.onrender.com)
  static const String baseUrl = 'https://mipripity-api-1.onrender.com';
  
  /// Alternative production URL (can be used by changing the active URL in ApiConfig)
  static const String productionUrl = 'https://mipripity-api-1.onrender.com';
  
  /// Default timeout for API requests in seconds
  static const int defaultTimeout = 10;

  /// Returns the active API base URL
  static String getBaseUrl() {
    // For development/testing purposes, uncomment the line below to use the local server
    // return baseUrl;
    
    // For production, use the deployed server
    return productionUrl;
  }
  
  /// Check if the API is reachable
  static Future<bool> isApiReachable() async {
    try {
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 5);
      
      final url = Uri.parse(getBaseUrl());
      final request = await client.getUrl(url);
      final response = await request.close();
      
      client.close();
      return response.statusCode < 500;
    } catch (e) {
      print('API connectivity check failed: $e');
      return false;
    }
  }
}
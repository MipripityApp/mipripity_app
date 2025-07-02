import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_config.dart';

/// API service for agency-related operations
class AgencyApi {
  /// Base URL for API endpoints
  final String _baseUrl = ApiConfig.getBaseUrl();

  /// Verify agency name with CAC
  /// 
  /// This calls the backend which scrapes the CAC public search page
  /// to verify if the agency name is registered.
  /// 
  /// Returns a Map with verification status, RC number, and official name
  Future<Map<String, dynamic>> verifyAgency(String agencyName) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/verify-agency'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'agency_name': agencyName,
        }),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {
          'success': true,
          'body': jsonDecode(response.body),
          'statusCode': response.statusCode,
        };
      } else {
        return {
          'success': false,
          'body': {
            'error': 'Failed to verify agency: ${response.body}',
            'status': 'not_found'
          },
          'statusCode': response.statusCode,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'body': {
          'error': 'Exception verifying agency: $e',
          'status': 'error'
        },
        'statusCode': 500,
      };
    }
  }
}
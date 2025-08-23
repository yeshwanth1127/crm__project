import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiTestService {
  static const String baseUrl = 'https://orbitco.in/api';
  
  // Test the analytics endpoint
  static Future<Map<String, dynamic>> testAnalyticsEndpoint(int companyId) async {
    try {
      print('🧪 Testing analytics endpoint...');
      final url = '$baseUrl/sales/analytics/overview/?company_id=$companyId&range=all';
      print('🌐 URL: $url');
      
      final response = await http.get(Uri.parse(url));
      print('📡 Response status: ${response.statusCode}');
      print('📡 Response body: ${response.body}');
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        return {
          'error': 'HTTP ${response.statusCode}',
          'body': response.body,
          'url': url
        };
      }
    } catch (e) {
      print('❌ Analytics endpoint test error: $e');
      return {
        'error': e.toString(),
        'url': '$baseUrl/sales/analytics/overview/?company_id=$companyId&range=all'
      };
    }
  }
  
  // Test the subscription features endpoint
  static Future<Map<String, dynamic>> testSubscriptionEndpoint(int companyId) async {
    try {
      print('🧪 Testing subscription endpoint...');
      final url = '$baseUrl/subscription/company/$companyId/features';
      print('🌐 URL: $url');
      
      final response = await http.get(Uri.parse(url));
      print('📡 Response status: ${response.statusCode}');
      print('📡 Response body: ${response.body}');
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        return {
          'error': 'HTTP ${response.statusCode}',
          'body': response.body,
          'url': url
        };
      }
    } catch (e) {
      print('❌ Subscription endpoint test error: $e');
      return {
        'error': e.toString(),
        'url': '$baseUrl/subscription/company/$companyId/features'
      };
    }
  }
  
  // Test the root endpoint
  static Future<Map<String, dynamic>> testRootEndpoint() async {
    try {
      print('🧪 Testing root endpoint...');
      final url = baseUrl;
      print('🌐 URL: $url');
      
      final response = await http.get(Uri.parse(url));
      print('📡 Response status: ${response.statusCode}');
      print('📡 Response body: ${response.body}');
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        return {
          'error': 'HTTP ${response.statusCode}',
          'body': response.body,
          'url': url
        };
      }
    } catch (e) {
      print('❌ Root endpoint test error: $e');
      return {
        'error': e.toString(),
        'url': baseUrl
      };
    }
  }
}

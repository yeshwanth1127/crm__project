import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class SubscriptionService {
  static const String baseUrl = 'https://orbitco.in';
  
  // Get available subscription plans
  static Future<List<Map<String, dynamic>>> getAvailablePlans() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/onboarding/plans'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data['plans']);
      } else {
        throw Exception('Failed to load plans: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error loading plans: $e');
    }
  }

  // Get company subscription
  static Future<Map<String, dynamic>> getCompanySubscription(int companyId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      
      if (token == null) {
        throw Exception('Authentication token not found');
      }

              final response = await http.get(
          Uri.parse('$baseUrl/subscription/company/$companyId'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else if (response.statusCode == 404) {
        return {'subscription_status': 'no_subscription'};
      } else {
        throw Exception('Failed to load subscription: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error loading subscription: $e');
    }
  }

  // Get company features
  static Future<Map<String, dynamic>> getCompanyFeatures(int companyId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      
      if (token == null) {
        throw Exception('Authentication token not found');
      }

              final response = await http.get(
          Uri.parse('$baseUrl/subscription/company/$companyId/features'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load features: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error loading features: $e');
    }
  }

  // Subscribe company to a plan
  static Future<Map<String, dynamic>> subscribeCompany(Map<String, dynamic> subscriptionData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      
      if (token == null) {
        throw Exception('Authentication token not found');
      }

              final response = await http.post(
          Uri.parse('$baseUrl/subscription/subscribe'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: json.encode(subscriptionData),
        );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final error = json.decode(response.body);
        throw Exception(error['detail'] ?? 'Failed to subscribe');
      }
    } catch (e) {
      throw Exception('Error subscribing: $e');
    }
  }

  // Cancel subscription
  static Future<Map<String, dynamic>> cancelSubscription(int companyId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      
      if (token == null) {
        throw Exception('Authentication token not found');
      }

      final response = await http.put(
        Uri.parse('$baseUrl/subscription/company/$companyId/cancel'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final error = json.decode(response.body);
        throw Exception(error['detail'] ?? 'Failed to cancel subscription');
      }
    } catch (e) {
      throw Exception('Error cancelling subscription: $e');
    }
  }

  // Get billing history
  static Future<List<Map<String, dynamic>>> getBillingHistory(int companyId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      
      if (token == null) {
        throw Exception('Authentication token not found');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/subscription/billing/$companyId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data);
      } else {
        throw Exception('Failed to load billing history: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error loading billing history: $e');
    }
  }
}

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// ✅ Backend URLs (Update these based on your server configuration):
/// If backend is on orbitco.in:8001 → 'https://orbitco.in:8001'
/// If backend is on orbitco.in (port 80/443) → 'https://orbitco.in'
/// For local development → 'http://localhost:8001'

class ApiService {
  static const String salesBaseUrl = 'https://orbitco.in/sales';
  static const String baseUrl = 'https://orbitco.in/api/onboarding';
  static const String authBaseUrl = 'https://orbitco.in/api/auth';

  Future<Map<String, dynamic>?> submitOnboarding(
    String companySize, 
    String crmType, 
    String companyName, {
    int? selectedPlanId,
    String? billingCycle,
  }) async {
    try {
      final Map<String, dynamic> requestBody = {
        "company_name": companyName,
        "company_size": companySize,
        "crm_type": crmType.toLowerCase().replaceAll(' ', '_'),
      };

      // Add plan selection if provided
      if (selectedPlanId != null) {
        requestBody["selected_plan_id"] = selectedPlanId;
      }
      if (billingCycle != null) {
        requestBody["billing_cycle"] = billingCycle;
      }

      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Backend error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network/Unexpected Error: $e');
    }
  }
  static Future<Map<String, dynamic>> fetchDashboardStats(int companyId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final response = await http.get(
        Uri.parse('$salesBaseUrl/dashboard-stats?company_id=$companyId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Backend error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  static Future<Map<String, dynamic>> fetchSelectedFeatures(int companyId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final response = await http.get(
        Uri.parse('$salesBaseUrl/selected-features?company_id=$companyId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Backend error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  static Future<void> saveFeatures(int companyId, List<String> features) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/update-features'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'company_id': companyId, 'updated_features': features}),
    );
    if (response.statusCode != 200) throw Exception('Failed to update features');
  }
}

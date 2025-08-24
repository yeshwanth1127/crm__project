import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_web/services/subscription_service.dart';

class FeatureFilterService {
  static Map<String, dynamic> _availableFeatures = {};
  static Map<String, dynamic> _currentPlan = {};
  static int _currentUsers = 0;
  static int _userLimit = 3;
  static bool _canAccess = true;
  static bool _canCreateMore = true;
  static int _remainingSlots = 2;

  static Future<void> initializeFeatures() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final companyId = prefs.getInt('company_id');
      final userToken = prefs.getString('token');

      if (companyId != null && userToken != null) {
        final response = await SubscriptionService.getCompanyFeatures(companyId);
        
        // Extract features and convert to the expected format
        final featuresList = response['features'] as List? ?? [];
        _availableFeatures = {};
        for (final feature in featuresList) {
          _availableFeatures[feature] = true;
        }
        
        // Extract plan information
        _currentPlan = {
          'plan_name': response['plan_name'] ?? 'Launch Plan',
          'user_limit': response['user_limit'] ?? 3,
        };
        
        _currentUsers = response['current_users'] ?? 1;
        _userLimit = response['user_limit'] ?? 3;
        _canAccess = response['subscription_status'] != 'no_subscription';
        _canCreateMore = _currentUsers < _userLimit;
        _remainingSlots = _userLimit - _currentUsers;
      } else {
        // Fallback to Launch Plan
        _availableFeatures = {
          'user_management': true,
          'customer_management': true,
          'task_tracking': true,
        };
        _currentPlan = {
          'plan_name': 'Launch Plan',
          'user_limit': 3,
        };
        _currentUsers = 1;
        _userLimit = 3;
        _canAccess = true;
        _canCreateMore = true;
        _remainingSlots = 2;
      }
    } catch (e) {
      // Fallback to Launch Plan on error
      _availableFeatures = {
        'user_management': true,
        'customer_management': true,
        'task_tracking': true,
      };
      _currentPlan = {
        'plan_name': 'Launch Plan',
        'user_limit': 3,
      };
      _currentUsers = 1;
      _userLimit = 3;
      _canAccess = true;
      _canCreateMore = true;
      _remainingSlots = 2;
    }
  }

  static bool hasFeature(String feature) {
    return _availableFeatures[feature] == true;
  }

  static Map<String, dynamic> getPlanInfo() {
    return _currentPlan;
  }

  static int getCurrentUsers() {
    return _currentUsers;
  }

  static int getUserLimit() {
    return _userLimit;
  }

  static bool canAccess() {
    return _canAccess;
  }

  static bool canCreateMoreUsers() {
    return _canCreateMore;
  }

  static int getRemainingSlots() {
    return _remainingSlots;
  }

  static Map<String, dynamic> getUserManagementInfo() {
    return {
      'can_access': _canAccess,
      'current_users': _currentUsers,
      'user_limit': _userLimit,
      'can_create_more': _canCreateMore,
      'remaining_slots': _remainingSlots,
      'plan_name': _currentPlan['plan_name'] ?? 'Launch Plan',
    };
  }

  static double? getPlanAdditionalUserPrice(String planName) {
    final pricing = {
      'Launch Plan': 500.0,
      'Growth Plan': 400.0,
      'Scale Plan': 300.0,
    };
    return pricing[planName];
  }

  static void updateUserCount(int newCount) {
    _currentUsers = newCount;
    _canCreateMore = _currentUsers < _userLimit;
    _remainingSlots = _userLimit - _currentUsers;
  }

  // Force refresh features from API
  static Future<void> forceRefreshFeatures() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final companyId = prefs.getInt('company_id');
      final userToken = prefs.getString('token');

      if (companyId != null && userToken != null) {
        final response = await SubscriptionService.getCompanyFeatures(companyId);
        
        // Extract features and convert to the expected format
        final featuresList = response['features'] as List? ?? [];
        _availableFeatures = {};
        for (final feature in featuresList) {
          _availableFeatures[feature] = true;
        }
        
        // Extract plan information
        _currentPlan = {
          'plan_name': response['plan_name'] ?? 'Launch Plan',
          'user_limit': response['user_limit'] ?? 3,
        };
        
        _currentUsers = response['current_users'] ?? 1;
        _userLimit = response['user_limit'] ?? 3;
        _canAccess = response['subscription_status'] != 'no_subscription';
        _canCreateMore = _currentUsers < _userLimit;
        _remainingSlots = _userLimit - _currentUsers;
      }
    } catch (e) {
      // Keep existing values on error
    }
  }
}

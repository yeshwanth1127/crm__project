import 'package:shared_preferences/shared_preferences.dart';
import 'subscription_service.dart';

class FeatureFilterService {
  static List<String> _availableFeatures = [];
  static String _currentPlan = '';
  static int _userLimit = 0;
  static int _currentUsers = 0;

  // Plan-specific feature mappings
  static const Map<String, List<String>> _planFeatures = {
    'Launch': [
      'contact_management',
      'lead_management',
      'task_tracking',
      'basic_dashboard',
      'limited_custom_fields',
      'mobile_access',
      'email_support',
      'ssl_security',
      'vps_hosting'
    ],
    'Accelerate': [
      'contact_management',
      'lead_management',
      'task_tracking',
      'basic_dashboard',
      'limited_custom_fields',
      'mobile_access',
      'email_support',
      'ssl_security',
      'vps_hosting',
      'lead_pipeline',
      'visual_sales_pipeline',
      'email_sms_notifications',
      'custom_dashboards',
      'customer_segments',
      'custom_fields',
      'support_tickets',
      'role_based_access',
      'customer_notes',
      'email_sms_integration',
      'team_chat',
      'auto_backups'
    ],
    'Scale': [
      'contact_management',
      'lead_management',
      'task_tracking',
      'basic_dashboard',
      'limited_custom_fields',
      'mobile_access',
      'email_support',
      'ssl_security',
      'vps_hosting',
      'lead_pipeline',
      'visual_sales_pipeline',
      'email_sms_notifications',
      'custom_dashboards',
      'customer_segments',
      'custom_fields',
      'support_tickets',
      'role_based_access',
      'customer_notes',
      'email_sms_integration',
      'team_chat',
      'auto_backups',
      'campaign_management',
      'custom_lead_stages',
      'bulk_messaging',
      'advanced_analytics',
      'file_uploads',
      'conversation_logs',
      'role_management',
      'user_management',
      'activity_timeline',
      'notification_center',
      'custom_domain'
    ],
    'Essentials': [
      'contact_management',
      'lead_management',
      'task_tracking',
      'follow_up_reminders',
      'activity_logs',
      'admin_salesman_roles',
      'custom_branding',
      'data_ownership'
    ],
    'Pro Deploy': [
      'contact_management',
      'lead_management',
      'task_tracking',
      'follow_up_reminders',
      'activity_logs',
      'admin_salesman_roles',
      'custom_branding',
      'data_ownership',
      'role_based_access',
      'support_module',
      'custom_fields',
      'file_uploads',
      'enhanced_analytics',
      'sms_email_notifications',
      'training_videos'
    ],
    'Enterprise': [
      'contact_management',
      'lead_management',
      'task_tracking',
      'follow_up_reminders',
      'activity_logs',
      'admin_salesman_roles',
      'custom_branding',
      'data_ownership',
      'role_based_access',
      'support_module',
      'custom_fields',
      'file_uploads',
      'enhanced_analytics',
      'sms_email_notifications',
      'training_videos',
      'white_labeling',
      'rest_api',
      'campaign_management',
      'crm_reports',
      'role_audit',
      'data_segmentation',
      'custom_workflows',
      'lifetime_license',
      'dedicated_manager'
    ]
  };

  // Initialize features for the current user
  static Future<void> initializeFeatures() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final companyId = prefs.getInt('company_id');
      
      if (companyId != null) {
        final featuresData = await SubscriptionService.getCompanyFeatures(companyId);
        
        _availableFeatures = List<String>.from(featuresData['features'] ?? []);
        _currentPlan = featuresData['plan_name'] ?? 'No Plan';
        _userLimit = featuresData['user_limit'] ?? 0;
        _currentUsers = featuresData['current_users'] ?? 0;
        
        // If no features from API, use plan-based features
        if (_availableFeatures.isEmpty && _currentPlan != 'No Plan') {
          _availableFeatures = _planFeatures[_currentPlan] ?? _getCoreFeatures();
        }
      }
    } catch (e) {
      print('Error initializing features: $e');
      // Fallback to core features only
      _availableFeatures = _getCoreFeatures();
    }
  }

  // Get core features (available in all plans)
  static List<String> _getCoreFeatures() {
    return [
      'contact_management',
      'lead_management',
      'task_tracking',
      'basic_dashboard'
    ];
  }

  // Check if a specific feature is available
  static bool hasFeature(String featureKey) {
    return _availableFeatures.contains(featureKey);
  }

  // Get all available features
  static List<String> getAvailableFeatures() {
    return List.from(_availableFeatures);
  }

  // Get current plan info
  static Map<String, dynamic> getPlanInfo() {
    return {
      'plan_name': _currentPlan,
      'user_limit': _userLimit,
      'current_users': _currentUsers,
      'available_features': _availableFeatures,
    };
  }

  // Filter dashboard menu items based on available features
  static List<Map<String, dynamic>> filterDashboardMenu(List<Map<String, dynamic>> allMenuItems) {
    return allMenuItems.where((item) {
      final featureKey = item['feature_key'];
      if (featureKey == null) return true; // Always show items without feature requirements
      return hasFeature(featureKey);
    }).toList();
  }

  // Check if user can access advanced features
  static bool canAccessAdvancedFeatures() {
    return hasFeature('advanced_analytics') || 
           hasFeature('campaign_management') || 
           hasFeature('custom_workflows');
  }

  // Check if user can access support features
  static bool canAccessSupportFeatures() {
    return hasFeature('support_tickets') || 
           hasFeature('support_module');
  }

  // Check if user can access marketing features
  static bool canAccessMarketingFeatures() {
    return hasFeature('campaign_management') || 
           hasFeature('bulk_messaging') || 
           hasFeature('marketing_automation');
  }

  // Get feature-based dashboard title
  static String getDashboardTitle() {
    if (canAccessAdvancedFeatures()) {
      return 'Enterprise CRM Dashboard';
    } else if (canAccessSupportFeatures()) {
      return 'Professional CRM Dashboard';
    } else {
      return 'Basic CRM Dashboard';
    }
  }

  // Check if feature is available for current plan
  static bool isFeatureAvailableForPlan(String featureKey) {
    if (_currentPlan == 'No Plan') return false;
    final planFeatures = _planFeatures[_currentPlan];
    return planFeatures?.contains(featureKey) ?? false;
  }

  // Get plan upgrade suggestions
  static List<String> getUpgradeSuggestions() {
    if (_currentPlan == 'No Plan') return [];
    
    final suggestions = <String>[];
    
    if (!hasFeature('support_tickets') && _currentPlan == 'Launch') {
      suggestions.add('Upgrade to Accelerate for Support CRM features');
    }
    
    if (!hasFeature('campaign_management') && _currentPlan != 'Scale' && _currentPlan != 'Enterprise') {
      suggestions.add('Upgrade to Scale for Marketing CRM features');
    }
    
    if (!hasFeature('advanced_analytics') && _currentPlan != 'Scale' && _currentPlan != 'Enterprise') {
      suggestions.add('Upgrade to Scale for Advanced Analytics');
    }
    
    return suggestions;
  }
}

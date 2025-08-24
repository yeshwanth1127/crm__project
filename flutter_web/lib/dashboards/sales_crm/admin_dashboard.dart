import 'package:flutter/material.dart';
import 'package:flutter_web/services/api_service.dart';
import 'package:flutter_web/services/feature_filter_service.dart';
import 'package:flutter_web/sales_crm/user_management/user_management.dart';
import 'package:flutter_web/sales_crm/customers/customers_home.dart';
import 'package:flutter_web/sales_crm/tasks/task_list_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AdminDashboard extends StatefulWidget {
  final int companyId;
  
  const AdminDashboard({super.key, required this.companyId});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  bool _isLoading = true;
  Map<String, dynamic> _dashboardData = {};
  String _selectedPage = 'Dashboard Overview';
  int? _companyId;
  String? _userToken;
  String? _adminName;
  String? _adminEmail;

  @override
  void initState() {
    super.initState();
    _initializeDashboard();
  }

  Future<void> _initializeDashboard() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _companyId = widget.companyId;
      _userToken = prefs.getString('token');
      _adminName = prefs.getString('full_name') ?? 'Admin';
      _adminEmail = prefs.getString('email') ?? '';

      if (_companyId != null && _userToken != null) {
        await FeatureFilterService.initializeFeatures();
        await FeatureFilterService.forceRefreshFeatures(); // Force refresh to ensure correct plan
        await _fetchDashboardData();
      }
    } catch (e) {
      // Handle initialization error
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchDashboardData() async {
    try {
      final data = await ApiService.fetchDashboardStats(_companyId!);
      setState(() {
        _dashboardData = data;
      });
    } catch (e) {
      // Handle API error
      _loadFallbackData();
    }
  }

  void _loadFallbackData() {
    setState(() {
      _dashboardData = {
        'total_customers': 0,
        'total_tasks': 0,
        'total_users': 1,
        'recent_activities': [],
      };
    });
  }

  List<Map<String, dynamic>> _getMenuItems() {
    return [
      {'title': 'Dashboard Overview', 'icon': Icons.dashboard, 'feature_key': null},
      {'title': 'User Management', 'icon': Icons.people, 'feature_key': 'user_management'},
      {'title': 'Customers', 'icon': Icons.business, 'feature_key': 'customer_management'},
      {'title': 'Tasks', 'icon': Icons.task, 'feature_key': 'task_tracking'},
      {'title': 'Follow-ups', 'icon': Icons.notifications, 'feature_key': 'follow_up_reminders'},
      {'title': 'Pipeline Analytics', 'icon': Icons.analytics, 'feature_key': 'visual_sales_pipeline'},
      {'title': 'Feature Settings', 'icon': Icons.settings, 'feature_key': 'custom_fields'},
      {'title': 'Company Settings', 'icon': Icons.business_center, 'feature_key': 'role_based_access'},
    ];
  }

  List<Map<String, dynamic>> _getFilteredMenuItems() {
    final allItems = _getMenuItems();
    return allItems.where((item) {
      final featureKey = item['feature_key'];
      if (featureKey == null) return true;
      return FeatureFilterService.hasFeature(featureKey);
    }).toList();
  }

  Widget _buildDashboardContent() {
    switch (_selectedPage) {
      case 'Dashboard Overview':
        return _buildDashboardOverview();
      case 'User Management':
        return UserManagementScreen();
      case 'Customers':
        return CustomersHome(companyId: widget.companyId);
      case 'Tasks':
        return TaskListScreen(companyId: widget.companyId);
      case 'Follow-ups':
        return _buildPlaceholderPage('Follow-ups', 'Follow-up management features');
      case 'Pipeline Analytics':
        return _buildPlaceholderPage('Pipeline Analytics', 'Sales pipeline visualization');
      case 'Feature Settings':
        return _buildPlaceholderPage('Feature Settings', 'Custom field configuration');
      case 'Company Settings':
        return _buildPlaceholderPage('Company Settings', 'Role-based access control');
      default:
        return _buildDashboardOverview();
    }
  }

  Widget _buildPlaceholderPage(String title, String description) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.construction,
            size: 80,
            color: Colors.white.withOpacity(0.6),
          ),
          const SizedBox(height: 20),
          Text(
            title,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            description,
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardOverview() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome back, $_adminName!',
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          _buildStatsCards(),
          const SizedBox(height: 20),
          _buildRecentActivities(),
        ],
      ),
    );
  }

  Widget _buildStatsCards() {
    return Row(
      children: [
        _buildStatCard(
          'Total Customers',
          _dashboardData['total_customers']?.toString() ?? '0',
          Icons.business,
          Colors.blue,
        ),
        const SizedBox(width: 20),
        _buildStatCard(
          'Total Tasks',
          _dashboardData['total_tasks']?.toString() ?? '0',
          Icons.task,
          Colors.green,
        ),
        const SizedBox(width: 20),
        _buildStatCard(
          'Total Users',
          '${FeatureFilterService.getCurrentUsers()}/${FeatureFilterService.getUserLimit()}',
          Icons.people,
          Colors.orange,
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 30),
            const SizedBox(height: 10),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Text(
              title,
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivities() {
    final activities = _dashboardData['recent_activities'] as List? ?? [];
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Recent Activities',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 15),
          if (activities.isEmpty)
            Text(
              'No recent activities',
              style: TextStyle(color: Colors.white.withOpacity(0.6)),
            )
          else
            ...activities.map((activity) => _buildActivityItem(activity)),
        ],
      ),
    );
  }

  Widget _buildActivityItem(dynamic activity) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(
            Icons.circle,
            size: 8,
            color: Colors.white.withOpacity(0.6),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              activity.toString(),
              style: TextStyle(color: Colors.white.withOpacity(0.8)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    final filteredMenuItems = _getFilteredMenuItems();
    final planInfo = FeatureFilterService.getPlanInfo();
    final planName = planInfo['plan_name'] ?? 'Launch Plan';

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF2193b0), Color(0xFF6dd5ed)],
          ),
        ),
        child: Row(
          children: [
            // Left Sidebar
            Container(
              width: 250,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
                border: Border.all(color: Colors.white.withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 40),
                  // Admin Name Display
                  Text(
                    'Welcome,',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    _adminName ?? 'Admin',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (_adminEmail != null && _adminEmail!.isNotEmpty) ...[
                    const SizedBox(height: 5),
                    Text(
                      _adminEmail!,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  const SizedBox(height: 20),
                  // Plan Display
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          planName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.refresh, color: Colors.white, size: 16),
                          onPressed: () async {
                            await FeatureFilterService.forceRefreshFeatures();
                            setState(() {});
                          },
                          tooltip: 'Refresh Plan',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Menu Items
                  ...filteredMenuItems.map((item) => _buildMenuItem(item)),
                  const Spacer(),
                  // Logout Button
                  ListTile(
                    title: const Text(
                      'Logout',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    onTap: () async {
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.clear();
                      Navigator.of(context).pushReplacementNamed('/login');
                    },
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
            // Main Content
            Expanded(
              child: _buildDashboardContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(Map<String, dynamic> item) {
    final isSelected = _selectedPage == item['title'];
    return ListTile(
      selected: isSelected,
      selectedTileColor: Colors.white.withOpacity(0.2),
      leading: Icon(
        item['icon'],
        color: Colors.white,
      ),
      title: Text(
        item['title'],
        style: TextStyle(
          color: Colors.white,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      onTap: () {
        setState(() {
          _selectedPage = item['title'];
        });
      },
    );
  }
}

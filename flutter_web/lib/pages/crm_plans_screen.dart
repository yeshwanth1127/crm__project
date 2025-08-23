import 'package:flutter/material.dart';
import 'package:flutter_web/services/subscription_service.dart';
import 'package:flutter_web/pages/onboarding_screen.dart';

class CRMPlansScreen extends StatefulWidget {
  const CRMPlansScreen({super.key});

  @override
  State<CRMPlansScreen> createState() => _CRMPlansScreenState();
}

class _CRMPlansScreenState extends State<CRMPlansScreen> {
  List<Map<String, dynamic>> plans = [];
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _loadPlans();
  }

  Future<void> _loadPlans() async {
    try {
      setState(() {
        isLoading = true;
        error = null;
      });

      final plansData = await SubscriptionService.getAvailablePlans();
      setState(() {
        plans = plansData;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }

  void _selectPlan(Map<String, dynamic> plan) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OnboardingScreen(selectedPlan: plan),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(),
              Expanded(
                child: _buildContent(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 20),
          const Text(
            'CRM Plans',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          Image.asset(
            'assets/images/orbitcrm_logo.png',
            height: 40,
            fit: BoxFit.contain,
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    if (error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Error loading plans',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _loadPlans,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const Text(
            'Choose Your Perfect CRM Plan',
            style: TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          const Text(
            'Select the plan that best fits your business needs',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          _buildSubscriptionPlans(),
          const SizedBox(height: 40),
          _buildSelfHostedPlans(),
        ],
      ),
    );
  }

  Widget _buildSubscriptionPlans() {
    final subscriptionPlans = plans.where((plan) => plan['type'] == 'subscription').toList();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Subscription Plans',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 20),
        Wrap(
          spacing: 20,
          runSpacing: 20,
          children: subscriptionPlans.map((plan) => _buildPlanCard(plan)).toList(),
        ),
      ],
    );
  }

  Widget _buildSelfHostedPlans() {
    final selfHostedPlans = plans.where((plan) => plan['type'] == 'self_hosted').toList();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Self-Hosted CRM Deployment',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 20),
        Wrap(
          spacing: 20,
          runSpacing: 20,
          children: selfHostedPlans.map((plan) => _buildPlanCard(plan)).toList(),
        ),
      ],
    );
  }

  Widget _buildPlanCard(Map<String, dynamic> plan) {
    final isSubscription = plan['type'] == 'subscription';
    final isPopular = plan['name'] == 'Accelerate' || plan['name'] == 'Pro Deploy';
    
    return Container(
      width: 350,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          if (isPopular)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: const BoxDecoration(
                color: Colors.orange,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: const Text(
                'Most Popular',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Text(
                  plan['name'],
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D3748),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  plan['description'] ?? '',
                  style: const TextStyle(
                    color: Color(0xFF718096),
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                _buildPricing(plan),
                const SizedBox(height: 20),
                _buildFeatures(plan),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _selectPlan(plan),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isPopular ? Colors.orange : const Color(0xFF6A11CB),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      isSubscription ? 'Start Free Trial' : 'Get Started',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPricing(Map<String, dynamic> plan) {
    if (plan['type'] == 'subscription') {
      return Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '₹${plan['price_monthly']?.toStringAsFixed(0) ?? '0'}',
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3748),
                ),
              ),
              const Text(
                '/month',
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF718096),
                ),
              ),
            ],
          ),
          if (plan['price_yearly'] != null) ...[
            const SizedBox(height: 8),
            Text(
              '₹${plan['price_yearly']?.toStringAsFixed(0) ?? '0'}/year (Save 17%)',
              style: const TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      );
    } else {
      return Column(
        children: [
          Text(
            '₹${plan['price_one_time']?.toStringAsFixed(0) ?? '0'}',
            style: const TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D3748),
            ),
          ),
          const Text(
            'One-time payment',
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF718096),
            ),
          ),
        ],
      );
    }
  }

  Widget _buildFeatures(Map<String, dynamic> plan) {
    final features = List<String>.from(plan['features'] ?? []);
    final userLimit = plan['user_limit'] ?? 0;
    final additionalPrice = plan['additional_user_price'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.people, color: Color(0xFF6A11CB)),
            const SizedBox(width: 8),
            Text(
              '$userLimit users included',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Color(0xFF2D3748),
              ),
            ),
            if (additionalPrice != null) ...[
              const SizedBox(width: 8),
              Text(
                '+₹$additionalPrice per additional user',
                style: const TextStyle(
                  color: Color(0xFF718096),
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 16),
        const Text(
          'Features included:',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Color(0xFF2D3748),
          ),
        ),
        const SizedBox(height: 8),
        ...features.take(8).map((feature) => Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _formatFeatureName(feature),
                  style: const TextStyle(
                    color: Color(0xFF4A5568),
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        )),
        if (features.length > 8) ...[
          const SizedBox(height: 8),
          Text(
            '+${features.length - 8} more features',
            style: const TextStyle(
              color: Color(0xFF6A11CB),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }

  String _formatFeatureName(String feature) {
    return feature
        .split('_')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }
}

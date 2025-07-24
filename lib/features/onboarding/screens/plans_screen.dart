import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:einsteiniapp/core/routes/app_router.dart' as router;
import 'package:einsteiniapp/core/utils/toast_utils.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class PlansScreen extends StatefulWidget {
  final bool isNewUser;
  
  const PlansScreen({
    Key? key,
    this.isNewUser = false,
  }) : super(key: key);

  @override
  State<PlansScreen> createState() => _PlansScreenState();
}

class _PlansScreenState extends State<PlansScreen> with SingleTickerProviderStateMixin {
  bool _isYearly = true;
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {
          _isYearly = _tabController.index == 0;
        });
      }
    });
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  Future<void> _selectPlan(String plan) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_plan', plan);
    
    if (mounted) {
      ToastUtils.showSuccessToast('$plan plan selected!');
      
      // For premium plans, redirect to the website
      if (plan != 'Free') {
        final Uri uri = Uri.parse('https://einsteini.ai/pricing');
        try {
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          } else {
            ToastUtils.showErrorToast('Could not launch pricing page');
          }
        } catch (e) {
          ToastUtils.showErrorToast('Error launching browser: $e');
        }
      } else {
        // Free plan - just go to home screen
        context.go(router.AppRoutes.home);
      }
    }
  }
  
  Future<void> _skipForNow() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_plan', 'Free');
    
    if (mounted) {
      // Navigate to home screen
      context.go(router.AppRoutes.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              floating: false,
              pinned: true,
              automaticallyImplyLeading: !widget.isNewUser,
              title: widget.isNewUser ? null : const Text('Subscription Plans'),
              actions: widget.isNewUser 
                ? [
                    TextButton(
                      onPressed: _skipForNow,
                      child: const Text('Skip for now'),
                    )
                  ] 
                : null,
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24.0, 16.0, 24.0, 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Welcome headline for new users
                    if (widget.isNewUser)
                      Column(
                        children: [
                          Text(
                            'Welcome to einsteini.ai',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ).animate().fadeIn(duration: 600.ms),
                          
                          const SizedBox(height: 12),
                          
                          Text(
                            'Choose the perfect plan to boost your LinkedIn engagement',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Colors.grey[600],
                            ),
                            textAlign: TextAlign.center,
                          ).animate().fadeIn(duration: 600.ms, delay: 200.ms),
                          
                          const SizedBox(height: 32),
                        ],
                      ),
                    
                    // Title and subtitle
                    Text(
                      'Choose the right plan that fits',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ).animate(target: widget.isNewUser ? 0.3 : 1).fadeIn(duration: 600.ms),
                    
                    Text(
                      'your business',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      textAlign: TextAlign.center,
                    ).animate(target: widget.isNewUser ? 0.3 : 1).fadeIn(duration: 600.ms),
                    
                    const SizedBox(height: 32),
                    
                    // Billing toggle
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.grey[800]
                            : Colors.grey[200],
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: TabBar(
                        controller: _tabController,
                        labelColor: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : Colors.black,
                        unselectedLabelColor: Colors.grey[600],
                        labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                        indicator: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(50),
                        ),
                        dividerColor: Colors.transparent,
                        indicatorSize: TabBarIndicatorSize.tab,
                        padding: EdgeInsets.zero,
                        labelPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        tabs: const [
                          Text('Yearly'),
                          Text('Monthly'),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
            
            // Plans Grid
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 1, // For mobile, we'll use 1 column
                  mainAxisSpacing: 16.0,
                  crossAxisSpacing: 16.0,
                  childAspectRatio: 1.2, // Adjust for card height
                ),
                delegate: SliverChildListDelegate([
                  // Free Plan
                  _buildPlanCard(
                    context,
                    title: 'Free',
                    price: '\$0',
                    isPopular: false,
                    features: [
                      '75 Comments per month',
                      'Basic Gold Access',
                      'Dashboard Access',
                      'No Credit Card Required',
                    ],
                    buttonText: 'Try for free',
                    onPressed: () => _selectPlan('Free'),
                    animationDelay: 400.ms,
                  ),
                  
                  // Pro Plan
                  _buildPlanCard(
                    context,
                    title: 'Pro',
                    price: _isYearly ? '\$107.91/year' : '\$9.99/month',
                    isPopular: false,
                    features: [
                      '3600 Comments per year',
                      '3 Different Tones',
                      'Customer support 3-4 business days',
                      'Multilingual support',
                    ],
                    buttonText: 'Select Package',
                    onPressed: () => _selectPlan('Pro'),
                    animationDelay: 500.ms,
                  ),
                  
                  // Gold Plan
                  _buildPlanCard(
                    context,
                    title: 'Gold',
                    price: _isYearly ? '\$134.91/year' : '\$12.49/month',
                    isPopular: true,
                    features: [
                      'All-Inclusive Pro Features',
                      '6000 Comments per year',
                      'Customer support priority (48 hours)',
                      'Proof Read',
                    ],
                    buttonText: 'Select Package',
                    onPressed: () => _selectPlan('Gold'),
                    animationDelay: 600.ms,
                  ),
                  
                  // Enterprise Plan
                  _buildPlanCard(
                    context,
                    title: 'Enterprise',
                    price: 'Contact Sales',
                    isPopular: false,
                    features: [
                      'Custom Integrations',
                      'Flexible Comment Packages',
                      'Tailored onboarding',
                      'Analytics and Reporting',
                    ],
                    buttonText: 'Contact Us',
                    onPressed: () => _selectPlan('Enterprise'),
                    animationDelay: 700.ms,
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildPlanCard(
    BuildContext context, {
    required String title,
    required String price,
    required bool isPopular,
    required List<String> features,
    required String buttonText,
    required VoidCallback onPressed,
    required Duration animationDelay,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isPopular 
            ? BorderSide(
                color: Theme.of(context).colorScheme.primary,
                width: 2,
              ) 
            : BorderSide.none,
      ),
      color: isPopular
          ? Theme.of(context).colorScheme.primary.withOpacity(isDarkMode ? 0.3 : 0.1)
          : isDarkMode
              ? Colors.grey[850]
              : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Plan title and badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (isPopular)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Best Value',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Price
            Text(
              price,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Features
            ...features.map((feature) => Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    color: Theme.of(context).colorScheme.primary,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      feature,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            )),
            
            const Spacer(),
            
            // Action button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isPopular
                      ? Theme.of(context).colorScheme.primary
                      : isDarkMode
                          ? Colors.grey[700]
                          : Colors.grey[200],
                  foregroundColor: isPopular
                      ? Colors.white
                      : Theme.of(context).colorScheme.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(buttonText),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 600.ms, delay: animationDelay);
  }
} 
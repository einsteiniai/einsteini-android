import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/models/subscription_model.dart';
import '../../../core/services/subscription_service.dart';
import '../../../core/services/location_service.dart';
import '../../../core/utils/toast_utils.dart';
import '../../../core/utils/permission_utils.dart';
import '../../../core/constants/app_constants.dart';

class SubscriptionScreen extends ConsumerStatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  ConsumerState<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends ConsumerState<SubscriptionScreen> {
  final SubscriptionService _subscriptionService = SubscriptionService();
  final LocationService _locationService = LocationService();
  SubscriptionModel? _subscription;
  bool _isLoading = true;
  bool _isYearly = true;
  bool _isIndianUser = false;

  @override
  void initState() {
    super.initState();
    _loadSubscriptionInfo();
  }

  Future<void> _loadSubscriptionInfo() async {
    setState(() => _isLoading = true);
    try {
      // Load subscription info and detect user location in parallel
      final results = await Future.wait([
        _subscriptionService.fetchSubscriptionInfo(),
        _locationService.isIndianUser(),
      ]);
      
      setState(() {
        _subscription = results[0] as SubscriptionModel?;
        _isIndianUser = results[1] as bool;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ToastUtils.showErrorToast('Failed to load subscription info');
    }
  }

  Future<void> _handlePlanSelection(String plan) async {
    try {
      // Request location permission for pricing
      bool hasLocationPermission = await PermissionUtils.checkPermissionGranted(AppPermission.location);
      if (!hasLocationPermission) {
        hasLocationPermission = await PermissionUtils.requestPermission(context, AppPermission.location);
        if (!hasLocationPermission) {
          ToastUtils.showInfoToast('Location permission helps determine accurate pricing');
          // Continue anyway - the service will handle missing location gracefully
        }
      }
      
      final checkoutUrl = await _subscriptionService.createCheckoutSession(
        plan: plan,
        referrer: 'https://app.einsteini.ai/pricing/',
      );
      
      if (checkoutUrl != null) {
        // Check if this is a Free Trial activation
        if (checkoutUrl == 'FREE_TRIAL_ACTIVATED') {
          ToastUtils.showSuccessToast('Free Trial activated successfully!');
          // Refresh the subscription info
          await _subscriptionService.fetchSubscriptionInfo();
          return;
        }
        
        // Regular Stripe checkout URL
        final uri = Uri.parse(checkoutUrl);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          ToastUtils.showErrorToast('Could not launch payment page');
        }
      } else {
        ToastUtils.showErrorToast('Failed to create checkout session');
      }
    } catch (e) {
      ToastUtils.showErrorToast('Error processing plan selection');
    }
  }

  Future<void> _handleUpgrade(String plan) async {
    try {
      // Request location permission for pricing
      bool hasLocationPermission = await PermissionUtils.checkPermissionGranted(AppPermission.location);
      if (!hasLocationPermission) {
        hasLocationPermission = await PermissionUtils.requestPermission(context, AppPermission.location);
        if (!hasLocationPermission) {
          ToastUtils.showInfoToast('Location permission helps determine accurate pricing');
          // Continue anyway - the service will handle missing location gracefully
        }
      }
      
      final upgradeUrl = await _subscriptionService.upgradePlan(
        plan,
        referrer: 'https://app.einsteini.ai/pricing/',
      );
      
      if (upgradeUrl != null) {
        final uri = Uri.parse(upgradeUrl);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          ToastUtils.showErrorToast('Could not launch upgrade page');
        }
      } else {
        ToastUtils.showErrorToast('Failed to initiate plan upgrade');
      }
    } catch (e) {
      ToastUtils.showErrorToast('Error upgrading plan');
    }
  }

  Future<void> _handleCancelSubscription() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Subscription'),
        content: const Text(
          'Are you sure you want to cancel your subscription? You will lose access to premium features at the end of your billing period.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Keep Subscription'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error
            ),
            child: const Text('Cancel Subscription'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final success = await _subscriptionService.cancelSubscription();
        if (success) {
          ToastUtils.showSuccessToast('Subscription canceled successfully');
          await _loadSubscriptionInfo();
        } else {
          ToastUtils.showErrorToast('Failed to cancel subscription');
        }
      } catch (e) {
        ToastUtils.showErrorToast('Error canceling subscription');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Subscription'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _loadSubscriptionInfo,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_subscription != null && 
                        _subscription!.product != 'No Product' && 
                        _subscription!.product.isNotEmpty) ...[
                      _buildCurrentPlanCard(),
                      const SizedBox(height: 24),
                      _buildUsageCard(),
                      const SizedBox(height: 24),
                      if (_subscription!.paymentDetails?.hasCard == true) ...[
                        _buildPaymentCard(),
                        const SizedBox(height: 24),
                      ],
                      if (_subscription!.nextInvoiceDate != null &&
                          _subscription!.nextInvoiceDate != 'No Future Invoices') ...[
                        _buildBillingCard(),
                        const SizedBox(height: 24),
                      ],
                    ],
                    _buildPlanSwitcher(),
                    const SizedBox(height: 16),
                    _buildAvailablePlans(),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildCurrentPlanCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _subscription!.isActive ? Icons.check_circle : Icons.warning,
                  color: _subscription!.isActive ? Colors.green : Colors.orange,
                ),
                const SizedBox(width: 8),
                Text(
                  'Current Plan',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _subscription!.planDisplayName,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Status: ${_subscription!.statusDisplayName}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: _subscription!.isActive ? Colors.green : Colors.orange,
                      ),
                    ),
                  ],
                ),
                if (_subscription!.hasPaidPlan && _subscription!.isActive)
                  ElevatedButton(
                    onPressed: _handleCancelSubscription,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.error,
                      foregroundColor: Theme.of(context).colorScheme.onError,
                    ),
                    child: const Text('Cancel'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUsageCard() {
    final usagePercentage = _subscription!.noc > 0
        ? ((_subscription!.noc - _subscription!.commentsRemaining) / _subscription!.noc)
        : 0.0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Usage This Period',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Comments Remaining',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                Text(
                  '${_subscription!.commentsRemaining}',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: _subscription!.hasComments ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: usagePercentage,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(
                usagePercentage > 0.8 ? Colors.red : Colors.green,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Payment Method',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.credit_card),
                const SizedBox(width: 12),
                Text(
                  _subscription!.paymentDetails!.displayCardInfo,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBillingCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Billing Information',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Next Payment',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                Text(
                  _subscription!.nextInvoiceDate!,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanSwitcher() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(25),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _isYearly = false),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: !_isYearly ? Colors.blue : Colors.transparent,
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Text(
                  'Monthly',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: !_isYearly ? Colors.white : Colors.black,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _isYearly = true),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _isYearly ? Colors.blue : Colors.transparent,
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Text(
                  'Yearly',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _isYearly ? Colors.white : Colors.black,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvailablePlans() {
    final plans = SubscriptionPlan.availablePlans;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Available Plans',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            if (!_isLoading)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.location_on,
                      size: 14,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _isIndianUser ? 'India (INR)' : 'Global (USD)',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        ...plans.map((plan) => _buildPlanCard(plan)),
      ],
    );
  }

  Widget _buildPlanCard(SubscriptionPlan plan) {
    // Only consider it current plan if subscription exists and has a valid product (not 'No Product')
    final hasValidSubscription = _subscription != null && 
        _subscription!.product != 'No Product' && 
        _subscription!.product.isNotEmpty;
    
    final isCurrentPlan = hasValidSubscription && 
        _subscription!.product.toLowerCase().contains(plan.name.toLowerCase());
    
    final canUpgrade = _subscription != null && _subscriptionService.canUpgradeTo(plan.name);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          plan.displayName,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (plan.isPopular) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orange,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'POPULAR',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                        if (isCurrentPlan) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'CURRENT',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    // Price display with slashed pricing for yearly plans
                    if (_isYearly && (plan.name == 'Pro' || plan.name == 'Gold')) ...[
                      Row(
                        children: [
                          // Slashed original price
                          Text(
                            plan.getOriginalPriceDisplay(_isYearly, isIndianUser: _isIndianUser),
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              decoration: TextDecoration.lineThrough,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Current discounted price
                          Text(
                            plan.getPriceDisplay(_isYearly, isIndianUser: _isIndianUser),
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: plan.name == 'Gold' ? Colors.orange : Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
                      // Regular price display for monthly or other plans
                      Text(
                        plan.getPriceDisplay(_isYearly, isIndianUser: _isIndianUser),
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: plan.name == 'Gold' ? Colors.orange : Colors.green,
                        ),
                      ),
                    ],
                    if (_isYearly && plan.getSavingsPercentage() > 0)
                      Text(
                        'Save ${plan.getSavingsPercentage().toStringAsFixed(0)}%',
                        style: TextStyle(
                          color: plan.name == 'Gold' ? Colors.orange : Colors.green,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
                if (!isCurrentPlan)
                  ElevatedButton(
                    onPressed: () {
                      final planName = plan.name == 'Free' 
                        ? 'Free Trial'
                        : (_isYearly 
                          ? '${plan.name} Yearly'
                          : '${plan.name} Monthly');
                      
                      if (canUpgrade) {
                        _handleUpgrade(planName);
                      } else {
                        _handlePlanSelection(planName);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: plan.name == 'Gold' ? Colors.orange : Colors.green,
                    ),
                    child: Text(
                      canUpgrade ? 'Upgrade' : 'Select',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            ...plan.features.map(
              (feature) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Icon(
                      Icons.check,
                      color: Colors.green,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(feature),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

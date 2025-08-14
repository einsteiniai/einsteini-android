import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import '../constants/app_constants.dart';
import '../utils/permission_utils.dart';
import '../models/subscription_model.dart';
import '../services/api_service.dart';

class SubscriptionService {
  static final SubscriptionService _instance = SubscriptionService._internal();
  factory SubscriptionService() => _instance;
  SubscriptionService._internal();

  final ApiService _apiService = ApiService();
  SubscriptionModel? _currentSubscription;

  /// Get current subscription from cache or fetch from API
  SubscriptionModel? get currentSubscription => _currentSubscription;

  /// Initialize subscription service
  Future<void> init() async {
    await _loadCachedSubscription();
  }

  /// Load subscription from local storage
  Future<void> _loadCachedSubscription() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final subscriptionJson = prefs.getString('cached_subscription');
      if (subscriptionJson != null) {
        // Parse and use cached subscription (you might want to add JSON parsing)
        debugPrint('Loaded cached subscription');
      }
    } catch (e) {
      debugPrint('Error loading cached subscription: $e');
    }
  }

  /// Cache subscription to local storage
  Future<void> _cacheSubscription(SubscriptionModel subscription) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('cached_subscription', subscription.toJson().toString());
    } catch (e) {
      debugPrint('Error caching subscription: $e');
    }
  }

  /// Get user email from storage
  Future<String?> _getUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_email');
  }

  /// Fetch complete subscription information
  Future<SubscriptionModel?> fetchSubscriptionInfo() async {
    final email = await _getUserEmail();
    if (email == null) {
      debugPrint('No user email found');
      return null;
    }

    try {
      // Fetch all subscription-related data concurrently
      final results = await Future.wait([
        _apiService.getProductDetails(email),
        _apiService.getCommentsRemaining(email),
        _apiService.getNextInvoiceDate(email),
        _apiService.getPaymentDetails(email),
        _apiService.getDetailedSubscriptionStatus(email),
      ]);

      final productDetails = results[0];
      final commentsInfo = results[1];
      final invoiceInfo = results[2];
      final paymentInfo = results[3];
      final statusInfo = results[4];

      final subscription = SubscriptionModel(
        status: statusInfo['status'] ?? 'inactive',
        product: productDetails['product'] ?? 'No Product',
        name: commentsInfo['name'] ?? 'User',
        daysLeft: 0, // This might need to be calculated or fetched separately
        commentsRemaining: commentsInfo['NOC'] ?? 0,
        noc: commentsInfo['NOC'] ?? 0,
        nextInvoiceDate: invoiceInfo['nextInvoice'],
        paymentDetails: PaymentDetails.fromJson(paymentInfo),
      );

      _currentSubscription = subscription;
      await _cacheSubscription(subscription);
      
      return subscription;
    } catch (e) {
      debugPrint('Error fetching subscription info: $e');
      return null;
    }
  }

  /// Get remaining comments count
  Future<int> getRemainingComments() async {
    final email = await _getUserEmail();
    if (email == null) return 0;

    try {
      final result = await _apiService.getCommentsRemaining(email);
      return result['NOC'] ?? 0;
    } catch (e) {
      debugPrint('Error getting remaining comments: $e');
      return 0;
    }
  }

  /// Check if user can generate comments
  Future<bool> canGenerateComments() async {
    final remaining = await getRemainingComments();
    return remaining > 0;
  }

  /// Use a comment (decrement count)
  Future<bool> useComment() async {
    final remaining = await getRemainingComments();
    if (remaining <= 0) return false;

    // The backend should handle decrementing on actual comment generation
    // This is just a local check
    return true;
  }

  /// Create checkout session for subscription
  Future<String?> createCheckoutSession({
    required String plan,
    String? referrer,
  }) async {
    final email = await _getUserEmail();
    if (email == null) return null;

    try {
      // Validate plan name against backend supported plans
      final validPlans = ['Free Trial', 'Pro Monthly', 'Pro Yearly', 'Gold Monthly', 'Gold Yearly'];
      if (!validPlans.contains(plan)) {
        debugPrint('Invalid plan name: $plan. Supported plans: $validPlans');
        return null;
      }

      // Get user location for pricing
      Position? position;
      try {
        // Check and request location permission
        bool hasPermission = await PermissionUtils.checkPermissionGranted(AppPermission.location);
        if (!hasPermission) {
          debugPrint('Location permission not granted, attempting to request...');
          // Note: We can't request permission here without context, but we'll try to get location anyway
          // The permission should be requested in the UI before calling this method
        }
        position = await Geolocator.getCurrentPosition();
      } catch (e) {
        debugPrint('Could not get location: $e');
      }

      final result = await _apiService.createCheckoutSession(
        email: email,
        plan: plan,
        latitude: position?.latitude,
        longitude: position?.longitude,
        referrer: referrer ?? 'https://app.einsteini.ai/pricing/',
      );

      debugPrint('Checkout session result: $result');

      if (result['success'] == true) {
        // Check if this is a Free Trial activation (no URL, just message)
        if (result['url'] == null || result['url'].toString().isEmpty) {
          final message = result['message'] ?? '';
          if (message.contains('Free Trial Activated') || 
              message.contains('Subscription already exists')) {
            // For Free Trial, the backend doesn't return a URL but a success message
            debugPrint('Free Trial handled successfully: $message');
            return 'FREE_TRIAL_ACTIVATED'; // Special return value to indicate success
          }
        }
        // Regular Stripe checkout session with URL
        return result['url'];
      } else {
        
        debugPrint('Checkout session creation failed: ${result['message']}');
        return null;
      }
    } catch (e) {
      debugPrint('Error creating checkout session: $e');
      return null;
    }
  }

  /// Upgrade subscription plan
  Future<String?> upgradePlan(String plan, {String? referrer}) async {
    final email = await _getUserEmail();
    if (email == null) return null;

    try {
      // Get user location for pricing
      Position? position;
      try {
        // Check and request location permission
        bool hasPermission = await PermissionUtils.checkPermissionGranted(AppPermission.location);
        if (!hasPermission) {
          debugPrint('Location permission not granted, attempting to request...');
          // Note: We can't request permission here without context, but we'll try to get location anyway
          // The permission should be requested in the UI before calling this method
        }
        position = await Geolocator.getCurrentPosition();
      } catch (e) {
        debugPrint('Could not get location: $e');
      }

      final result = await _apiService.upgradePlan(
        email: email,
        plan: plan,
        latitude: position?.latitude,
        longitude: position?.longitude,
        referrer: referrer ?? 'https://app.einsteini.ai/pricing/',
      );

      if (result['success'] == true) {
        // Refresh subscription info after upgrade
        await fetchSubscriptionInfo();
        return result['url'];
      } else {
        debugPrint('Plan upgrade failed: ${result['message']}');
        return null;
      }
    } catch (e) {
      debugPrint('Error upgrading plan: $e');
      return null;
    }
  }

  /// Cancel subscription
  Future<bool> cancelSubscription() async {
    final email = await _getUserEmail();
    if (email == null) return false;

    try {
      final result = await _apiService.deactivateSubscription(email);
      
      if (result['success'] == true) {
        // Refresh subscription info after cancellation
        await fetchSubscriptionInfo();
        return true;
      } else {
        debugPrint('Subscription cancellation failed: ${result['message']}');
        return false;
      }
    } catch (e) {
      debugPrint('Error canceling subscription: $e');
      return false;
    }
  }

  /// Get subscription plans with current user's plan highlighted
  List<SubscriptionPlan> getAvailablePlans() {
    return SubscriptionPlan.availablePlans;
  }

  /// Check if current plan can be upgraded to target plan
  bool canUpgradeTo(String targetPlan) {
    if (_currentSubscription == null) return true;
    
    final currentProduct = _currentSubscription!.product;
    
    // Define upgrade hierarchy
    const planHierarchy = {
      'Free Trial': 0,
      'Pro Monthly': 1,
      'Pro Yearly': 1,
      'Gold Monthly': 2,
      'Gold Yearly': 2,
      'Enterprise': 3,
    };

    final currentLevel = planHierarchy[currentProduct] ?? 0;
    final targetLevel = planHierarchy[targetPlan] ?? 0;
    
    return targetLevel > currentLevel;
  }

  /// Get plan recommendation based on usage
  SubscriptionPlan? getRecommendedPlan() {
    if (_currentSubscription == null) {
      return SubscriptionPlan.availablePlans.first; // Free plan
    }

    final commentsUsed = _currentSubscription!.noc - _currentSubscription!.commentsRemaining;
    
    // If user is using more than 75% of comments, suggest upgrade
    if (commentsUsed > (_currentSubscription!.noc * 0.75)) {
      final plans = SubscriptionPlan.availablePlans;
      for (final plan in plans) {
        if (canUpgradeTo(plan.name)) {
          return plan;
        }
      }
    }
    
    return null;
  }

  /// Clear cached subscription data
  Future<void> clearCache() async {
    _currentSubscription = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('cached_subscription');
  }

  /// Refresh subscription information
  Future<SubscriptionModel?> refresh() async {
    return await fetchSubscriptionInfo();
  }
}

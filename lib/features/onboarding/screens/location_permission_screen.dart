import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:einsteiniapp/core/routes/app_router.dart' as router;
import 'package:einsteiniapp/core/utils/permission_utils.dart';
import 'package:einsteiniapp/core/constants/app_constants.dart';
import 'package:einsteiniapp/core/utils/toast_utils.dart';

class LocationPermissionScreen extends StatefulWidget {
  const LocationPermissionScreen({Key? key}) : super(key: key);

  @override
  State<LocationPermissionScreen> createState() => _LocationPermissionScreenState();
}

class _LocationPermissionScreenState extends State<LocationPermissionScreen> {
  bool _isPermissionGranted = false;
  bool _isChecking = false;
  Timer? _checkTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkPermission();
    });
  }

  @override
  void dispose() {
    _checkTimer?.cancel();
    super.dispose();
  }

  Future<void> _savePermissionState(bool granted) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('location_permission_granted', granted);
  }

  Future<void> _checkPermission() async {
    setState(() {
      _isChecking = true;
    });

    final hasPermission = await PermissionUtils.checkPermissionGranted(AppPermission.location);
    
    await _savePermissionState(hasPermission);
    
    setState(() {
      _isPermissionGranted = hasPermission;
      _isChecking = false;
    });
    
    if (_isPermissionGranted) {
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          _completeOnboarding();
        }
      });
    }
  }

  Future<void> _requestPermission() async {
    setState(() {
      _isChecking = true;
    });

    try {
      final granted = await PermissionUtils.requestPermission(context, AppPermission.location);
      
      await _savePermissionState(granted);
      
      setState(() {
        _isPermissionGranted = granted;
        _isChecking = false;
      });

      if (granted) {
        ToastUtils.showSuccessToast('Location permission granted!');
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) {
            _completeOnboarding();
          }
        });
      } else {
        ToastUtils.showInfoToast('You can grant location permission later in settings');
        // Still complete onboarding even if permission is denied
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) {
            _completeOnboarding();
          }
        });
      }
    } catch (e) {
      setState(() {
        _isChecking = false;
      });
      ToastUtils.showErrorToast('Error requesting location permission');
    }
  }

  Future<void> _skipPermission() async {
    await _savePermissionState(false);
    ToastUtils.showInfoToast('You can enable location permission later in settings');
    _completeOnboarding();
  }

  Future<void> _completeOnboarding() async {
    // Mark onboarding as completed
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.hasCompletedOnboardingKey, true);
    
    if (mounted) {
      context.go(router.AppRoutes.auth);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Setup einsteini.ai'),
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 240,
                          height: 240,
                          margin: const EdgeInsets.symmetric(vertical: 32),
                          child: Lottie.asset(
                            'assets/animations/accessibility_permission.json',
                            fit: BoxFit.contain,
                          ),
                        ),
                      ).animate().fadeIn(duration: 600.ms),
                      
                      Text(
                        'Location Permission',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ).animate().fadeIn(duration: 600.ms, delay: 300.ms),
                      
                      const SizedBox(height: 16),
                      
                      Text(
                        'We use your location to provide accurate regional pricing and better personalized content for your area.',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          height: 1.5,
                        ),
                      ).animate().fadeIn(duration: 600.ms, delay: 400.ms),
                      
                      const SizedBox(height: 32),
                      
                      _buildPermissionItem(
                        context,
                        title: 'Regional Pricing',
                        description: 'Get accurate pricing tailored to your local market',
                        icon: Icons.attach_money,
                      ).animate().fadeIn(duration: 600.ms, delay: 500.ms),
                      
                      const SizedBox(height: 24),
                      
                      _buildPermissionItem(
                        context,
                        title: 'Local Content',
                        description: 'Receive region-specific suggestions and trends',
                        icon: Icons.location_on,
                      ).animate().fadeIn(duration: 600.ms, delay: 600.ms),
                      
                      const SizedBox(height: 24),
                      
                      _buildPermissionItem(
                        context,
                        title: 'Better Experience',
                        description: 'Enjoy a more personalized and relevant experience',
                        icon: Icons.star,
                      ).animate().fadeIn(duration: 600.ms, delay: 700.ms),
                      
                      const SizedBox(height: 16),

                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Your location data is only used for pricing and content personalization. We respect your privacy.',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ),
                          ],
                        ),
                      ).animate().fadeIn(duration: 600.ms, delay: 800.ms),
                      
                      if (_isPermissionGranted)
                        Container(
                          margin: const EdgeInsets.only(top: 16),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.check_circle,
                                color: Colors.green,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Location permission granted! Setting up your personalized experience.',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Colors.green,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ).animate().fadeIn(duration: 300.ms),
                    ],
                  ),
                ),
              ),
              
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Column(
                  children: [
                    _isChecking
                      ? const Center(child: CircularProgressIndicator())
                      : SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isPermissionGranted 
                              ? _completeOnboarding
                              : _requestPermission,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: Text(_isPermissionGranted ? 'Continue' : 'Grant Permission'),
                          ),
                        ),
                    
                    const SizedBox(height: 12),
                    
                    if (!_isPermissionGranted)
                      TextButton(
                        onPressed: _skipPermission,
                        child: const Text('Skip for Now'),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPermissionItem(BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: Theme.of(context).colorScheme.primary,
            size: 24,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
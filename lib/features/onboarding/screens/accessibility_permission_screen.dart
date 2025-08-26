import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:einsteiniapp/core/routes/app_router.dart' as router;

class AccessibilityPermissionScreen extends StatefulWidget {
  const AccessibilityPermissionScreen({super.key});

  @override
  State<AccessibilityPermissionScreen> createState() => _AccessibilityPermissionScreenState();
}

class _AccessibilityPermissionScreenState extends State<AccessibilityPermissionScreen> {

  @override
  void initState() {
    super.initState();
    // Automatically skip the accessibility screen
    _skipPermission();
  }

  void _skipPermission() async {
    // Directly navigate to the next screen
    if (mounted) {
      context.go(router.AppRoutes.themeSelection);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Setup einsteini.ai'),
        elevation: 0,
      ),
      body: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  // Original implementation commented out
  /*
  bool _isPermissionGranted = false;
  bool _isChecking = false;
  Timer? _checkTimer;

  @override
  void initState() {
    super.initState();
    _checkPermission();
  }

  @override
  void dispose() {
    _checkTimer?.cancel();
    super.dispose();
  }

  Future<void> _savePermissionState(bool granted) async {
    // Save permission state directly
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('accessibility_granted', granted);
    await prefs.setBool('accessibility_permission_granted', granted); // For backward compatibility
  }

  Future<void> _checkPermission() async {
    setState(() {
      _isChecking = true;
    });

    final hasPermission = await PlatformChannel.checkAccessibilityPermission();
    
    // Save permission state
    await _savePermissionState(hasPermission);
    
    setState(() {
      _isPermissionGranted = hasPermission;
      _isChecking = false;
    });
    
    // If permission is already granted, automatically proceed after a short delay
    if (_isPermissionGranted) {
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          context.go(router.AppRoutes.themeSelection);
        }
      });
    } else {
      // Start continuous checking for permission changes every 500ms
      // to detect changes faster when the user returns from Settings
      _checkTimer = Timer.periodic(const Duration(milliseconds: 500), (_) async {
        final permissionStatus = await PlatformChannel.checkAccessibilityPermission();
        if (permissionStatus && mounted) {
          // Save permission state
          await _savePermissionState(true);
          
          setState(() {
            _isPermissionGranted = true;
          });
          _checkTimer?.cancel();
          
          // Immediately navigate to theme selection when permission is granted
          if (mounted) {
            context.go(router.AppRoutes.themeSelection);
          }
        }
      });
    }
  }

  Future<void> _requestPermission() async {
    // Show the accessibility permission explanation dialog
    PermissionUtils.showAccessibilityPermissionExplanation(
      context,
      onAgree: () async {
        // User agreed to the permission, open accessibility settings
    await PlatformChannel.openAccessibilitySettings();
    // Permission checking will continue with the timer
      },
      onDisagree: () {
        // User disagreed, do nothing or show a message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Accessibility permission is required for full functionality'),
            duration: Duration(seconds: 3),
          ),
        );
      },
    );
  }

  void _skipPermission() async {
    // Mark as intentionally skipped
    await _savePermissionState(false);
    context.go(router.AppRoutes.themeSelection);
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
                        'Accessibility Services',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ).animate().fadeIn(duration: 600.ms, delay: 300.ms),
                      
                      const SizedBox(height: 16),
                      
                      Text(
                        'einsteini.ai needs accessibility permission to analyze LinkedIn content and help you create engaging comments and posts that grow your professional network.',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          height: 1.5,
                        ),
                      ).animate().fadeIn(duration: 600.ms, delay: 400.ms),
                      
                      const SizedBox(height: 32),
                      
                      _buildPermissionItem(
                        context,
                        title: 'Smart Content Analysis',
                        description: 'Get personalized suggestions based on LinkedIn posts',
                        icon: Icons.analytics,
                      ).animate().fadeIn(duration: 600.ms, delay: 500.ms),
                      
                      const SizedBox(height: 24),
                      
                      _buildPermissionItem(
                        context,
                        title: 'Engagement Optimization',
                        description: 'Create comments that boost your visibility',
                        icon: Icons.visibility,
                      ).animate().fadeIn(duration: 600.ms, delay: 600.ms),
                      
                      const SizedBox(height: 24),
                      
                      _buildPermissionItem(
                        context,
                        title: 'Private & Secure',
                        description: 'Your LinkedIn data never leaves your device',
                        icon: Icons.lock,
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
                                'You will be directed to your device settings. Look for "einsteini.ai" in the services list and toggle it ON.',
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
                                  'Permission Granted! Continue to the next step.',
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
                      : Row(
                          children: [
                            Expanded(
                          child: ElevatedButton(
                                onPressed: _isPermissionGranted ? null : _requestPermission,
                            style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.all(16),
                                  backgroundColor: Theme.of(context).colorScheme.primary,
                                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                                  disabledBackgroundColor: Colors.grey,
                            ),
                                child: Text(_isPermissionGranted
                                  ? 'Permission Granted'
                                  : 'Enable Accessibility',
                                  style: const TextStyle(fontSize: 16),
                          ),
                        ),
                            ),
                          ],
                        ),
                    const SizedBox(height: 8),
                      TextButton(
                        onPressed: _skipPermission,
                      child: const Text('Skip for now'),
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

  Widget _buildPermissionItem(
    BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark
            ? Colors.grey[800]!
            : Colors.grey[300]!,
          width: 1,
        ),
          ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 24,
            color: Theme.of(context).colorScheme.secondary,
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
                  style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ],
      ),
    );
  }
  */
} 
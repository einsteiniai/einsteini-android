import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:einsteiniapp/core/constants/app_constants.dart';
import 'package:einsteiniapp/core/routes/app_router.dart' as router;
import 'package:einsteiniapp/core/widgets/app_logo.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
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
                          margin: const EdgeInsets.only(top: 40, bottom: 40),
                          child: const AppLogo(
                            size: 100,
                            padding: 12,
                          ),
                        ),
                      ).animate().fadeIn(duration: 600.ms),
                      
                      Text(
                        'Welcome to\neinsteini.ai',
                        style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          height: 1.2,
                        ),
                      ).animate().fadeIn(duration: 600.ms, delay: 300.ms),
                      
                      const SizedBox(height: 24),
                      
                      Text(
                        AppConstants.appTagline,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          height: 1.5,
                        ),
                      ).animate().fadeIn(duration: 600.ms, delay: 400.ms),
                      
                      const SizedBox(height: 40),
                      
                      _buildFeatureItem(
                        context,
                        icon: Icons.comment,
                        title: 'AI-Powered Comments',
                        description: 'Generate intelligent, engaging LinkedIn comments in seconds',
                      ).animate().fadeIn(duration: 600.ms, delay: 500.ms),
                      
                      const SizedBox(height: 24),
                      
                      _buildFeatureItem(
                        context,
                        icon: Icons.trending_up,
                        title: 'Grow Your Presence',
                        description: 'Increase profile views and expand your professional network',
                      ).animate().fadeIn(duration: 600.ms, delay: 600.ms),
                      
                      const SizedBox(height: 24),
                      
                      _buildFeatureItem(
                        context,
                        icon: Icons.timer,
                        title: 'Save Time',
                        description: 'Create professional content directly within LinkedIn',
                      ).animate().fadeIn(duration: 600.ms, delay: 700.ms),
                    ],
                  ),
                ),
              ),
              
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      context.go(router.AppRoutes.overlayPermission);
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Get Started'),
                  ),
                ),
              ).animate().fadeIn(duration: 600.ms, delay: 800.ms),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem(BuildContext context, {
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
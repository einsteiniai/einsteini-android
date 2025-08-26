import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

class TutorialScreen extends StatefulWidget {
  const TutorialScreen({super.key});

  @override
  State<TutorialScreen> createState() => _TutorialScreenState();
}

class _TutorialScreenState extends State<TutorialScreen> {
  int _currentPage = 0;
  final PageController _pageController = PageController();

  final List<TutorialStep> _tutorialSteps = [
    TutorialStep(
      icon: Icons.home,
      title: 'Welcome to einsteini.ai',
      description: 'Your intelligent LinkedIn AI companion that helps you create engaging content, analyze posts, and grow your professional network.',
      tips: [
        'Navigate through the app using the bottom navigation bar',
        'Access quick actions from the home screen',
        'Use the hamburger menu for additional features',
      ],
    ),
    TutorialStep(
      icon: Icons.auto_awesome,
      title: 'AI Assistant',
      description: 'Powerful AI tools to enhance your LinkedIn presence and engagement.',
      tips: [
        'Analyze any LinkedIn post for insights and engagement opportunities',
        'Generate professional comments tailored to your style',
        'Create compelling posts with AI assistance',
        'Generate personalized "About Me" sections',
        'Translate content to different languages',
        'Summarize long posts for quick understanding',
      ],
    ),
    TutorialStep(
      icon: Icons.search,
      title: 'Analyzing Posts',
      description: 'Learn how to analyze LinkedIn posts for maximum engagement.',
      tips: [
        'Copy any LinkedIn post URL and paste it in the AI Assistant',
        'Choose your analysis type: Comment, Post, About Me, Translate, or Summarize',
        'Select your preferred tone: Professional, Casual, Expert, or Supportive',
        'Pick the style that matches your industry and personality',
        'Generate multiple variations and choose the best one',
      ],
    ),
    TutorialStep(
      icon: Icons.comment,
      title: 'Creating Comments',
      description: 'Generate engaging comments that build meaningful connections.',
      tips: [
        'Select "Comment" from the AI Assistant options',
        'Choose your tone based on the post context',
        'Pick an industry-specific style for better relevance',
        'Review and customize the generated comment',
        'Copy and paste directly to LinkedIn',
      ],
    ),
    TutorialStep(
      icon: Icons.post_add,
      title: 'Creating Posts',
      description: 'Create compelling LinkedIn posts that drive engagement.',
      tips: [
        'Use "Post" option to generate original content',
        'Input your topic or paste content for inspiration',
        'Select appropriate tone and style for your audience',
        'Generate multiple variations to find the perfect post',
        'Include relevant hashtags and calls-to-action',
      ],
    ),
    TutorialStep(
      icon: Icons.person,
      title: 'About Me Generator',
      description: 'Create a professional and engaging LinkedIn "About" section.',
      tips: [
        'Choose "About Me" from the AI Assistant',
        'Input your professional background and goals',
        'Select a tone that reflects your personality',
        'Generate a compelling summary that highlights your value',
        'Update your LinkedIn profile with the generated content',
      ],
    ),
    TutorialStep(
      icon: Icons.layers,
      title: 'Overlay Feature',
      description: 'Access AI assistance directly within the LinkedIn app.',
      tips: [
        'Enable overlay permission in settings',
        'The overlay appears when you\'re browsing LinkedIn',
        'Quickly analyze posts without switching apps',
        'Generate comments instantly while viewing content',
        'Toggle overlay on/off from the home screen',
      ],
    ),
    TutorialStep(
      icon: Icons.history,
      title: 'History & Analytics',
      description: 'Track your AI-generated content and analyze your usage patterns.',
      tips: [
        'View all your previously analyzed posts',
        'Re-analyze posts with different settings',
        'Search through your history by keywords',
        'Track your most used features and styles',
        'Export or share your generated content',
      ],
    ),
    TutorialStep(
      icon: Icons.settings,
      title: 'Settings & Customization',
      description: 'Personalize your experience and manage your preferences.',
      tips: [
        'Set your default comment style and tone',
        'Manage notification preferences',
        'Configure LinkedIn account connection',
        'Customize theme and appearance',
        'Manage subscription and billing',
      ],
    ),
    TutorialStep(
      icon: Icons.tips_and_updates,
      title: 'Pro Tips for Success',
      description: 'Master these techniques to maximize your LinkedIn engagement.',
      tips: [
        'Always personalize AI-generated content to match your voice',
        'Engage authentically - add your own insights to generated comments',
        'Use different tones for different types of posts and audiences',
        'Analyze successful posts to understand what works in your industry',
        'Combine multiple AI features for comprehensive content strategy',
        'Regular posting and commenting builds stronger professional relationships',
      ],
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _handleBackNavigation(BuildContext context, bool isNewUser) {
    if (isNewUser) {
      // For new users, go to plans screen
      context.go('/subscription');
    } else {
      // For existing users accessing from menu, check if we can pop
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/home');
      }
    }
  }

  void _handleSkip(BuildContext context, bool isNewUser) {
    if (isNewUser) {
      // For new users, go to plans screen
      context.go('/subscription');
    } else {
      // For existing users accessing from menu, check if we can pop
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/home');
      }
    }
  }

  void _handleGetStarted(BuildContext context, bool isNewUser) {
    if (isNewUser) {
      // For new users, go to plans screen after tutorial
      context.go('/subscription');
    } else {
      // For existing users accessing from menu, check if we can pop
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/home');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
  // Check if this is a new user
  final routerState = GoRouterState.of(context);
  final isNewUser = routerState.uri.toString().contains('isNewUser=true');
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('How to Use einsteini.ai'),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => _handleBackNavigation(context, isNewUser),
        ),
        actions: [
          TextButton(
            onPressed: () => _handleSkip(context, isNewUser),
            child: const Text('Skip'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Progress indicator
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: LinearProgressIndicator(
                    value: (_currentPage + 1) / _tutorialSteps.length,
                    backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  '${_currentPage + 1} of ${_tutorialSteps.length}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          
          // Tutorial content
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
              },
              itemCount: _tutorialSteps.length,
              itemBuilder: (context, index) {
                return _buildTutorialPage(_tutorialSteps[index]);
              },
            ),
          ),
          
          // Navigation buttons
          Container(
            padding: const EdgeInsets.all(24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (_currentPage > 0)
                  OutlinedButton.icon(
                    onPressed: () {
                      _pageController.previousPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                    icon: const Icon(Icons.arrow_back_ios),
                    label: const Text('Previous'),
                  )
                else
                  const SizedBox(width: 100),
                
                if (_currentPage < _tutorialSteps.length - 1)
                  ElevatedButton.icon(
                    onPressed: () {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                    icon: const Icon(Icons.arrow_forward_ios),
                    label: const Text('Next'),
                  )
                else
                  ElevatedButton(
                    onPressed: () => _handleGetStarted(context, isNewUser),
                    child: const Text('Get Started'),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTutorialPage(TutorialStep step) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon
          Center(
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                step.icon,
                size: 60,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),
          
          const SizedBox(height: 32),
          
          // Title
          Text(
            step.title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(duration: 600.ms, delay: 200.ms),
          
          const SizedBox(height: 16),
          
          // Description
          Text(
            step.description,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(duration: 600.ms, delay: 400.ms),
          
          const SizedBox(height: 32),
          
          // Tips
          if (step.tips.isNotEmpty) ...[
            Text(
              'Key Features & Tips:',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ).animate().fadeIn(duration: 600.ms, delay: 600.ms),
            
            const SizedBox(height: 16),
            
            ...step.tips.asMap().entries.map((entry) {
              final index = entry.key;
              final tip = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      margin: const EdgeInsets.only(top: 8, right: 12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        tip,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(
                duration: 600.ms, 
                delay: Duration(milliseconds: 800 + (index * 100)),
              );
            }),
          ],
        ],
      ),
    );
  }
}

class TutorialStep {
  final IconData icon;
  final String title;
  final String description;
  final List<String> tips;

  TutorialStep({
    required this.icon,
    required this.title,
    required this.description,
    required this.tips,
  });
}

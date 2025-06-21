import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:einsteiniapp/core/constants/app_constants.dart';
import 'package:einsteiniapp/core/routes/app_router.dart';
import 'package:einsteiniapp/core/widgets/custom_app_bar.dart';
import 'package:einsteiniapp/core/utils/toast_utils.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _jobTitleController = TextEditingController();
  final _companyController = TextEditingController();
  final _bioController = TextEditingController();
  final _linkedInController = TextEditingController();
  final _twitterController = TextEditingController();
  bool _isLoading = false;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _jobTitleController.dispose();
    _companyController.dispose();
    _bioController.dispose();
    _linkedInController.dispose();
    _twitterController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _nameController.text = prefs.getString('user_name') ?? 'LinkedIn User';
      _jobTitleController.text = prefs.getString('user_job_title') ?? 'LinkedIn Professional';
      _companyController.text = prefs.getString('user_company') ?? 'Company';
      _bioController.text = prefs.getString('user_bio') ?? 'I use einsteini.ai to create engaging LinkedIn content that helps me grow my professional network.';
      _linkedInController.text = prefs.getString('user_linkedin') ?? 'linkedin.com/in/username';
      _twitterController.text = prefs.getString('user_twitter') ?? '@username';
    });
  }

  Future<void> _saveUserData() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_name', _nameController.text);
      await prefs.setString('user_job_title', _jobTitleController.text);
      await prefs.setString('user_company', _companyController.text);
      await prefs.setString('user_bio', _bioController.text);
      await prefs.setString('user_linkedin', _linkedInController.text);
      await prefs.setString('user_twitter', _twitterController.text);

      if (mounted) {
        ToastUtils.showSuccessToast('Profile updated successfully');
        setState(() {
          _isEditing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ToastUtils.showErrorToast('Error saving profile: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final logoImage = isDarkMode ? 'assets/images/einsteini_white.png' : 'assets/images/einsteini_black.png';

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Profile',
        showBackButton: true,
        showDrawerButton: false,
        centerTitle: false,
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.close : Icons.edit),
            onPressed: () {
              setState(() {
                _isEditing = !_isEditing;
                if (!_isEditing) {
                  // Reload data if canceling edit
                  _loadUserData();
                }
              });
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Header
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    child: Text(
                      _nameController.text.isNotEmpty ? _nameController.text[0].toUpperCase() : 'U',
                      style: const TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (!_isEditing) ...[
                    Text(
                      _nameController.text,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_jobTitleController.text} at ${_companyController.text}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _bioController.text,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 24),
                    // Social Links
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildSocialButton(
                          icon: Icons.link,
                          label: 'LinkedIn',
                          onPressed: () {
                            // Open LinkedIn profile
                          },
                        ),
                        const SizedBox(width: 16),
                        _buildSocialButton(
                          icon: Icons.chat_bubble,
                          label: 'Twitter',
                          onPressed: () {
                            // Open Twitter profile
                          },
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            
            const SizedBox(height: 32),

            // Edit Form
            if (_isEditing)
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Name',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _jobTitleController,
                      decoration: const InputDecoration(
                        labelText: 'Job Title',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your job title';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _companyController,
                      decoration: const InputDecoration(
                        labelText: 'Company',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your company';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _bioController,
                      decoration: const InputDecoration(
                        labelText: 'Bio',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 4,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your bio';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _linkedInController,
                      decoration: const InputDecoration(
                        labelText: 'LinkedIn Profile URL',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.link),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _twitterController,
                      decoration: const InputDecoration(
                        labelText: 'Twitter Handle',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.chat_bubble),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _saveUserData,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Save Profile'),
                      ),
                    ),
                  ],
                ),
              ),

            if (!_isEditing) ...[
              // Activity Section
              const Divider(height: 32),
              
              Text(
                'Recent Activity',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              const SizedBox(height: 16),
              
              _buildActivityItem(
                title: 'Posted: "5 Tips for Better LinkedIn Engagement"',
                time: '2 days ago',
                engagement: '56 likes • 8 comments',
              ),
              
              _buildActivityItem(
                title: 'Commented on "The Future of AI in Marketing"',
                time: '3 days ago',
                engagement: '12 likes',
              ),
              
              _buildActivityItem(
                title: 'Shared an article: "Digital Transformation in 2024"',
                time: '1 week ago',
                engagement: '34 likes • 5 comments',
              ),
              
              const SizedBox(height: 16),
              
              Center(
                child: TextButton(
                  onPressed: () {
                    // View all activity
                  },
                  child: const Text('View All Activity'),
                ),
              ),
              
              // Stats Section
              const Divider(height: 32),
              
              Text(
                'Engagement Stats',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              const SizedBox(height: 16),
              
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      title: 'Posts',
                      value: '24',
                      icon: Icons.post_add,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatCard(
                      title: 'Comments',
                      value: '86',
                      icon: Icons.comment,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatCard(
                      title: 'Likes',
                      value: '342',
                      icon: Icons.thumb_up,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  Widget _buildSocialButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }
  
  Widget _buildActivityItem({
    required String title,
    required String time,
    required String engagement,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  time,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                Text(
                  engagement,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: Theme.of(context).colorScheme.primary,
            size: 28,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
} 
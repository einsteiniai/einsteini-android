import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:einsteiniapp/core/constants/app_constants.dart';
import 'package:einsteiniapp/core/theme/theme_provider.dart';
import 'package:einsteiniapp/core/widgets/custom_app_bar.dart';
import 'package:einsteiniapp/core/utils/toast_utils.dart';
import '../widgets/overlay_control.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  String _selectedTheme = 'System Default';
  bool _notificationsEnabled = true;
  bool _dailyReminderEnabled = false;
  bool _autoStartEnabled = true;
  bool _savePostDrafts = true;
  bool _linkedInSyncEnabled = true;
  bool _commentSuggestionsEnabled = true;
  bool _postSuggestionsEnabled = true;
  String _language = 'English (US)';
  bool _isOverlayServiceEnabled = false;
  
  // Define state variables for loading states
  bool _isRefreshingLinkedIn = false;
  bool _isClearingCache = false;
  bool _isDeletingAccount = false;
  bool _isReconnectingLinkedIn = false;
  bool _isUpdatingLinkedIn = false;
  
  // Time pickers
  TimeOfDay _morningReminderTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _weeklySummaryTime = const TimeOfDay(hour: 18, minute: 0);
  
  @override
  void initState() {
    super.initState();
    _loadSettings();
  }
  
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
      _dailyReminderEnabled = prefs.getBool('daily_reminder_enabled') ?? false;
      _autoStartEnabled = prefs.getBool('auto_post_enabled') ?? true;
      _savePostDrafts = prefs.getBool('save_post_drafts') ?? true;
      _linkedInSyncEnabled = prefs.getBool('linkedin_sync_enabled') ?? true;
      _commentSuggestionsEnabled = prefs.getBool('comment_suggestions_enabled') ?? true;
      _postSuggestionsEnabled = prefs.getBool('post_suggestions_enabled') ?? true;
      _language = prefs.getString('language') ?? 'English (US)';
      _isOverlayServiceEnabled = prefs.getBool('overlay_service_enabled') ?? false;
    });
  }
  
  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', _notificationsEnabled);
    await prefs.setBool('daily_reminder_enabled', _dailyReminderEnabled);
    await prefs.setBool('auto_post_enabled', _autoStartEnabled);
    await prefs.setBool('save_post_drafts', _savePostDrafts);
    await prefs.setBool('linkedin_sync_enabled', _linkedInSyncEnabled);
    await prefs.setBool('comment_suggestions_enabled', _commentSuggestionsEnabled);
    await prefs.setBool('post_suggestions_enabled', _postSuggestionsEnabled);
    await prefs.setString('language', _language);
    await prefs.setBool('overlay_service_enabled', _isOverlayServiceEnabled);
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeProvider);
    final themeNotifier = ref.read(themeProvider.notifier);
    
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Settings',
        showBackButton: true,
        showDrawerButton: false,
        centerTitle: false,
        showSettingsButton: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Theme Settings
          _buildSectionHeader('Appearance'),
          _buildThemeSelector(themeMode, themeNotifier),
          const Divider(),
          
          // LinkedIn Integration Settings
          _buildSectionHeader('LinkedIn Integration'),
          SwitchListTile(
            title: const Text('LinkedIn Account Sync'),
            subtitle: const Text('Keep your LinkedIn profile data in sync'),
            value: _linkedInSyncEnabled,
            onChanged: (value) {
              setState(() {
                _linkedInSyncEnabled = value;
                _saveSettings();
              });
            },
          ),
          ListTile(
            title: const Text('LinkedIn Account'),
            subtitle: const Text('linkedin.com/in/username'),
            trailing: TextButton(
              onPressed: () {
                _showLinkedInAccountDialog();
              },
              child: const Text('Change'),
            ),
          ),
          ListTile(
            title: const Text('Refresh LinkedIn Connection'),
            subtitle: const Text('Update your connection with LinkedIn'),
            trailing: const Icon(Icons.refresh),
            onTap: () {
              _refreshLinkedInConnection();
            },
          ),
          const Divider(),
          
          // AI Assistant Settings
          _buildSectionHeader('AI Assistant'),
          ListTile(
            title: const Text('Comment Style'),
            subtitle: Text(_language),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => _showCommentStyleDialog(),
          ),
          SwitchListTile(
            title: const Text('Comment Suggestions'),
            subtitle: const Text('Receive AI-generated comment suggestions'),
            value: _commentSuggestionsEnabled,
            onChanged: (value) {
              setState(() {
                _commentSuggestionsEnabled = value;
                _saveSettings();
              });
            },
          ),
          SwitchListTile(
            title: const Text('Post Suggestions'),
            subtitle: const Text('Receive AI-generated post suggestions'),
            value: _postSuggestionsEnabled,
            onChanged: (value) {
              setState(() {
                _postSuggestionsEnabled = value;
                _saveSettings();
              });
            },
          ),
          ListTile(
            title: const Text('Post Frequency'),
            subtitle: Text(_language),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => _showPostFrequencyDialog(),
          ),
          SwitchListTile(
            title: const Text('Save Post Drafts'),
            subtitle: const Text('Automatically save drafts of your posts'),
            value: _savePostDrafts,
            onChanged: (value) {
              setState(() {
                _savePostDrafts = value;
                _saveSettings();
              });
            },
          ),
          const Divider(),
          
          // Notification Settings
          _buildSectionHeader('Notifications'),
          SwitchListTile(
            title: const Text('Enable Notifications'),
            subtitle: const Text('Receive alerts for new engagement opportunities'),
            value: _notificationsEnabled,
            onChanged: (value) {
              setState(() {
                _notificationsEnabled = value;
                _saveSettings();
              });
            },
          ),
          SwitchListTile(
            title: const Text('Daily Engagement Reminder'),
            subtitle: const Text('Receive a daily reminder to engage on LinkedIn'),
            value: _dailyReminderEnabled,
            onChanged: (value) {
              setState(() {
                _dailyReminderEnabled = value;
                _saveSettings();
              });
            },
          ),
          ListTile(
            title: const Text('Notification Schedule'),
            subtitle: const Text('Set when you want to receive notifications'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              _showNotificationScheduleDialog();
            },
          ),
          const Divider(),
          
          // Accessibility & Overlay Features
          _buildSectionHeader('Accessibility & Overlay'),
          const OverlayControl(),
          const Divider(),
          
          // Language Settings
          _buildSectionHeader('Language'),
          ListTile(
            title: const Text('App Language'),
            subtitle: Text(_language),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => _showLanguageDialog(),
          ),
          const Divider(),
          
          // Subscription & Billing
          _buildSectionHeader('Subscription & Billing'),
          ListTile(
            title: const Text('Manage Subscription'),
            subtitle: const Text('View plans, usage, and billing'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              context.push('/subscription');
            },
          ),
          const Divider(),
          
          // Privacy & Data
          _buildSectionHeader('Privacy & Data'),
          ListTile(
            title: const Text('Privacy Policy'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              context.push('/privacy-policy');
            },
          ),
          ListTile(
            title: const Text('Terms of Service'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              context.push('/terms-of-service');
            },
          ),
          ListTile(
            title: const Text('Clear Cache'),
            trailing: const Icon(Icons.cleaning_services),
            onTap: () {
              _clearCache();
            },
          ),
          ListTile(
            title: const Text('Delete Account'),
            trailing: const Icon(Icons.delete_forever, color: Colors.red),
            onTap: () {
              _initiateAccountDeletion();
            },
          ),
          const Divider(),
          
          // About
          _buildSectionHeader('About'),
          ListTile(
            title: const Text('App Version'),
            subtitle: Text(AppConstants.appVersion),
          ),
          ListTile(
            title: const Text('Send Feedback'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              // Navigate to feedback form
            },
          ),
          
          const SizedBox(height: 40),
          
          // Logout Button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () async {
                // Show confirmation dialog
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Logout'),
                    content: const Text('Are you sure you want to logout?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Logout'),
                      ),
                    ],
                  ),
                );
                
                if (confirmed == true && mounted) {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setBool(AppConstants.userLoggedInKey, false);
                  if (mounted) {
                    context.go(AppConstants.authRoute);
                  }
                }
              },
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: BorderSide(color: Theme.of(context).colorScheme.error),
              ),
              child: Text(
                'Logout',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
  
  Widget _buildThemeSelector(ThemeMode currentTheme, ThemeNotifier themeNotifier) {
    return Column(
      children: [
        RadioListTile<ThemeMode>(
          title: const Text('Light'),
          value: ThemeMode.light,
          groupValue: currentTheme,
          onChanged: (value) async {
            if (value != null && value != currentTheme) {
              final shouldRestart = await themeNotifier.showThemeChangeDialog(context, value);
              if (shouldRestart && mounted) {
                _restartApp();
              }
            }
          },
        ),
        RadioListTile<ThemeMode>(
          title: const Text('Dark'),
          value: ThemeMode.dark,
          groupValue: currentTheme,
          onChanged: (value) async {
            if (value != null && value != currentTheme) {
              final shouldRestart = await themeNotifier.showThemeChangeDialog(context, value);
              if (shouldRestart && mounted) {
                _restartApp();
              }
            }
          },
        ),
        RadioListTile<ThemeMode>(
          title: const Text('System Default'),
          value: ThemeMode.system,
          groupValue: currentTheme,
          onChanged: (value) async {
            if (value != null && value != currentTheme) {
              final shouldRestart = await themeNotifier.showThemeChangeDialog(context, value);
              if (shouldRestart && mounted) {
                _restartApp();
              }
            }
          },
        ),
      ],
    );
  }
  
  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Language'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('English'),
              value: 'English',
              groupValue: _language,
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _language = value;
                    _saveSettings();
                  });
                  Navigator.pop(context);
                }
              },
            ),
            RadioListTile<String>(
              title: const Text('Spanish'),
              value: 'Spanish',
              groupValue: _language,
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _language = value;
                    _saveSettings();
                  });
                  Navigator.pop(context);
                }
              },
            ),
            RadioListTile<String>(
              title: const Text('French'),
              value: 'French',
              groupValue: _language,
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _language = value;
                    _saveSettings();
                  });
                  Navigator.pop(context);
                }
              },
            ),
            RadioListTile<String>(
              title: const Text('German'),
              value: 'German',
              groupValue: _language,
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _language = value;
                    _saveSettings();
                  });
                  Navigator.pop(context);
                }
              },
            ),
            RadioListTile<String>(
              title: const Text('Chinese'),
              value: 'Chinese',
              groupValue: _language,
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _language = value;
                    _saveSettings();
                  });
                  Navigator.pop(context);
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
  
  void _showCommentStyleDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Comment Style'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('Professional'),
              subtitle: const Text('Formal and business-oriented'),
              value: 'Professional',
              groupValue: _language,
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _language = value;
                    _saveSettings();
                  });
                  Navigator.pop(context);
                }
              },
            ),
            RadioListTile<String>(
              title: const Text('Casual'),
              subtitle: const Text('Friendly and conversational'),
              value: 'Casual',
              groupValue: _language,
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _language = value;
                    _saveSettings();
                  });
                  Navigator.pop(context);
                }
              },
            ),
            RadioListTile<String>(
              title: const Text('Expert'),
              subtitle: const Text('Authoritative and insightful'),
              value: 'Expert',
              groupValue: _language,
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _language = value;
                    _saveSettings();
                  });
                  Navigator.pop(context);
                }
              },
            ),
            RadioListTile<String>(
              title: const Text('Supportive'),
              subtitle: const Text('Encouraging and positive'),
              value: 'Supportive',
              groupValue: _language,
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _language = value;
                    _saveSettings();
                  });
                  Navigator.pop(context);
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
  
  void _showPostFrequencyDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Post Frequency'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('Daily'),
              value: 'Daily',
              groupValue: _language,
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _language = value;
                    _saveSettings();
                  });
                  Navigator.pop(context);
                }
              },
            ),
            RadioListTile<String>(
              title: const Text('Weekly'),
              value: 'Weekly',
              groupValue: _language,
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _language = value;
                    _saveSettings();
                  });
                  Navigator.pop(context);
                }
              },
            ),
            RadioListTile<String>(
              title: const Text('Bi-Weekly'),
              value: 'Bi-Weekly',
              groupValue: _language,
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _language = value;
                    _saveSettings();
                  });
                  Navigator.pop(context);
                }
              },
            ),
            RadioListTile<String>(
              title: const Text('Monthly'),
              value: 'Monthly',
              groupValue: _language,
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _language = value;
                    _saveSettings();
                  });
                  Navigator.pop(context);
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
  
  void _showNotificationScheduleDialog() {
    final TimeOfDay initialTime = TimeOfDay.now();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Notification Schedule'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Morning Reminder'),
              subtitle: const Text('9:00 AM'),
              trailing: IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () async {
                  await _selectMorningTime(context);
                },
              ),
            ),
            const Divider(),
            ListTile(
              title: const Text('Engagement Opportunity'),
              subtitle: const Text('When your network is most active'),
              trailing: Switch(
                value: true,
                onChanged: (value) {},
              ),
            ),
            const Divider(),
            ListTile(
              title: const Text('Weekly Summary'),
              subtitle: const Text('Fridays at 4:00 PM'),
              trailing: IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () async {
                  await _selectWeeklySummaryTime(context);
                },
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
  
  Future<void> _selectMorningTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _morningReminderTime,
    );
    
    if (picked != null && picked != _morningReminderTime) {
      setState(() {
        _morningReminderTime = picked;
      });
      
      ToastUtils.showInfoToast('Morning reminder set to ${picked.format(context)}');
    }
  }
  
  Future<void> _selectWeeklySummaryTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _weeklySummaryTime,
    );
    
    if (picked != null && picked != _weeklySummaryTime) {
      setState(() {
        _weeklySummaryTime = picked;
      });
      
      ToastUtils.showInfoToast('Weekly summary set to ${picked.format(context)}');
    }
  }
  
  void _showLinkedInAccountDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('LinkedIn Account'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(
                labelText: 'LinkedIn URL',
                hintText: 'linkedin.com/in/username',
                prefixIcon: Icon(Icons.link),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _reconnectLinkedIn();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Reconnect'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _updateLinkedInAccount();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
  
  void _refreshLinkedInConnection() {
    // Simulate refreshing connection
    setState(() {
      _isRefreshingLinkedIn = true;
    });
    
    // Simulate network delay
    Future.delayed(const Duration(seconds: 1), () {
      setState(() {
        _isRefreshingLinkedIn = false;
      });
      
      ToastUtils.showSuccessToast('LinkedIn connection refreshed');
    });
  }
  

  
  void _clearCache() {
    // Simulate clearing cache
    setState(() {
      _isClearingCache = true;
    });
    
    // Simulate operation
    Future.delayed(const Duration(seconds: 1), () {
      setState(() {
        _isClearingCache = false;
      });
      
      ToastUtils.showSuccessToast('Cache cleared successfully');
    });
  }
  
  void _initiateAccountDeletion() {
    // Show confirmation dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text('Are you sure you want to delete your account? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteAccount();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
  
  void _deleteAccount() {
    // Simulate account deletion
    setState(() {
      _isDeletingAccount = true;
    });
    
    // Simulate deletion process
    Future.delayed(const Duration(seconds: 1), () {
      setState(() {
        _isDeletingAccount = false;
      });
      
      ToastUtils.showInfoToast('Account deletion initiated');
      
      // In a real app, this would log the user out and redirect to login screen
    });
  }
  
  void _reconnectLinkedIn() {
    // Simulate reconnection
    setState(() {
      _isReconnectingLinkedIn = true;
    });
    
    // Simulate network request
    Future.delayed(const Duration(seconds: 1), () {
      setState(() {
        _isReconnectingLinkedIn = false;
      });
      
      ToastUtils.showSuccessToast('LinkedIn account reconnected');
    });
  }
  
  void _updateLinkedInAccount() {
    // Simulate update
    setState(() {
      _isUpdatingLinkedIn = true;
    });
    
    // Simulate network request
    Future.delayed(const Duration(seconds: 1), () {
      setState(() {
        _isUpdatingLinkedIn = false;
      });
      
      ToastUtils.showSuccessToast('LinkedIn account updated');
    });
  }
  
  // Method to restart the app
  void _restartApp() {
    // Perform any cleanup needed before restart
    
    // Navigate to initial route to simulate a restart
    if (mounted) {
      context.go(AppConstants.homeRoute);
    }
  }
} 
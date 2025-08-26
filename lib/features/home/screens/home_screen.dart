import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:einsteiniapp/core/routes/app_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:einsteiniapp/core/widgets/custom_app_bar.dart';
import 'package:einsteiniapp/core/widgets/app_logo.dart';
import 'package:einsteiniapp/core/utils/permission_utils.dart';
import 'package:einsteiniapp/core/widgets/permission_reminder_box.dart';
import 'package:einsteiniapp/features/home/widgets/ai_assistant_tab.dart';
import 'package:einsteiniapp/features/home/widgets/history_tab.dart';
import 'package:einsteiniapp/core/services/history_service.dart';
import 'package:einsteiniapp/core/services/api_service.dart';
import 'package:einsteiniapp/core/constants/app_constants.dart' as app_const;
import 'package:einsteiniapp/core/constants/app_constants.dart' show AppPermission;

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  String _userName = 'LinkedIn User';
  String _userEmail = 'user@example.com';
  bool _showOverlayPermissionBox = false;
  // Remove accessibility permission box variable
  // bool _showAccessibilityPermissionBox = false;
  bool _overlayEnabled = false;
  
  // Subscription information
  String _subscriptionStatus = 'inactive';
  String _subscriptionPlan = 'Free';
  int _commentsRemaining = 0;
  int _daysRemaining = 0;
  bool _loadingSubscription = true;
  
  // Store recent activity from history
  List<AnalyzedPost> _recentActivity = [];
  bool _loadingRecentActivity = true;
  
  // Reference to the AIAssistantTab key to access its methods
  final GlobalKey<AIAssistantTabState> _aiAssistantTabKey = GlobalKey<AIAssistantTabState>();
  
  // TabController for managing tabs
  late TabController _tabController;
  
  // API Service
  final ApiService _apiService = ApiService();
  
  @override
  void initState() {
    super.initState();
    _loadUserData();
    _checkPermissions();
    _loadRecentActivity();
    _loadSubscriptionInfo();
    _loadOverlayState();
    
    // Initialize tab controller
    _tabController = TabController(length: 3, vsync: this, initialIndex: _selectedIndex);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          _selectedIndex = _tabController.index;
        });
      }
    });
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName = prefs.getString('user_name') ?? 'LinkedIn User';
      _userEmail = prefs.getString('user_email') ?? 'user@example.com';
    });
  }
  
  Future<void> _loadSubscriptionInfo() async {
    try {
      final subscription = await _apiService.getSubscriptionStatus();
      final commentsCount = await _apiService.getNumberOfComments();
      
      setState(() {
        _subscriptionStatus = subscription['status'] ?? 'inactive';
        _subscriptionPlan = subscription['product'] ?? 'Free';
        _commentsRemaining = commentsCount;
        _daysRemaining = subscription['daysleft'] ?? 0;
        _loadingSubscription = false;
      });
      
      debugPrint('Comments remaining: $_commentsRemaining');
    } catch (e) {
      print('Error loading subscription info: $e');
      setState(() {
        _loadingSubscription = false;
      });
    }
  }

  Future<void> _checkPermissions() async {
    final overlayGranted = await PermissionUtils.checkPermissionGranted(AppPermission.overlay);
    // Remove accessibility permission check
    // final accessibilityGranted = await PermissionUtils.checkPermissionGranted(AppPermission.accessibility);
    
    setState(() {
      _showOverlayPermissionBox = !overlayGranted;
      // Remove setting for accessibility permission box
      // _showAccessibilityPermissionBox = !accessibilityGranted;
    });
  }
  
  void _dismissOverlayPermissionBox() {
    setState(() {
      _showOverlayPermissionBox = false;
    });
  }
  
  // Remove dismiss accessibility permission box method
  /*
  void _dismissAccessibilityPermissionBox() {
    setState(() {
      _showAccessibilityPermissionBox = false;
    });
  }
  */
  
  // Handle re-analyzing a post from history
  void _handleReanalyzePost(AnalyzedPost post) async {
    // Switch to AI Assistant tab
    setState(() {
      _selectedIndex = 2;
    });
    _tabController.animateTo(2);
    
    // Access the AIAssistantTab methods
    if (_aiAssistantTabKey.currentState != null) {
      await _aiAssistantTabKey.currentState!.analyzeFromHistory(post);
      // Refresh recent activity after analysis is complete
      _loadRecentActivity();
    }
  }

  Future<void> _loadRecentActivity() async {
    try {
      final allPosts = await HistoryService.getAllPosts();
      setState(() {
        // Take only the most recent 3 posts
        _recentActivity = allPosts.take(3).toList();
        _loadingRecentActivity = false;
      });
    } catch (e) {
      print('Error loading recent activity: $e');
      setState(() {
        _loadingRecentActivity = false;
      });
    }
  }

  Future<void> _loadOverlayState() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _overlayEnabled = prefs.getBool('overlay_enabled') ?? false;
    });
  }

  @override
  Widget build(BuildContext context) {
    
    return Scaffold(
      appBar: CustomAppBar(
        title: _getAppBarTitle(),
        showDrawerButton: true,
        centerTitle: false,
        elevation: 0,
        actions: _buildAppBarActions(),
      ),
      drawer: _buildDrawer(),
      body: TabBarView(
        controller: _tabController,
        physics: const NeverScrollableScrollPhysics(), // Disable swiping
        children: [
          _buildHomeTab(),
          AIAssistantTab(key: _aiAssistantTabKey),
          HistoryTab(onReanalyzePost: _handleReanalyzePost),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }
  
  String _getAppBarTitle() {
    switch (_selectedIndex) {
      case 0:
        return 'Home';
      case 1:
        return 'AI Assistant';
      case 2:
        return 'History';
      default:
        return 'einsteini.ai';
    }
  }
  
  List<Widget> _buildAppBarActions() {
    return [
      IconButton(
        icon: const Icon(Icons.search),
        onPressed: () {
          // Show search
        },
      ),
      IconButton(
        icon: const Icon(Icons.notifications_outlined),
        onPressed: () {
          // Show notifications
        },
      ),
    ];
  }
  
  Widget _buildDrawer() {
    return Drawer(
      child: Column(
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  child: Text(
                    _userName.isNotEmpty ? _userName[0].toUpperCase() : 'U',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _userName,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _userEmail,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home_outlined),
            title: const Text('Home'),
            selected: _selectedIndex == 0,
            onTap: () {
              setState(() {
                _selectedIndex = 0;
              });
              _tabController.animateTo(0);
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.auto_awesome),
            title: const Text('AI Assistant'),
            selected: _selectedIndex == 1,
            onTap: () {
              setState(() {
                _selectedIndex = 1;
              });
              _tabController.animateTo(1);
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.history_outlined),
            title: const Text('History'),
            selected: _selectedIndex == 2,
            onTap: () {
              setState(() {
                _selectedIndex = 2;
              });
              _tabController.animateTo(2);
              Navigator.pop(context);
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text('Profile'),
            onTap: () {
              Navigator.pop(context);
              context.push(AppRoutes.profile);
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings_outlined),
            title: const Text('Settings'),
            onTap: () {
              Navigator.pop(context);
              context.push(AppRoutes.settings);
            },
          ),
          ListTile(
            leading: const Icon(Icons.workspace_premium),
            title: const Text('Subscription'),
            onTap: () {
              Navigator.pop(context);
              context.push(AppRoutes.subscription);
            },
          ),
          ListTile(
            leading: const Icon(Icons.school_outlined),
            title: const Text('Tutorial'),
            onTap: () {
              Navigator.pop(context);
              context.push(AppRoutes.tutorial);
            },
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: AppLogo(
              size: 40,
              padding: 6,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Text('Version ${app_const.AppConstants.appVersion}'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildHomeTab() {
    return RefreshIndicator(
      onRefresh: () async {
        // Refresh recent activity
        await _loadRecentActivity();
        // Recheck permissions
        await _checkPermissions();
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_showOverlayPermissionBox) ...[
              PermissionReminderBox(
                permission: AppPermission.overlay,
                onDismiss: _dismissOverlayPermissionBox,
              ),
              const SizedBox(height: 16),
            ],
            // Remove accessibility permission box display
            // if (_showAccessibilityPermissionBox) ...[
            //   PermissionReminderBox(
            //     permission: AppPermission.accessibility,
            //     onDismiss: _dismissAccessibilityPermissionBox,
            //   ),
            //   const SizedBox(height: 16),
            // ],
            _buildWelcomeCard(),
            const SizedBox(height: 24),
            _buildRecentActivitySection(),
            const SizedBox(height: 24),
            _buildQuickActionsSection(),
            const SizedBox(height: 24),
            _buildTipsSection(),
          ],
        ),
      ),
    );
  }
  
  Widget _buildWelcomeCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  child: Text(
                    _userName.isNotEmpty ? _userName[0].toUpperCase() : 'U',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome back, ${_userName.split(' ')[0]}!',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Ready to boost your LinkedIn engagement?',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildSubscriptionInfo(),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.comment,
                    title: 'Tokens',
                    value: _loadingSubscription ? '...' : '$_commentsRemaining',
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.auto_awesome,
                    title: 'Plan',
                    value: _loadingSubscription ? '...' : _subscriptionPlan,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.event_available,
                    title: 'Days Left',
                    value: _loadingSubscription ? '...' : '$_daysRemaining',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSubscriptionInfo() {
    if (_loadingSubscription) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }
    
    Color statusColor;
    IconData statusIcon;
    String statusText;
    
    switch (_subscriptionStatus) {
      case 'active':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        statusText = 'Active Subscription';
        break;
      case 'trialing':
        statusColor = Colors.blue;
        statusIcon = Icons.access_time;
        statusText = 'Free Trial';
        break;
      default:
        statusColor = Colors.red;
        statusIcon = Icons.error;
        statusText = 'Inactive Subscription';
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(
            statusIcon,
            color: statusColor,
            size: 18,
          ),
          const SizedBox(width: 8),
          Text(
            statusText,
            style: TextStyle(
              color: statusColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          TextButton(
            onPressed: () {
              // Open subscription management page
              context.push('/subscription');
            },
            style: TextButton.styleFrom(
              backgroundColor: _subscriptionStatus == 'active' 
                ? Colors.grey 
                : Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              minimumSize: const Size(80, 30),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: Text(_subscriptionStatus == 'active' ? 'Manage' : 'Upgrade'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
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
  
  Widget _buildRecentActivitySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Activity',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            if (_recentActivity.isNotEmpty)
              TextButton(
                onPressed: () {
                  // Navigate to history tab
                  setState(() {
                    _selectedIndex = 2;
                  });
                  _tabController.animateTo(2);
                },
                child: const Text('View All'),
              ),
          ],
        ),
        const SizedBox(height: 16),
        
        if (_loadingRecentActivity)
          const Center(
            child: CircularProgressIndicator(),
          )
        else if (_recentActivity.isEmpty)
          _buildEmptyRecentActivity()
        else
          ..._recentActivity.map((post) => _buildRecentActivityCard(post)),
      ],
    );
  }
  
  Widget _buildEmptyRecentActivity() {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.history,
                size: 40,
                color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
              ),
              const SizedBox(height: 16),
              Text(
                'No recent activity',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Analyzed LinkedIn posts will appear here',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  // Navigate to AI Assistant tab
                  setState(() {
                    _selectedIndex = 1;
                  });
                  _tabController.animateTo(1);
                },
                icon: const Icon(Icons.add),
                label: const Text('Analyze a Post'),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildRecentActivityCard(AnalyzedPost post) {
    final DateTime analyzedAt = DateTime.parse(post.analyzedAt);
    final String timeAgo = AnalyzedPost.getRelativeTime(analyzedAt);
    
    IconData activityIcon = Icons.post_add;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
          child: Icon(
            activityIcon,
            color: Theme.of(context).colorScheme.primary,
            size: 20,
          ),
        ),
        title: Text(
          post.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text('by ${post.author} • Analyzed $timeAgo'),
        trailing: IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: () {
            // Re-analyze post
            _handleReanalyzePost(post);
          },
          tooltip: 'Re-analyze',
        ),
        onTap: () {
          // Navigate to the history tab
          setState(() {
            _selectedIndex = 2;
          });
          _tabController.animateTo(2);
        },
      ),
    );
  }
  
  Widget _buildQuickActionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildQuickActionCard(
                icon: Icons.search_outlined,
                title: 'Analyze Post',
                onTap: () {
                  setState(() {
                    _selectedIndex = 1;
                  });
                  _tabController.animateTo(1);
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildQuickActionCard(
                icon: Icons.post_add,
                title: 'Create Post',
                onTap: () {
                  setState(() {
                    _selectedIndex = 1;
                  });
                  _tabController.animateTo(1);
                  // Navigate to Create Post tab
                  if (_aiAssistantTabKey.currentState != null) {
                    _aiAssistantTabKey.currentState!.setTabIndex(1);
                  }
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildQuickActionCard(
                icon: Icons.person_outline,
                title: 'About Me',
                onTap: () {
                  setState(() {
                    _selectedIndex = 1;
                  });
                  _tabController.animateTo(1);
                  // Navigate to About Me tab
                  if (_aiAssistantTabKey.currentState != null) {
                    _aiAssistantTabKey.currentState!.setTabIndex(2);
                  }
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildOverlayToggleCard(),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildUpgradeCard(),
      ],
    );
  }
  
  Widget _buildQuickActionCard({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Card(
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Container(
          height: 160,
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 32,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildOverlayToggleCard() {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        height: 160,
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _overlayEnabled ? Icons.visibility : Icons.visibility_off,
              size: 32,
              color: _overlayEnabled 
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
            const SizedBox(height: 12),
            Text(
              'Overlay',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Switch(
              value: _overlayEnabled,
              onChanged: _toggleOverlay,
              activeThumbColor: Theme.of(context).colorScheme.primary,
            ),
          ],
        ),
      ),
    );
  }
  
  void _toggleOverlay(bool value) async {
    if (!await PermissionUtils.checkPermissionGranted(AppPermission.overlay)) {
      // Request overlay permission if not granted
      await PermissionUtils.requestPermission(context, AppPermission.overlay);
      return;
    }
    
    setState(() {
      _overlayEnabled = value;
    });
    
    // Save preference
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool('overlay_enabled', value);
    
    // Toggle overlay via platform channel
    final bool success = await PermissionUtils.toggleOverlay(value);
    
    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to toggle overlay')),
      );
    }
  }
  
  Widget _buildUpgradeCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.workspace_premium,
                  color: Theme.of(context).colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Unlock Premium Features',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Upgrade to our premium plan to unlock advanced features, unlimited AI analysis, and priority support.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  context.push(AppRoutes.subscription);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Upgrade Now'),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildTipsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'LinkedIn Engagement Tips',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Card(
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.lightbulb,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Tip of the Day',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Engage with comments on trending posts in your industry to increase your visibility to potential connections.',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: () {
                    // View more tips
                  },
                  child: const Text('View More Tips'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: _selectedIndex,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
        showUnselectedLabels: true,
        elevation: 8,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
        unselectedLabelStyle: const TextStyle(fontSize: 12),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.auto_awesome_outlined),
            activeIcon: Icon(Icons.auto_awesome),
            label: 'AI Assistant',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history_outlined),
            activeIcon: Icon(Icons.history),
            label: 'History',
          ),
        ],
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
          _tabController.animateTo(index);
        },
      ),
    );
  }
  
  Widget? _buildFloatingActionButton() {
    // Only show FAB on History tab
    if (_selectedIndex == 2) {  // Updated to match the new index for History tab
      return FloatingActionButton(
        onPressed: () {
          // Navigate to AI Assistant tab
          setState(() {
            _selectedIndex = 1;  // Updated to match the new index for AI Assistant tab
          });
          _tabController.animateTo(1);
        },
        backgroundColor: Theme.of(context).colorScheme.primary,
        child: const Icon(Icons.add),
      );
    }
    return null;
  }
} 
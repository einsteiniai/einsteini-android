import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:einsteiniapp/core/routes/app_router.dart';
import 'package:einsteiniapp/features/home/screens/profile_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:einsteiniapp/core/widgets/custom_app_bar.dart';
import 'package:einsteiniapp/core/widgets/app_logo.dart';
import 'package:einsteiniapp/core/utils/permission_utils.dart';
import 'package:einsteiniapp/core/widgets/permission_reminder_box.dart';
import 'package:einsteiniapp/features/home/widgets/ai_assistant_tab.dart';
import 'package:einsteiniapp/features/home/widgets/history_tab.dart';
import 'package:einsteiniapp/core/services/history_service.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  String _userName = 'LinkedIn User';
  String _userEmail = 'user@example.com';
  bool _showOverlayPermissionBox = false;
  bool _showAccessibilityPermissionBox = false;
  
  // Store recent activity from history
  List<AnalyzedPost> _recentActivity = [];
  bool _loadingRecentActivity = true;
  
  // Reference to the AIAssistantTab key to access its methods
  final GlobalKey<AIAssistantTabState> _aiAssistantTabKey = GlobalKey<AIAssistantTabState>();
  
  // TabController for managing tabs
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _loadUserData();
    _checkPermissions();
    _loadRecentActivity();
    
    // Initialize tab controller
    _tabController = TabController(length: 4, vsync: this, initialIndex: _selectedIndex);
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

  Future<void> _checkPermissions() async {
    final overlayGranted = await PermissionUtils.checkPermissionGranted(AppPermission.overlay);
    final accessibilityGranted = await PermissionUtils.checkPermissionGranted(AppPermission.accessibility);
    
    setState(() {
      _showOverlayPermissionBox = !overlayGranted;
      _showAccessibilityPermissionBox = !accessibilityGranted;
    });
  }
  
  void _dismissOverlayPermissionBox() {
    setState(() {
      _showOverlayPermissionBox = false;
    });
  }
  
  void _dismissAccessibilityPermissionBox() {
    setState(() {
      _showAccessibilityPermissionBox = false;
    });
  }
  
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

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final logoImage = isDarkMode ? 'assets/images/einsteini_white.png' : 'assets/images/einsteini_black.png';
    
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
          HistoryTab(onReanalyzePost: _handleReanalyzePost),
          AIAssistantTab(key: _aiAssistantTabKey),
          _buildAnalyticsTab(),
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
        return 'History';
      case 2:
        return 'AI Assistant';
      case 3:
        return 'Analytics';
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
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final logoImage = isDarkMode ? 'assets/images/einsteini_white.png' : 'assets/images/einsteini_black.png';

    return Drawer(
      child: Column(
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceVariant,
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
            leading: const Icon(Icons.history_outlined),
            title: const Text('History'),
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
            leading: const Icon(Icons.auto_awesome),
            title: const Text('AI Assistant'),
            selected: _selectedIndex == 2,
            onTap: () {
              setState(() {
                _selectedIndex = 2;
              });
              _tabController.animateTo(2);
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.bar_chart),
            title: const Text('Analytics'),
            selected: _selectedIndex == 3,
            onTap: () {
              setState(() {
                _selectedIndex = 3;
              });
              _tabController.animateTo(3);
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
          const Spacer(),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: AppLogo(
              size: 40,
              padding: 6,
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(bottom: 16.0),
            child: Text('Version 1.0.0'),
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
            if (_showAccessibilityPermissionBox) ...[
              PermissionReminderBox(
                permission: AppPermission.accessibility,
                onDismiss: _dismissAccessibilityPermissionBox,
              ),
              const SizedBox(height: 16),
            ],
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
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.comment,
                    title: 'Comments',
                    value: '24',
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.thumb_up,
                    title: 'Likes',
                    value: '142',
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.visibility,
                    title: 'Views',
                    value: '1.2K',
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
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
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
                    _selectedIndex = 1;
                  });
                  _tabController.animateTo(1);
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
          ..._recentActivity.map((post) => _buildRecentActivityCard(post)).toList(),
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
                    _selectedIndex = 2;
                  });
                  _tabController.animateTo(2);
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
    
    String activityType = 'LinkedIn Post';
    IconData activityIcon = Icons.post_add;
    Color iconColor = Colors.green;
    
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
            _selectedIndex = 1;
          });
          _tabController.animateTo(1);
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
                icon: Icons.post_add,
                title: 'Create Post',
                onTap: () {
                  // Create post action
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildQuickActionCard(
                icon: Icons.comment,
                title: 'Write Comment',
                onTap: () {
                  // Write comment action
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
                icon: Icons.auto_awesome,
                title: 'AI Suggestions',
                onTap: () {
                  // AI suggestions action
                  setState(() {
                    _selectedIndex = 2;
                  });
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildQuickActionCard(
                icon: Icons.analytics,
                title: 'View Analytics',
                onTap: () {
                  // View analytics action
                  setState(() {
                    _selectedIndex = 3;
                  });
                },
              ),
            ),
          ],
        ),
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
        child: Padding(
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
            ],
          ),
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
  
  Widget _buildAnalyticsTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.bar_chart,
            size: 64,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 24),
          Text(
            'Analytics',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Text(
              'Track your LinkedIn engagement metrics and growth over time.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () {
              // View detailed analytics
            },
            icon: const Icon(Icons.analytics),
            label: const Text('View Detailed Analytics'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            ),
          ),
        ],
      ),
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
            icon: Icon(Icons.history_outlined),
            activeIcon: Icon(Icons.history),
            label: 'History',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.auto_awesome_outlined),
            activeIcon: Icon(Icons.auto_awesome),
            label: 'AI Assistant',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart_outlined),
            activeIcon: Icon(Icons.bar_chart),
            label: 'Analytics',
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
    if (_selectedIndex == 1) {
      return FloatingActionButton(
        onPressed: () {
          // Navigate to AI Assistant tab
          setState(() {
            _selectedIndex = 2;
          });
          _tabController.animateTo(2);
        },
        backgroundColor: Theme.of(context).colorScheme.primary,
        child: const Icon(Icons.add),
      );
    }
    return null;
  }
} 
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:einsteiniapp/core/services/history_service.dart';
import 'package:einsteiniapp/core/utils/toast_utils.dart';
import 'package:url_launcher/url_launcher.dart';

class HistoryTab extends StatefulWidget {
  final Function(AnalyzedPost)? onReanalyzePost;
  
  const HistoryTab({Key? key, this.onReanalyzePost}) : super(key: key);

  @override
  State<HistoryTab> createState() => _HistoryTabState();
}

class _HistoryTabState extends State<HistoryTab> {
  final TextEditingController _searchController = TextEditingController();
  List<AnalyzedPost> _historyItems = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadHistory();
    
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
      _searchHistory();
    });
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final posts = await HistoryService.getAllPosts();
      setState(() {
        _historyItems = posts;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading history: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  Future<void> _searchHistory() async {
    if (_searchQuery.isEmpty) {
      _loadHistory();
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final results = await HistoryService.searchPosts(_searchQuery);
      setState(() {
        _historyItems = results;
        _isLoading = false;
      });
    } catch (e) {
      print('Error searching history: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  Future<void> _deleteHistoryItem(AnalyzedPost item) async {
    try {
      await HistoryService.deletePost(item.id);
      ToastUtils.showSuccessToast('Post removed from history');
      _loadHistory();
    } catch (e) {
      print('Error deleting history item: $e');
      ToastUtils.showErrorToast('Failed to remove post from history');
    }
  }
  
  Future<void> _clearAllHistory() async {
    try {
      await HistoryService.clearAllHistory();
      ToastUtils.showSuccessToast('History cleared');
      _loadHistory();
    } catch (e) {
      print('Error clearing history: $e');
      ToastUtils.showErrorToast('Failed to clear history');
    }
  }
  
  Future<void> _launchURL(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        ToastUtils.showErrorToast('Could not open URL');
      }
    } catch (e) {
      ToastUtils.showErrorToast('Invalid URL');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Analysis History',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (_historyItems.isNotEmpty)
                OutlinedButton.icon(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Clear History'),
                        content: const Text('Are you sure you want to clear all history? This action cannot be undone.'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancel'),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              _clearAllHistory();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Clear All'),
                          ),
                        ],
                      ),
                    );
                  },
                  icon: const Icon(Icons.delete_outline, size: 16),
                  label: const Text('Clear All'),
                ),
            ],
          ).animate().fadeIn(duration: 400.ms),
          
          const SizedBox(height: 8),
          
          Text(
            'View your previously analyzed LinkedIn posts',
            style: Theme.of(context).textTheme.bodyMedium,
          ).animate().fadeIn(duration: 400.ms, delay: 100.ms),
          
          const SizedBox(height: 24),
          
          _buildSearchBar().animate().fadeIn(duration: 400.ms, delay: 200.ms),
          
          const SizedBox(height: 16),
          
          if (_isLoading)
            const Expanded(
              child: Center(
                child: CircularProgressIndicator(),
              ),
            )
          else
            Expanded(
              child: _historyItems.isEmpty
                  ? _buildEmptyState().animate().fadeIn(duration: 400.ms, delay: 300.ms)
                  : _buildHistoryList().animate().fadeIn(duration: 400.ms, delay: 300.ms),
            ),
        ],
      ),
    );
  }
  
  Widget _buildSearchBar() {
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: 'Search history...',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: _searchController.text.isNotEmpty
          ? IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                _searchController.clear();
                // Clear search and reload all history
                _loadHistory();
              },
            )
          : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none, // Remove the border
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none, // Remove the border
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.primary,
            width: 1.5,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        filled: true,
        fillColor: Theme.of(context).brightness == Brightness.dark
            ? Colors.grey[800]!.withOpacity(0.5)
            : Colors.grey[100]!.withOpacity(0.7),
      ),
      onSubmitted: (_) {
        // Trigger search on submit
        _searchHistory();
      },
    );
  }
  
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history,
            size: 64,
            color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
          ),
          const SizedBox(height: 24),
          Text(
            _searchQuery.isNotEmpty
                ? 'No results found'
                : 'No history yet',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isNotEmpty
                ? 'Try a different search term'
                : 'Your analyzed LinkedIn posts will appear here',
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          if (_searchQuery.isEmpty) ...[
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                // Navigate to AI Assistant tab
                DefaultTabController.of(context).animateTo(1);
              },
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('Analyze a Post'),
              style: ElevatedButton.styleFrom(
                iconColor: Colors.white,
              ),
            ),
          ],
        ],
      ),
    );
  }
  
  Widget _buildHistoryList() {
    return RefreshIndicator(
      onRefresh: _loadHistory,
      child: ListView.separated(
        itemCount: _historyItems.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final item = _historyItems[index];
          return _buildHistoryCard(item);
        },
      ),
    );
  }
  
  Widget _buildHistoryCard(AnalyzedPost item) {
    final DateTime analyzedAt = DateTime.parse(item.analyzedAt);
    final String timeAgo = AnalyzedPost.getRelativeTime(analyzedAt);
    
    // Determine icon and color based on functionality
    IconData functionIcon = Icons.analytics_outlined;
    Color functionColor = Theme.of(context).colorScheme.primary;
    String functionText = 'Analyzed';
    
    if (item.functionality.contains('summary')) {
      functionIcon = Icons.summarize;
      functionColor = Colors.green;
      functionText = 'Summarized';
    } else if (item.functionality.contains('translate')) {
      functionIcon = Icons.translate;
      functionColor = Colors.blue;
      functionText = 'Translated';
    } else if (item.functionality.contains('comment')) {
      functionIcon = Icons.comment;
      functionColor = Colors.orange;
      functionText = 'Comment Generated';
    }
    
    return Card(
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  child: Text(
                    item.author.isNotEmpty ? item.author[0].toUpperCase() : 'U',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'by ${item.author} • ${item.date}',
                        style: Theme.of(context).textTheme.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.history,
                            size: 12,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Analyzed $timeAgo',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Add functionality indicator
            if (item.functionality.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: functionColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(functionIcon, size: 16, color: functionColor),
                    const SizedBox(width: 6),
                    Text(
                      _getFunctionalityDisplayText(item.functionality),
                      style: TextStyle(
                        color: functionColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            
            const SizedBox(height: 16),
            // Remove stats chips, keep only the action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    // Re-analyze post
                    if (widget.onReanalyzePost != null) {
                      widget.onReanalyzePost!(item);
                      // Navigate to AI Assistant tab handled by parent
                    }
                  },
                  icon: const Icon(Icons.refresh, size: 16, color: Colors.white),
                  label: const Text('Re-analyze'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    iconColor: Colors.white,
                    visualDensity: VisualDensity.compact,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.more_vert),
                  onPressed: () {
                    _showOptionsBottomSheet(context, item);
                  },
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  // Helper method to get a user-friendly display text for functionality
  String _getFunctionalityDisplayText(String functionality) {
    if (functionality.isEmpty || functionality == 'analyze') {
      return 'Analyzed';
    }
    
    if (functionality.contains('summary')) {
      final type = functionality.split(':').length > 1 ? functionality.split(':')[1].trim() : '';
      return 'Summarized ($type)';
    }
    
    if (functionality.contains('translate')) {
      final language = functionality.split(':').length > 1 ? functionality.split(':')[1].trim() : '';
      return 'Translated to $language';
    }
    
    if (functionality.contains('comment')) {
      final tone = functionality.split(':').length > 1 ? functionality.split(':')[1].trim() : '';
      return 'Comment ($tone tone)';
    }
    
    return functionality;
  }
  
  void _showOptionsBottomSheet(BuildContext context, AnalyzedPost item) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.open_in_new),
                title: const Text('Open LinkedIn Post'),
                onTap: () {
                  Navigator.pop(context);
                  _launchURL(item.postUrl);
                },
              ),
              ListTile(
                leading: const Icon(Icons.copy),
                title: const Text('Copy Post URL'),
                onTap: () {
                  Navigator.pop(context);
                  Clipboard.setData(ClipboardData(text: item.postUrl)).then((_) {
                    ToastUtils.showSuccessToast('URL copied to clipboard');
                  });
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline),
                title: const Text('Remove from History'),
                onTap: () {
                  Navigator.pop(context);
                  _deleteHistoryItem(item);
                },
              ),
            ],
          ),
        );
      },
    );
  }
} 
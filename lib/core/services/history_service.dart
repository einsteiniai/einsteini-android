import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class AnalyzedPost {
  final String id;
  final String title;
  final String content;
  final String author;
  final String date;
  final String analyzedAt;
  final String postUrl;
  final int likes;
  final int comments;
  final List<String> images;
  final List<Map<String, String>> commentsList;
  final String functionality; // Added field to track what feature was used

  AnalyzedPost({
    required this.id,
    required this.title,
    required this.content,
    required this.author,
    required this.date,
    required this.analyzedAt,
    required this.postUrl,
    required this.likes,
    required this.comments,
    required this.images,
    required this.commentsList,
    this.functionality = '', // Default to empty string
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'author': author,
      'date': date,
      'analyzedAt': analyzedAt,
      'postUrl': postUrl,
      'likes': likes,
      'comments': comments,
      'images': images,
      'commentsList': commentsList.map((comment) => comment).toList(),
      'functionality': functionality,
    };
  }

  factory AnalyzedPost.fromJson(Map<String, dynamic> json) {
    return AnalyzedPost(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      author: json['author'] ?? '',
      date: json['date'] ?? '',
      analyzedAt: json['analyzedAt'] ?? '',
      postUrl: json['postUrl'] ?? '',
      likes: json['likes'] ?? 0,
      comments: json['comments'] ?? 0,
      images: List<String>.from(json['images'] ?? []),
      commentsList: (json['commentsList'] as List<dynamic>?)
          ?.map((comment) => Map<String, String>.from(comment))
          .toList() ??
          [],
      functionality: json['functionality'] ?? '',
    );
  }

  // Generate a title from content if none is provided
  static String generateTitleFromContent(String content) {
    if (content.isEmpty) return 'LinkedIn Post';
    
    // Use the first sentence or first 50 characters as the title
    final firstSentenceEnd = content.indexOf('.');
    if (firstSentenceEnd > 0 && firstSentenceEnd < 100) {
      return content.substring(0, firstSentenceEnd + 1);
    } else {
      // If no period found or too long, use first 50 chars
      return content.length > 50 
        ? content.substring(0, 50) + '...' 
        : content;
    }
  }
  
  // Format relative timestamp
  static String getRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()} years ago';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()} months ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} days ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hours ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minutes ago';
    } else {
      return 'Just now';
    }
  }
}

class HistoryService {
  static const String _storageKey = 'analyzed_posts_history';
  
  // Get all analyzed posts
  static Future<List<AnalyzedPost>> getAllPosts() async {
    final prefs = await SharedPreferences.getInstance();
    final postsJson = prefs.getStringList(_storageKey) ?? [];
    
    return postsJson
        .map((postJson) => AnalyzedPost.fromJson(jsonDecode(postJson)))
        .toList()
        ..sort((a, b) => DateTime.parse(b.analyzedAt).compareTo(DateTime.parse(a.analyzedAt)));
  }
  
  // Save a new analyzed post
  static Future<void> savePost(AnalyzedPost post) async {
    final prefs = await SharedPreferences.getInstance();
    final postsJson = prefs.getStringList(_storageKey) ?? [];
    
    // Check if post with same URL already exists
    final existingPostIndex = postsJson.indexWhere((postJson) {
      final decodedPost = jsonDecode(postJson);
      return decodedPost['postUrl'] == post.postUrl;
    });
    
    if (existingPostIndex >= 0) {
      // Update existing post
      postsJson[existingPostIndex] = jsonEncode(post.toJson());
    } else {
      // Add new post
      postsJson.add(jsonEncode(post.toJson()));
    }
    
    await prefs.setStringList(_storageKey, postsJson);
  }
  
  // Delete a post by ID
  static Future<void> deletePost(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final postsJson = prefs.getStringList(_storageKey) ?? [];
    
    final updatedPostsJson = postsJson.where((postJson) {
      final decodedPost = jsonDecode(postJson);
      return decodedPost['id'] != id;
    }).toList();
    
    await prefs.setStringList(_storageKey, updatedPostsJson);
  }
  
  // Clear all history
  static Future<void> clearAllHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }
  
  // Search posts by query
  static Future<List<AnalyzedPost>> searchPosts(String query) async {
    if (query.isEmpty) {
      return getAllPosts();
    }
    
    final allPosts = await getAllPosts();
    final lowercaseQuery = query.toLowerCase();
    
    return allPosts.where((post) {
      return post.title.toLowerCase().contains(lowercaseQuery) ||
          post.content.toLowerCase().contains(lowercaseQuery) ||
          post.author.toLowerCase().contains(lowercaseQuery);
    }).toList();
  }
} 
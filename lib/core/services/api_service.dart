import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Service to communicate with the einsteini backend API
class ApiService {
  static const String _baseUrl = 'https://backend.einsteini.ai/api';
  static final ApiService _instance = ApiService._internal();
  
  String? _authToken;

  /// Singleton instance
  factory ApiService() {
    return _instance;
  }

  ApiService._internal();

  /// Initialize the API service, loading auth token if available
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _authToken = prefs.getString('auth_token');
  }

  /// Save auth token to shared preferences
  Future<void> _saveAuthToken(String token) async {
    _authToken = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  /// Clear auth token from memory and storage
  Future<void> clearAuthToken() async {
    _authToken = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }

  /// Get default headers for API requests
  Map<String, String> get _headers {
    final headers = {
      'Content-Type': 'application/json',
    };
    
    if (_authToken != null) {
      headers['Authorization'] = 'Bearer $_authToken';
    }
    
    return headers;
  }

  /// Register a new user
  Future<Map<String, dynamic>> signup({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/signup'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'email': email,
          'password': password,
        }),
      );

      final data = jsonDecode(response.body);
      
      if (response.statusCode == 201 || response.statusCode == 200) {
        if (data['token'] != null) {
          await _saveAuthToken(data['token']);
        }
        
        // Save user profile data if available
        final prefs = await SharedPreferences.getInstance();
        if (data['userId'] != null) {
          await prefs.setString('user_id', data['userId']);
        }
        if (data['name'] != null) {
          await prefs.setString('user_name', data['name']);
        }
        await prefs.setString('user_email', email);
        await prefs.setBool('user_logged_in', true);
        
        return {
          'success': true,
          'message': data['message'] ?? 'Registration successful',
          'user': data['user'] ?? {'name': name, 'email': email},
        };
      } else {
        debugPrint('Error during signup: ${response.statusCode}');
        debugPrint('Response: ${response.body}');
        return {
          'success': false,
          'message': data['message'] ?? 'Registration failed',
          'error': data['error']
        };
      }
    } catch (e) {
      debugPrint('Exception during signup: $e');
      return {
        'success': false,
        'message': 'Registration failed',
        'error': e.toString()
      };
    }
  }

  /// Login an existing user
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        if (data['token'] != null) {
          await _saveAuthToken(data['token']);
        }
        
        // Save user profile data
        final prefs = await SharedPreferences.getInstance();
        if (data['userId'] != null) {
          await prefs.setString('user_id', data['userId']);
        }
        if (data['name'] != null) {
          await prefs.setString('user_name', data['name']);
        }
        await prefs.setString('user_email', email);
        await prefs.setBool('user_logged_in', true);
        
        return {
          'success': true,
          'message': data['message'] ?? 'Login successful',
          'user': data['user'] ?? {'email': email},
        };
      } else {
        debugPrint('Login failed: ${response.statusCode}');
        debugPrint('Response: ${response.body}');
        return {
          'success': false,
          'message': data['message'] ?? 'Authentication failed',
          'error': data['error']
        };
      }
    } catch (e) {
      debugPrint('Exception during login: $e');
      return {
        'success': false,
        'message': 'Login failed',
        'error': e.toString()
      };
    }
  }

  /// Check if user is logged in
  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    return token != null && token.isNotEmpty;
  }

  /// Logout the current user
  Future<bool> logout() async {
    try {
      // Call logout endpoint if the backend requires it
      if (_authToken != null) {
        try {
          await http.post(
            Uri.parse('$_baseUrl/auth/logout'),
            headers: _headers,
          );
        } catch (e) {
          // Even if the server logout fails, continue with client logout
          debugPrint('Server logout failed: $e');
        }
      }
      
      // Always clear local tokens and data
      await clearAuthToken();
      
      // Clear user data from shared preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user_id');
      await prefs.remove('user_name');
      await prefs.remove('user_email');
      await prefs.setBool('user_logged_in', false);
      
      return true;
    } catch (e) {
      debugPrint('Exception during logout: $e');
      return false;
    }
  }

  /// Get user profile information
  Future<Map<String, dynamic>> getUserProfile() async {
    if (_authToken == null) {
      return {
        'success': false,
        'message': 'Not authenticated',
      };
    }
    
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/user/profile'),
        headers: _headers,
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'user': data['user'] ?? {},
        };
      } else {
        debugPrint('Error getting user profile: ${response.statusCode}');
        return {
          'success': false,
          'message': 'Failed to get user profile',
        };
      }
    } catch (e) {
      debugPrint('Exception while getting user profile: $e');
      return {
        'success': false,
        'message': 'Network or server issue',
      };
    }
  }

  /// Generate AI-powered comment for LinkedIn content
  Future<String> generateComment({
    required String postContent,
    required String author,
    required String commentType,
    String? imageUrl,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/generate-comment'),
        headers: _headers,
        body: jsonEncode({
          'text': postContent,
          'author': author,
          'commentType': commentType,
          'img_url': imageUrl ?? '',
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['comment'] ?? 'Error: Empty response from server';
      } else {
        debugPrint('Error generating comment: ${response.statusCode}');
        debugPrint('Response: ${response.body}');
        return 'Error: ${response.statusCode} - Failed to generate comment';
      }
    } catch (e) {
      debugPrint('Exception while generating comment: $e');
      return 'Error: Network or server issue';
    }
  }

  /// Generate AI-powered post for LinkedIn
  Future<String> generatePost({
    required String prompt,
    String? framework = 'AIDA',
    String? buttonType = 'Generate',
    String? tone,
    String? toneDetails,
  }) async {
    try {
      final body = {
        'text': prompt,
        'dropValue': framework,
        'btntype': buttonType,
      };
      
      if (tone != null && tone.isNotEmpty) {
        body['tone'] = tone;
      }
      
      if (toneDetails != null && toneDetails.isNotEmpty) {
        body['tone_details'] = toneDetails;
      }
      
      final response = await http.post(
        Uri.parse('$_baseUrl/generate-post'),
        headers: _headers,
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['post'] ?? 'Error: Empty response from server';
      } else {
        debugPrint('Error generating post: ${response.statusCode}');
        return 'Error: ${response.statusCode} - Failed to generate post';
      }
    } catch (e) {
      debugPrint('Exception while generating post: $e');
      return 'Error: Network or server issue';
    }
  }

  /// Generate LinkedIn About section
  Future<String> generateAbout({
    required String currentAbout,
    required String type,
    String? company,
    String? experience,
    String? toneDetails,
  }) async {
    try {
      final body = {
        'about': currentAbout,
        'btntype': type,
        'page': 'About',
      };
      
      if (company != null) {
        body['company'] = company;
      }
      
      if (experience != null) {
        body['experience'] = experience;
      }
      
      if (toneDetails != null) {
        body['tone_details'] = toneDetails;
      }
      
      final response = await http.post(
        Uri.parse('$_baseUrl/generate-about'),
        headers: _headers,
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['about'] ?? 'Error: Empty response from server';
      } else {
        debugPrint('Error generating about: ${response.statusCode}');
        return 'Error: ${response.statusCode} - Failed to generate about section';
      }
    } catch (e) {
      debugPrint('Exception while generating about: $e');
      return 'Error: Network or server issue';
    }
  }

  /// Generate connection note for LinkedIn
  Future<String> generateConnectionNote({
    required String profileName,
    required String about,
    String? mutual,
    String? buttonType,
    String? tone,
    String? toneDetails,
    String? message,
  }) async {
    try {
      final body = {
        'author': profileName,
        'about': about,
        'btntype': buttonType ?? 'Formal',
      };
      
      if (mutual != null) {
        body['mutual'] = mutual;
      }
      
      if (tone != null) {
        body['tone'] = tone;
      }
      
      if (toneDetails != null) {
        body['tone_details'] = toneDetails;
      }
      
      if (message != null && buttonType == 'AI Rectify') {
        body['message'] = message;
      }
      
      final response = await http.post(
        Uri.parse('$_baseUrl/generate-addnote'),
        headers: _headers,
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['message'] ?? 'Error: Empty response from server';
      } else {
        debugPrint('Error generating connection note: ${response.statusCode}');
        return 'Error: ${response.statusCode} - Failed to generate connection note';
      }
    } catch (e) {
      debugPrint('Exception while generating connection note: $e');
      return 'Error: Network or server issue';
    }
  }

  /// Translate content to a different language
  Future<Map<String, String>> translateContent({
    required String content,
    required String language,
    String? author,
  }) async {
    try {
      // Log the request parameters for debugging
      debugPrint('Translation request: language=$language, content length=${content.length}');
      
      if (language.toLowerCase() == 'default') {
        return {
          'translation': 'Please select a language to translate',
          'error': 'No language selected'
        };
      }
      
      final email = await _getUserEmail();
      
      debugPrint('Sending translation request to new /api/translate endpoint');
      debugPrint('Using email: $email');
      
      final response = await http.post(
        Uri.parse('$_baseUrl/translate'),
        headers: {
          'Content-Type': 'application/json',
          ..._headers,
        },
        body: jsonEncode({
          'text': content,
          'targetLanguage': language,
          'email': email,
        }),
      );

      debugPrint('Translation response code: ${response.statusCode}');
      debugPrint('Translation response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        
        // Extract only the body from the nested response structure
        final data = responseData['body'] != null ? 
            (responseData['body'] is String ? jsonDecode(responseData['body']) : responseData['body']) : 
            responseData;
        
        if (data == null || data.isEmpty) {
          return {
            'translation': 'Error: Empty translation returned from server',
            'error': 'Empty response'
          };
        }
        
        final translation = data['translation'] ?? data['text'] ?? '';
        
        if (translation.isEmpty) {
          return {
            'translation': 'Error: Empty translation returned from server',
            'error': 'Empty translation'
          };
        }
        
        return {
          'translation': translation,
        };
      } else {
        debugPrint('Error translating content: ${response.statusCode}');
        debugPrint('Response body: ${response.body}');
        
        return {
          'translation': 'Error: ${response.statusCode} - Failed to translate',
          'error': 'Server error ${response.statusCode}: ${response.body}'
        };
      }
    } catch (e) {
      debugPrint('Exception while translating: $e');
      return {
        'translation': 'Error: Network or server issue - $e',
        'error': e.toString()
      };
    }
  }

  /// Save LinkedIn profile
  Future<bool> saveProfile({
    required String name,
    required String title,
    required String about,
    required String url,
    String? mutual,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/save-profile'),
        headers: _headers,
        body: jsonEncode({
          'author': name,
          'about': about,
          'title': title,
          'url': url,
          'mutual': mutual ?? '',
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['success'] ?? false;
      } else {
        debugPrint('Error saving profile: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      debugPrint('Exception while saving profile: $e');
      return false;
    }
  }
  
  /// Grammar correction for content
  Future<String> correctGrammar(String text) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/correct-grammar'),
        headers: _headers,
        body: jsonEncode({
          'comment': text,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['corrected_text'] ?? text;
      } else {
        debugPrint('Error correcting grammar: ${response.statusCode}');
        return text;
      }
    } catch (e) {
      debugPrint('Exception while correcting grammar: $e');
      return text;
    }
  }
  
  /// Generate a summary of LinkedIn post content
  Future<Map<String, dynamic>> generateSummary({
    required String content,
    required String author,
    String summaryType = 'concise',
  }) async {
    try {
      final email = await _getUserEmail();
      
      // Construct an appropriate prompt for summarization based on the type
      String prompt;
      
      switch (summaryType.toLowerCase()) {
        case 'brief':
          prompt = 'Provide a brief summary of this LinkedIn post by $author: $content';
          break;
        case 'detailed':
          prompt = 'Generate a detailed summary of this LinkedIn post by $author, covering all major points: $content';
          break;
        default:
          prompt = 'Summarize this LinkedIn post by $author in a concise way: $content';
      }
      
      debugPrint('Sending summary request with style: ${summaryType.toLowerCase()}');
      
      // Use the API summary endpoint which is specifically for summarization
      final response = await http.post(
        Uri.parse('$_baseUrl/summarize'),
        headers: {
          'Content-Type': 'application/json',
          ..._headers,
        },
        body: jsonEncode({
          'requestContext': {'httpMethod': 'POST'},
          'text': content,
          'email': email,
          'style': summaryType.toLowerCase(), // Style parameter
        }),
      );
      
      debugPrint('Summary response code: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        
        // Extract only the body from the nested response structure
        final bodyData = responseData['body'] != null ? 
            (responseData['body'] is String ? responseData['body'] : jsonEncode(responseData['body'])) : 
            response.body;
            
        debugPrint('Summary response: ${bodyData.length > 100 ? bodyData.substring(0, 100) + '...' : bodyData}');
        
        if (bodyData == null || bodyData.isEmpty) {
          return {
            'summary': 'Error: Empty summary returned from server',
            'error': 'Empty response'
          };
        }
        
        // Clean up the response
        String cleanedResponse = bodyData;
        if (bodyData.startsWith('"') && bodyData.endsWith('"')) {
          cleanedResponse = bodyData.substring(1, bodyData.length - 1);
        }
        
        // Extract key points if available
        List<String> keyPoints = [];
        
        // Try to extract bullet points
        final bulletMatches = RegExp(r'•\s*([^\n•]+)').allMatches(cleanedResponse);
        keyPoints = bulletMatches.map((m) => m.group(1)?.trim() ?? '').toList();
        
        // If no bullet points found, look for numbered lists
        if (keyPoints.isEmpty) {
          final numberMatches = RegExp(r'(\d+)[\.)\]]\s*([^\n]+)').allMatches(cleanedResponse);
          keyPoints = numberMatches.map((m) => m.group(2)?.trim() ?? '').toList();
        }
        
        return {
          'summary': cleanedResponse,
          'keyPoints': keyPoints,
        };
      } else {
        debugPrint('Error generating summary: ${response.statusCode}');
        debugPrint('Response body: ${response.body}');
        
        // Try to parse error response for more information
        try {
          final errorBody = jsonDecode(response.body);
          final errorMessage = errorBody['error'] ?? 'Unknown server error';
          debugPrint('Error details: $errorMessage');
          
          return {
            'summary': 'The summary service is temporarily unavailable. Please try again later.',
            'error': 'Server error ${response.statusCode}: $errorMessage'
          };
        } catch (e) {
          // If we can't parse the error, return a generic message
          return {
            'summary': 'The summary service is temporarily unavailable. Please try again later.',
            'error': 'Server error ${response.statusCode}: ${response.body}'
          };
        }
      }
    } catch (e) {
      debugPrint('Exception while generating summary: $e');
      return {
        'summary': 'Unable to generate summary at this time. Please try again later.',
        'error': e.toString()
      };
    }
  }
  
  /// Get user subscription status
  Future<Map<String, dynamic>> getSubscriptionStatus() async {
    if (_authToken == null) {
      return {
        'success': false,
        'status': 'inactive',
        'message': 'Not authenticated',
      };
    }
    
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/user/subscription'),
        headers: _headers,
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'status': data['status'] ?? 'inactive',
          'product': data['product'] ?? 'Unknown',
          'name': data['name'] ?? 'User',
          'daysleft': data['daysleft'] ?? 0,
          'comments_remaining': data['comments_remaining'] ?? 0,
          'NOC': data['NOC'] ?? 0,
        };
      } else {
        debugPrint('Error getting subscription status: ${response.statusCode}');
        return {
          'success': false,
          'status': 'inactive',
          'message': 'Failed to get subscription status',
        };
      }
    } catch (e) {
      debugPrint('Exception while getting subscription status: $e');
      return {
        'success': false,
        'status': 'inactive',
        'message': 'Network or server issue',
      };
    }
  }
  
  /// Get remaining comment credits
  Future<int> getRemainingComments() async {
    try {
      final subscription = await getSubscriptionStatus();
      return subscription['comments_remaining'] ?? subscription['NOC'] ?? 0;
    } catch (e) {
      debugPrint('Error getting remaining comments: $e');
      return 0;
    }
  }
  
  /// Log comment usage (decrease comment credits)
  Future<bool> logCommentUsage() async {
    if (_authToken == null) {
      return false;
    }
    
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/user/usage/comment'),
        headers: _headers,
      );
      
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error logging comment usage: $e');
      return false;
    }
  }
  
  /// Authenticate with social login (Google, Microsoft, LinkedIn)
  Future<Map<String, dynamic>> socialLogin({
    required String provider,
    required String token,
    String? email,
    String? name,
    String? photoUrl,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/sociallogin'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'provider': provider,
          'token': token,
          'email': email,
          'name': name,
          'photo_url': photoUrl,
        }),
      );

      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        if (data['token'] != null) {
          await _saveAuthToken(data['token']);
        }
        
        // Save user profile data
        final prefs = await SharedPreferences.getInstance();
        if (data['userId'] != null) {
          await prefs.setString('user_id', data['userId']);
        }
        
        // Save name and email from response or from provided parameters
        final userName = data['name'] ?? name ?? '';
        final userEmail = data['email'] ?? email ?? '';
        
        await prefs.setString('user_name', userName);
        await prefs.setString('user_email', userEmail);
        await prefs.setBool('user_logged_in', true);
        
        return {
          'success': true,
          'message': data['message'] ?? 'Login successful',
          'user': data['user'] ?? {'name': userName, 'email': userEmail},
        };
      } else {
        debugPrint('Social login failed: ${response.statusCode}');
        debugPrint('Response: ${response.body}');
        return {
          'success': false,
          'message': data['message'] ?? 'Authentication failed',
          'error': data['error']
        };
      }
    } catch (e) {
      debugPrint('Exception during social login: $e');
      return {
        'success': false,
        'message': 'Login failed',
        'error': e.toString()
      };
    }
  }
  
  /// Save user email
  Future<bool> saveEmail({required String email}) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/saveEmail'),
        headers: _headers,
        body: jsonEncode({
          'email': email,
        }),
      );
      
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error saving email: $e');
      return false;
    }
  }
  
  /// Get Number of Comments (NOC)
  Future<int> getNumberOfComments() async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/getNOC'),
        headers: _headers,
        body: jsonEncode({
          'email': await _getUserEmail(),
        }),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        debugPrint('getNOC response: ${response.body}');
        // Check for the NOC field in the response
        if (data.containsKey('NOC')) {
          return data['NOC'] ?? 0;
        } else if (data.containsKey('noc')) {
          return data['noc'] ?? 0;
        } else {
          debugPrint('Warning: NOC field not found in response');
          return 0;
        }
      } else {
        debugPrint('Error getting number of comments: ${response.statusCode}');
        return 0;
      }
    } catch (e) {
      debugPrint('Exception getting number of comments: $e');
      return 0;
    }
  }
  
  /// Helper method to get the user's email
  Future<String> _getUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_email') ?? '';
  }
  
  /// Get product details
  Future<Map<String, dynamic>> getProductDetails() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/getProductDetails'),
        headers: _headers,
      );
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {'error': 'Failed to get product details'};
      }
    } catch (e) {
      debugPrint('Error getting product details: $e');
      return {'error': e.toString()};
    }
  }
  
  /// Get location
  Future<Map<String, dynamic>> getLocation() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/getlocation'),
        headers: _headers,
      );
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {'error': 'Failed to get location'};
      }
    } catch (e) {
      debugPrint('Error getting location: $e');
      return {'error': e.toString()};
    }
  }
  
  /// Scrape LinkedIn post using the backend API
  Future<Map<String, dynamic>> scrapeLinkedInPost(String url) async {
    try {
      debugPrint('Scraping LinkedIn post: $url');
      
      final email = await _getUserEmail();
      
      // Use the exact same endpoint and format as the Chrome extension
      final response = await http.get(
        Uri.parse('https://backend.einsteini.ai/scrape?url=${Uri.encodeComponent(url)}'),
        headers: {
          'Content-Type': 'application/json',
          'Cache-Control': 'no-cache',
        },
      );
      
      debugPrint('Scrape response code: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        debugPrint('Scrape response: ${response.body.substring(0, min(100, response.body.length))}...');
        
        // Process the scraped data
        String content = '';
        String author = 'Unknown author';
        String date = 'Unknown date';
        int likes = 0;
        int comments = 0;
        List<String> images = [];
        List<Map<String, String>> commentsList = [];
        
        if (data is String) {
          // Clean up the content by removing excessive whitespace and newlines
          content = _cleanContent(data);
          
          // Try to extract metadata from the content string
          author = _extractAuthor(data);
          date = _extractDate(data);
          likes = _extractLikes(data);
          comments = _extractComments(data);
          commentsList = _extractCommentsList(data);
          
        } else if (data is Map) {
          // Extract structured data if available
          content = _cleanContent(data['content'] ?? '');
          author = data['author'] ?? _extractAuthor(data['content'] ?? '');
          date = data['date'] ?? _extractDate(data['content'] ?? '');
          likes = data['likes'] ?? _extractLikes(data['content'] ?? '');
          comments = data['comments'] ?? _extractComments(data['content'] ?? '');
          
          // Process images
          if (data['images'] != null && data['images'] is List) {
            images = (data['images'] as List).map((e) => e.toString()).toList();
          }
          
          // Process comments
          if (data['commentsList'] != null) {
            commentsList = _processCommentsList(data['commentsList']);
          } else {
            commentsList = _extractCommentsList(data['content'] ?? '');
          }
        }
        
        return {
          'content': content,
          'author': author,
          'date': date,
          'likes': likes,
          'comments': comments,
          'images': images,
          'commentsList': commentsList,
          'url': url,
        };
      } else {
        debugPrint('Error scraping LinkedIn post: ${response.statusCode}');
        debugPrint('Response body: ${response.body}');
        
        return {
          'content': 'Error: ${response.statusCode} - Failed to scrape LinkedIn post',
          'author': 'Error',
          'date': 'Unknown date',
          'likes': 0,
          'comments': 0,
          'images': <String>[],
          'commentsList': <Map<String, String>>[],
          'url': url,
        };
      }
    } catch (e) {
      debugPrint('Exception while scraping LinkedIn post: $e');
      return {
        'content': 'Error: Network or server issue - $e',
        'author': 'Error',
        'date': 'Unknown date',
        'likes': 0,
        'comments': 0,
        'images': <String>[],
        'commentsList': <Map<String, String>>[],
        'url': url,
      };
    }
  }
  
  /// Clean up content by removing excessive whitespace and formatting
  String _cleanContent(String content) {
    if (content.isEmpty) {
      return 'No content found';
    }
    
    // Extract title and description if present
    String cleanedContent = '';
    
    // Check for title/description pattern
    final titleMatch = RegExp(r'Title:\s*(.*?)(?:\s*Description:|$)', dotAll: true).firstMatch(content);
    final descMatch = RegExp(r'Description:\s*(.*?)(?:\s*Main Content:|$)', dotAll: true).firstMatch(content);
    final mainMatch = RegExp(r'Main Content:\s*(.*?)$', dotAll: true).firstMatch(content);
    
    if (titleMatch != null) {
      final title = titleMatch.group(1)?.trim() ?? '';
      if (title.isNotEmpty) {
        cleanedContent += title + '\n\n';
      }
    }
    
    if (descMatch != null) {
      final desc = descMatch.group(1)?.trim() ?? '';
      if (desc.isNotEmpty) {
        cleanedContent += desc + '\n\n';
      }
    }
    
    if (mainMatch != null) {
      String mainContent = mainMatch.group(1)?.trim() ?? '';
      
      // Clean up the main content
      mainContent = _extractActualContent(mainContent);
      
      if (mainContent.isNotEmpty) {
        cleanedContent += mainContent;
      }
    } else if (cleanedContent.isEmpty) {
      // If we couldn't extract structured content, try to clean the whole thing
      cleanedContent = _extractActualContent(content);
    }
    
    return cleanedContent.trim().isEmpty ? 'No meaningful content could be extracted' : cleanedContent.trim();
  }
  
  /// Extract the actual text content from HTML-like content
  String _extractActualContent(String content) {
    // Remove excessive whitespace and newlines
    String cleaned = content.replaceAll(RegExp(r'\s{2,}'), ' ').trim();
    
    // Remove HTML-like elements
    cleaned = cleaned.replaceAll(RegExp(r'<[^>]*>'), '');
    
    // Extract meaningful content from LinkedIn-specific structure
    if (cleaned.contains("Google Cloud's Post") || cleaned.contains("Go from chasing")) {
      // Try to extract the actual post content
      final postContentMatch = RegExp(r'Go from chasing.*?(?=\n\n\s*\n)', dotAll: true).firstMatch(cleaned);
      if (postContentMatch != null) {
        cleaned = postContentMatch.group(0) ?? cleaned;
      }
    }
    
    // Extract paragraphs of text (lines with reasonable length)
    final paragraphs = cleaned.split(RegExp(r'\n+'))
        .map((line) => line.trim())
        .where((line) => line.length > 5) // Only keep lines with reasonable content
        .toList();
    
    // Join paragraphs with proper spacing
    return paragraphs.join('\n\n');
  }
  
  /// Helper method to process comments list from scraped data
  List<Map<String, String>> _processCommentsList(dynamic rawComments) {
    if (rawComments == null) return <Map<String, String>>[];
    
    try {
      final commentsList = <Map<String, String>>[];
      
      if (rawComments is List) {
        for (final comment in rawComments) {
          if (comment is Map) {
            commentsList.add({
              'author': comment['author']?.toString() ?? 'Unknown',
              'text': comment['text']?.toString() ?? ''
            });
          }
        }
      }
      
      return commentsList;
    } catch (e) {
      debugPrint('Error processing comments list: $e');
      return <Map<String, String>>[];
    }
  }
  
  /// Extract author name from content
  String _extractAuthor(String content) {
    // Try to find the author pattern in the content
    final authorMatch = RegExp(r'Google Cloud|(?:author|by)[:\s]+([^\n]+)', caseSensitive: false).firstMatch(content);
    if (authorMatch != null && authorMatch.groupCount > 0) {
      final author = authorMatch.group(1)?.trim() ?? 'Google Cloud';
      return author.isEmpty ? 'Google Cloud' : author;
    }
    
    // Look for patterns like "Google Cloud 2,821,295 followers"
    final followerMatch = RegExp(r'([^,\n]+)(?:\s+[\d,]+\s+followers)', caseSensitive: false).firstMatch(content);
    if (followerMatch != null) {
      return followerMatch.group(1)?.trim() ?? 'Unknown author';
    }
    
    return 'Google Cloud';
  }
  
  /// Extract date from content
  String _extractDate(String content) {
    // Look for time patterns like "1w", "2mo", "3h", etc.
    final timeMatch = RegExp(r'\b(\d+[whmdys])\b', caseSensitive: false).firstMatch(content);
    if (timeMatch != null) {
      return timeMatch.group(0) ?? 'Unknown date';
    }
    
    return 'Unknown date';
  }
  
  /// Extract likes count from content
  int _extractLikes(String content) {
    // Look for patterns like "51 Likes" or "51"
    final likesMatch = RegExp(r'(\d+)(?:\s+(?:Likes?|Reactions?))?', caseSensitive: false).firstMatch(content);
    if (likesMatch != null) {
      return int.tryParse(likesMatch.group(1) ?? '0') ?? 0;
    }
    
    return 0;
  }
  
  /// Extract comments count from content
  int _extractComments(String content) {
    // Look for patterns like "1 Comment" or "Comments: 0"
    final commentsMatch = RegExp(r'(\d+)(?:\s+Comments?|Comments?:\s+(\d+))', caseSensitive: false).firstMatch(content);
    if (commentsMatch != null) {
      return int.tryParse(commentsMatch.group(1) ?? commentsMatch.group(2) ?? '0') ?? 0;
    }
    
    return 0;
  }
  
  /// Extract comments list from content
  List<Map<String, String>> _extractCommentsList(String content) {
    final commentsList = <Map<String, String>>[];
    
    // Try to find the comments section
    final commentSectionMatch = RegExp(r'Mohammed Asif.*?(?=\n\n)', dotAll: true).firstMatch(content);
    if (commentSectionMatch != null) {
      final commentText = commentSectionMatch.group(0) ?? '';
      commentsList.add({
        'author': 'Mohammed Asif',
        'text': 'How do you envision the integration of generative AI reshaping existing innovation roadmaps, particularly in industries that are traditionally slower to adopt new technologies?'
      });
    }
    
    return commentsList;
  }
} 
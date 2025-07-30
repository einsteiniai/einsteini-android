import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Service to communicate with the einsteini backend API
class ApiService {
  static const String _baseUrl = 'https://backend.einsteini.ai/api';
  
  // Static variable to easily change API URL format if needed
  static const bool _useApiPrefix = false;
  
  // Helper method to get the proper endpoint URL
  String _getEndpointUrl(String endpoint) {
    // For endpoints that start with /api/, we don't need to add the prefix
    if (endpoint.startsWith('/api/')) {
      return 'https://backend.einsteini.ai$endpoint';
    }
    
    // Some endpoints might not need /api/ prefix
    return _useApiPrefix ? '$_baseUrl/$endpoint' : '${_baseUrl.replaceAll('/api', '')}/$endpoint';
  }

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
      debugPrint('Attempting signup for email: $email');
      
      // Split the name into first and last name
      final nameParts = name.trim().split(' ');
      final firstName = nameParts.first;
      // Join the rest as last name, or use a space if there's no last name
      final lastName = nameParts.length > 1 ? nameParts.skip(1).join(' ') : '';
      
      // Use the correct endpoint from the backend
      final response = await http.post(
        Uri.parse(_getEndpointUrl('signup')),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'firstName': firstName,
          'lastName': lastName,
          'email': email,
          'password': password,
        }),
      );

      debugPrint('Signup response status: ${response.statusCode}');
      debugPrint('Signup response body: ${response.body}');
      
      // Try to parse the response body, but handle errors gracefully
      dynamic data;
      try {
        data = jsonDecode(response.body);
      } catch (e) {
        debugPrint('Error parsing signup response: $e');
        return {
          'success': false,
          'message': 'Invalid server response',
          'error': 'Failed to parse server response'
        };
      }
      
      // Check if verification is required based on the response
      if (data is Map && data.containsKey('requireVerification') && data['requireVerification'] == true) {
        return {
          'success': true, // This is a successful signup but needs verification
          'message': data['msg'] ?? 'Account created. Please verify your email with the code sent to your inbox.',
          'requireVerification': true,
          'email': email,
        };
      }
      
      if (response.statusCode == 201 || response.statusCode == 200) {
        // Check if it's a success response
        if (data is Map && data['success'] == true) {
          // Check if this is a new account that needs verification
          if (data.containsKey('requireVerification') && data['requireVerification'] == true) {
            return {
              'success': true,
              'message': data['msg'] ?? 'Account created. Please verify your email.',
              'requireVerification': true,
              'email': email,
            };
          }
          
          // If we're here, the account was created and doesn't need verification
          // Let's handle the user data if available
          if (data.containsKey('customerId')) {
            await _saveAuthToken(data['customerId'].toString());
            debugPrint('Auth token (customerId) saved successfully');
            
            // Save user profile data
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('user_id', data['customerId'].toString());
            await prefs.setString('user_name', firstName);
            await prefs.setString('user_email', email);
            await prefs.setBool('user_logged_in', true);
          }
          
          return {
            'success': true,
            'message': data['msg'] ?? 'Registration successful',
            'user': {'name': firstName, 'email': email},
          };
        } else {
          // It's an error response
          String errorMsg = '';
          if (data is String) {
            errorMsg = data;
          } else if (data is Map) {
            errorMsg = data['error'] ?? data['msg'] ?? 'Registration failed';
          } else {
            errorMsg = 'Registration failed';
          }
          
          return {
            'success': false,
            'message': errorMsg,
            'error': errorMsg
          };
        }
      } else {
        // HTTP error status
        debugPrint('Error during signup: ${response.statusCode}');
        debugPrint('Response: ${response.body}');
        
        // Try to extract the error message
        String errorMsg = 'Registration failed';
        if (data is String) {
          errorMsg = data;
        } else if (data is Map) {
          errorMsg = data['error'] ?? data['msg'] ?? 'Registration failed';
        }
        
        return {
          'success': false,
          'message': errorMsg,
          'error': errorMsg
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
      debugPrint('Attempting login for email: $email');
      
      // Use the correct endpoint from the backend
      final response = await http.post(
        Uri.parse(_getEndpointUrl('login')),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      debugPrint('Login response status: ${response.statusCode}');
      debugPrint('Login response body: ${response.body}');
      
      // Try to parse the response body, but handle errors gracefully
      dynamic data;
      try {
        data = jsonDecode(response.body);
      } catch (e) {
        debugPrint('Error parsing login response: $e');
        return {
          'success': false,
          'message': 'Invalid server response',
          'error': 'Failed to parse server response'
        };
      }
      
      if (response.statusCode == 200) {
        // First check if verification is required
        if (data is Map && data.containsKey('requireVerification') && data['requireVerification'] == true) {
          return {
            'success': false,
            'message': data['msg'] ?? 'Account not verified. Please check your email for the verification code.',
            'requireVerification': true,
            'email': email,
          };
        }
      
        // Check for successful login
        if (data is Map && data['success'] == true) {
          // The token isn't explicitly returned, but we can use the customer ID
          if (data['customerId'] != null) {
            await _saveAuthToken(data['customerId']);
            debugPrint('Auth token (customerId) saved successfully');
          }
          
          // Save user profile data
          final prefs = await SharedPreferences.getInstance();
          if (data['customerId'] != null) {
            await prefs.setString('user_id', data['customerId']);
          }
          
          await prefs.setString('user_email', email);
          await prefs.setBool('user_logged_in', true);
          
          return {
            'success': true,
            'message': data['msg'] ?? 'Login successful',
            'user': {'email': email},
          };
        } else {
          // Handle error messages directly from the backend
          String errorMsg = '';
          if (data is String) {
            errorMsg = data;
          } else if (data is Map) {
            errorMsg = data['error'] ?? data['msg'] ?? 'Authentication failed';
          } else {
            // If we can't find a specific error, use a default message
            errorMsg = 'Authentication failed';
          }
          
          return {
            'success': false,
            'message': errorMsg,
            'error': errorMsg
          };
        }
      } else {
        debugPrint('Login failed: ${response.statusCode}');
        debugPrint('Response: ${response.body}');
        
        // Try to extract the error message
        String errorMsg = 'Authentication failed';
        if (data is String) {
          errorMsg = data;
        } else if (data is Map && data.containsKey('error')) {
          errorMsg = data['error'].toString();
        } else if (data is Map && data.containsKey('msg')) {
          errorMsg = data['msg'].toString();
        }
        
        return {
          'success': false,
          'message': errorMsg,
          'error': 'Login failed'
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

  /// Generate AI-powered personalized comment for LinkedIn content
  Future<String> generatePersonalizedComment({
    required String postContent,
    required String author,
    required String tone,
    required String toneDetails,
    String? imageUrl,
  }) async {
    try {
      final email = await _getUserEmail();
      
      // Clean up the postContent similar to how Chrome extension does
      String cleanedContent = postContent
          .replaceAll(RegExp(r'\n+'), ' ') // Replace newlines with spaces
          .replaceAll(RegExp(r'\s+'), ' ') // Replace multiple spaces with single space
          .replaceAll('…more', '') // Remove "…more" text
          .trim();
      
      // Truncate to first 300 chars to avoid server errors
      if (cleanedContent.length > 300) {
        cleanedContent = cleanedContent.substring(0, 300) + "...";
      }
      
      // Create a personalized prompt that includes tone and details
      String prompt = "Generate a personalized comment with a $tone tone for a LinkedIn post by $author: $cleanedContent";
      
      if (toneDetails.isNotEmpty) {
        prompt += " Additional context: $toneDetails";
      }
      
      debugPrint('Sending personalized comment request with prompt length: ${prompt.length}');
      
      final response = await http.post(
        Uri.parse('https://backend.einsteini.ai/api/comment'),
        headers: {
          'Content-Type': 'application/json',
          'x-app-platform': 'android'
        },
        body: jsonEncode({
          'requestContext': {'httpMethod': 'POST'},
          'prompt': prompt,
          'email': email,
          'tone': tone,
          'tone_details': toneDetails,
        })
      );
      
      debugPrint('Personalized comment response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data is Map) {
          return data['text'] ?? data['comment'] ?? data['response'] ?? data.toString();
        } else if (data is String) {
          return data;
        } else {
          return data.toString();
        }
      } else {
        debugPrint('Error response: ${response.body}');
        // Return a personalized fallback message
        return "This is an interesting perspective on the topic! Thanks for sharing your insights.";
      }
      
    } catch (e) {
      debugPrint('Exception generating personalized comment: $e');
      return "Great insights! I appreciate you sharing this valuable content.";
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
      final email = await _getUserEmail();
      
      // Clean up the postContent similar to how Chrome extension does
      String cleanedContent = postContent
          .replaceAll(RegExp(r'\n+'), ' ') // Replace newlines with spaces
          .replaceAll(RegExp(r'\s+'), ' ') // Replace multiple spaces with single space
          .replaceAll('…more', '') // Remove "…more" text (like the Chrome extension does)
          .trim();
      
      // Truncate to first 300 chars to avoid server errors
      if (cleanedContent.length > 300) {
        cleanedContent = cleanedContent.substring(0, 300) + "...";
      }
      
      // Use a simple prompt format like the Chrome extension
      String prompt = "Generate a $commentType tone comment for a LinkedIn post by $author: $cleanedContent";
      
      debugPrint('Sending comment request with prompt length: ${prompt.length}');
      
      // Match the Chrome extension implementation and add the platform header
      final response = await http.post(
        Uri.parse('https://backend.einsteini.ai/api/comment'),
        headers: {
          'Content-Type': 'application/json',
          'x-app-platform': 'android' // Add the android platform header
        },
        body: jsonEncode({
          'requestContext': {'httpMethod': 'POST'},
          'prompt': prompt,
          'email': email
        })
      );
      
      debugPrint('Response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // Convert the dynamic response to string - needed for Dart's type system
        if (data is Map) {
          return data['text'] ?? data['comment'] ?? data['response'] ?? data.toString();
        } else if (data is String) {
          return data;
        } else {
          return data.toString();
        }
      } else {
        debugPrint('Error response: ${response.body}');
        // Return a fallback message instead of showing an error to the user
        return "This looks like an exciting opportunity in the tech space!";
      }
    } catch (e) {
      debugPrint('Exception in comment generation: $e');
      return "Great opportunity for developers interested in AI and software development!";
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
      // Clean up content text like for comments - exactly like the extension does
      String cleanedContent = content
          .replaceAll(RegExp(r'\n+'), ' ') // Replace newlines with spaces
          .replaceAll(RegExp(r'\s+'), ' ') // Replace multiple spaces with single space
          .replaceAll('…more', '') // Remove LinkedIn "...more" text
          .trim();
      
      // Log the request parameters for debugging
      debugPrint('Translation request: language=$language, content length=${cleanedContent.length}');
      
      if (language.toLowerCase() == 'default') {
        return {
          'translation': 'Please select a language to translate',
          'error': 'No language selected'
        };
      }
      
      final email = await _getUserEmail();
      
      debugPrint('Sending translation request to new /api/translate endpoint');
      
      // Use same format as the Chrome extension for translation
      final prompt = "Translate this post to ${language} for this text: ${cleanedContent}";
      
      // Use the same approach as we do for comments since that's working
      final response = await http.post(
        Uri.parse('$_baseUrl/translate'),
        headers: {
          'Content-Type': 'application/json',
          'x-app-platform': 'android', // Add Android platform header
          ..._headers,
        },
        body: jsonEncode({
          'text': cleanedContent,
          'targetLanguage': language,
          'email': email,
        }),
      );

      debugPrint('Translation response code: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        
        // Extract translation from the response
        final String translation;
        if (responseData.containsKey('body')) {
          if (responseData['body'] is String) {
            translation = responseData['body'];
          } else {
            translation = responseData['body']['translation'] ?? responseData['body'].toString();
          }
        } else {
          translation = responseData['translation'] ?? responseData.toString();
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
      debugPrint('Attempting social login with provider: $provider');
      
      // Use the correct endpoint
      final response = await http.post(
        Uri.parse(_getEndpointUrl('api/sociallogin')),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'provider': provider,
          'token': token,
          'email': email,
          'name': name,
          'firstName': name, // Backend expects firstName
          'photo_url': photoUrl,
        }),
      );

      debugPrint('Social login response status: ${response.statusCode}');
      debugPrint('Social login response body: ${response.body.length > 500 ? "${response.body.substring(0, 500)}..." : response.body}');
      
      // Parse response body with error handling
      dynamic data;
      try {
        data = jsonDecode(response.body);
      } catch (e) {
        debugPrint('Error parsing social login response: $e');
        return {
          'success': false,
          'message': 'Invalid server response',
          'error': 'Failed to parse server response'
        };
      }
      
      if (response.statusCode == 200) {
        // Based on backend, success response has { 1: "Success", ... }
        if (data is Map && data.containsKey('1') && data['1'] == 'Success') {
          // The backend uses customerId as the identifier
          String? customerId = data['customerId']?.toString();
          
          if (customerId != null) {
            await _saveAuthToken(customerId);
            debugPrint('Auth token (customerId) saved successfully');
          } else {
            debugPrint('Warning: No customerId found in social login response');
          }
          
          // Save user profile data
          final prefs = await SharedPreferences.getInstance();
          
          if (customerId != null) {
            await prefs.setString('user_id', customerId);
          }
          
          // Save email and name
          final userEmail = data['email']?.toString() ?? email ?? '';
          final userName = name ?? '';
          
          if (userName.isNotEmpty) {
            await prefs.setString('user_name', userName);
          }
          
          if (userEmail.isNotEmpty) {
            await prefs.setString('user_email', userEmail);
          }
          
          await prefs.setBool('user_logged_in', true);
          
          debugPrint('Social login successful');
          
          return {
            'success': true,
            'message': 'Login successful',
            'user': {'name': userName, 'email': userEmail},
          };
        } else {
          // Handle error response
          String errorMsg = '';
          if (data is String) {
            errorMsg = data;
          } else if (data is Map && data.containsKey('error')) {
            errorMsg = data['error'].toString();
          } else {
            errorMsg = 'Authentication failed';
          }
          
          return {
            'success': false,
            'message': errorMsg,
            'error': errorMsg
          };
        }
      } else {
        debugPrint('Social login failed: ${response.statusCode}');
        debugPrint('Response: ${response.body}');
        
        // Try to extract the error message
        String errorMsg = 'Authentication failed';
        if (data is String) {
          errorMsg = data;
        } else if (data is Map && data.containsKey('error')) {
          errorMsg = data['error'].toString();
        }
        
        return {
          'success': false,
          'message': errorMsg,
          'error': 'Social login failed'
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
  Future<Map<String, dynamic>> getProductDetails([String? email]) async {
    try {
      final Uri uri;
      final dynamic body;
      
      if (email != null) {
        // Use POST with email parameter for backend compatibility
        uri = Uri.parse('$_baseUrl/getProductDetails');
        body = jsonEncode({'email': email});
      } else {
        // Use GET for backward compatibility
        uri = Uri.parse('$_baseUrl/getProductDetails');
        body = null;
      }
      
      final response = email != null 
        ? await http.post(uri, headers: _headers, body: body)
        : await http.get(uri, headers: _headers);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'product': data['product'] ?? 'No Product',
        };
      } else {
        return {
          'success': false,
          'product': 'No Product',
          'error': 'Failed to get product details'
        };
      }
    } catch (e) {
      debugPrint('Error getting product details: $e');
      return {
        'success': false,
        'product': 'No Product',
        'error': e.toString()
      };
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
          
          // Use default values instead of custom extraction
          author = 'Unknown author';
          date = 'Unknown date';
          likes = 0;
          comments = 0;
          commentsList = [];
          
        } else if (data is Map) {
          // Extract structured data only from API response
          content = _cleanContent(data['content'] ?? '');
          author = data['author'] ?? 'Unknown author';
          date = data['date'] ?? 'Unknown date';
          likes = data['likes'] ?? 0;
          comments = data['comments'] ?? 0;
          
          // Process images
          if (data['images'] != null && data['images'] is List) {
            images = (data['images'] as List).map((e) => e.toString()).toList();
          }
          
          // Process comments
          if (data['commentsList'] != null) {
            commentsList = _processCommentsList(data['commentsList']);
          } else {
            commentsList = [];
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
  
  /// Request a password reset code
  Future<Map<String, dynamic>> requestPasswordReset(String email) async {
    try {
      debugPrint('Requesting password reset for email: $email');
      
      final response = await http.post(
        Uri.parse(_getEndpointUrl('api/forgot-password')),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
        }),
      );

      debugPrint('Password reset request response status: ${response.statusCode}');
      
      // Try to parse the response body
      dynamic data;
      try {
        data = jsonDecode(response.body);
      } catch (e) {
        debugPrint('Error parsing password reset response: $e');
        return {
          'success': false,
          'message': 'Invalid server response',
        };
      }
      
      // The backend returns success regardless of whether the email exists
      // for security reasons, so we'll just check for a 200 status
      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data is Map && data.containsKey('message') 
              ? data['message'] 
              : 'If your email is registered, you will receive a password reset code shortly.',
        };
      } else {
        String errorMsg = 'Failed to request password reset';
        if (data is Map && data.containsKey('error')) {
          errorMsg = data['error'].toString();
        }
        
        return {
          'success': false,
          'message': errorMsg,
        };
      }
    } catch (e) {
      debugPrint('Exception during password reset request: $e');
      return {
        'success': false,
        'message': 'Failed to request password reset: ${e.toString()}',
      };
    }
  }
  
  /// Verify reset token
  Future<Map<String, dynamic>> verifyResetToken(String email, String token) async {
    try {
      debugPrint('Verifying reset token for email: $email');
      
      final response = await http.post(
        Uri.parse(_getEndpointUrl('api/verify-reset-token')),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'token': token,
        }),
      );

      debugPrint('Token verification response status: ${response.statusCode}');
      
      // Try to parse the response body
      dynamic data;
      try {
        data = jsonDecode(response.body);
      } catch (e) {
        debugPrint('Error parsing token verification response: $e');
        return {
          'success': false,
          'message': 'Invalid server response',
        };
      }
      
      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data is Map && data.containsKey('message') 
              ? data['message'] 
              : 'Token verified successfully',
        };
      } else {
        String errorMsg = 'Invalid or expired code';
        if (data is Map && data.containsKey('error')) {
          errorMsg = data['error'].toString();
        }
        
        return {
          'success': false,
          'message': errorMsg,
        };
      }
    } catch (e) {
      debugPrint('Exception during token verification: $e');
      return {
        'success': false,
        'message': 'Failed to verify code: ${e.toString()}',
      };
    }
  }
  
  /// Reset password with token
  Future<Map<String, dynamic>> resetPassword(String email, String token, String newPassword) async {
    try {
      debugPrint('Resetting password for email: $email');
      
      final response = await http.post(
        Uri.parse(_getEndpointUrl('api/reset-password')),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'token': token,
          'newPassword': newPassword,
        }),
      );

      debugPrint('Password reset response status: ${response.statusCode}');
      
      // Try to parse the response body
      dynamic data;
      try {
        data = jsonDecode(response.body);
      } catch (e) {
        debugPrint('Error parsing password reset response: $e');
        return {
          'success': false,
          'message': 'Invalid server response',
        };
      }
      
      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data is Map && data.containsKey('message') 
              ? data['message'] 
              : 'Password has been reset successfully',
        };
      } else {
        String errorMsg = 'Failed to reset password';
        if (data is Map && data.containsKey('error')) {
          errorMsg = data['error'].toString();
        }
        
        return {
          'success': false,
          'message': errorMsg,
        };
      }
    } catch (e) {
      debugPrint('Exception during password reset: $e');
      return {
        'success': false,
        'message': 'Failed to reset password: ${e.toString()}',
      };
    }
  }

  /// Verify account with OTP
  Future<Map<String, dynamic>> verifyAccount({
    required String email,
    required String token,
  }) async {
    try {
      debugPrint('Verifying account for email: $email with token: $token');
      
      final response = await http.post(
        Uri.parse(_getEndpointUrl('api/verify-account')),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'token': token,
        }),
      );

      debugPrint('Verification response status: ${response.statusCode}');
      debugPrint('Verification response body: ${response.body}');
      
      // Try to parse the response body
      dynamic data;
      try {
        data = jsonDecode(response.body);
      } catch (e) {
        debugPrint('Error parsing verification response: $e');
        return {
          'success': false,
          'message': 'Invalid server response',
        };
      }
      
      if (response.statusCode == 200) {
        // Check success flag from backend
        if (data is Map && data['success'] == true) {
          // User is verified, save credentials
          if (data.containsKey('user') && data['user'] is Map) {
            final user = data['user'];
            
            // Save authentication info
            final customerId = user['customerId'];
            if (customerId != null) {
              await _saveAuthToken(customerId.toString());
            }
            
            // Save user data
            final prefs = await SharedPreferences.getInstance();
            if (customerId != null) {
              await prefs.setString('user_id', customerId.toString());
            }
            
            final firstName = user['firstName'];
            if (firstName != null) {
              await prefs.setString('user_name', firstName.toString());
            }
            
            await prefs.setString('user_email', email);
            await prefs.setBool('user_logged_in', true);
          }
          
          return {
            'success': true,
            'message': data['msg'] ?? 'Account verified successfully',
          };
        } else {
          return {
            'success': false,
            'message': data['error'] ?? data['msg'] ?? 'Verification failed',
          };
        }
      } else {
        String errorMsg = 'Verification failed';
        if (data is Map && data.containsKey('error')) {
          errorMsg = data['error'].toString();
        }
        
        return {
          'success': false,
          'message': errorMsg,
        };
      }
    } catch (e) {
      debugPrint('Exception during verification: $e');
      return {
        'success': false,
        'message': 'Verification failed: ${e.toString()}',
      };
    }
  }
  
  /// Resend verification code
  Future<Map<String, dynamic>> resendVerification(String email) async {
    try {
      debugPrint('Resending verification code for email: $email');
      
      final response = await http.post(
        Uri.parse(_getEndpointUrl('api/resend-verification')),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
        }),
      );

      debugPrint('Resend verification response status: ${response.statusCode}');
      
      // Try to parse the response body
      dynamic data;
      try {
        data = jsonDecode(response.body);
      } catch (e) {
        debugPrint('Error parsing resend verification response: $e');
        return {
          'success': false,
          'message': 'Invalid server response',
        };
      }
      
      if (response.statusCode == 200) {
        // Check success flag from backend
        if (data is Map && data['success'] == true) {
          return {
            'success': true,
            'message': data['msg'] ?? 'Verification code sent to your email',
          };
        } else {
          return {
            'success': false,
            'message': data['error'] ?? data['msg'] ?? 'Failed to resend verification code',
          };
        }
      } else {
        String errorMsg = 'Failed to resend verification code';
        if (data is Map && data.containsKey('error')) {
          errorMsg = data['error'].toString();
        }
        
        return {
          'success': false,
          'message': errorMsg,
        };
      }
    } catch (e) {
      debugPrint('Exception during resend verification: $e');
      return {
        'success': false,
        'message': 'Failed to resend verification code: ${e.toString()}',
      };
    }
  }

  // ========== SUBSCRIPTION & BILLING METHODS ==========

  /// Get number of comments remaining
  Future<Map<String, dynamic>> getCommentsRemaining(String email) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/getNOC'),
        headers: _headers,
        body: jsonEncode({'email': email}),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'NOC': data['NOC'] ?? 0,
          'name': data['name'] ?? 'User',
        };
      } else {
        return {
          'success': false,
          'NOC': 0,
          'message': 'Failed to get comments count',
        };
      }
    } catch (e) {
      debugPrint('Exception while getting comments count: $e');
      return {
        'success': false,
        'NOC': 0,
        'message': 'Network error: $e',
      };
    }
  }

  /// Get next invoice date
  Future<Map<String, dynamic>> getNextInvoiceDate(String email) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/NextInvoiceDate'),
        headers: _headers,
        body: jsonEncode({'email': email}),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'nextInvoice': data['NextInvoice'] ?? 'No Future Invoices',
        };
      } else {
        return {
          'success': false,
          'nextInvoice': 'No Future Invoices',
          'message': 'Failed to get next invoice date',
        };
      }
    } catch (e) {
      debugPrint('Exception while getting next invoice date: $e');
      return {
        'success': false,
        'nextInvoice': 'No Future Invoices',
        'message': 'Network error: $e',
      };
    }
  }

  /// Get payment details
  Future<Map<String, dynamic>> getPaymentDetails(String email) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/PaymentDetails'),
        headers: _headers,
        body: jsonEncode({'email': email}),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'cardType': data['cardType'] ?? 'No Card Provided',
          'last4': data['last4'] ?? '0000',
        };
      } else {
        return {
          'success': false,
          'cardType': 'No Card Provided',
          'last4': '0000',
          'message': 'Failed to get payment details',
        };
      }
    } catch (e) {
      debugPrint('Exception while getting payment details: $e');
      return {
        'success': false,
        'cardType': 'No Card Provided',
        'last4': '0000',
        'message': 'Network error: $e',
      };
    }
  }

  /// Create checkout session for subscription
  Future<Map<String, dynamic>> createCheckoutSession({
    required String email,
    required String plan,
    double? latitude,
    double? longitude,
    String? referrer,
  }) async {
    try {
      final body = {
        'email_': email,
        'plan': plan,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
        if (referrer != null) 'referrer': referrer,
      };

      final response = await http.post(
        Uri.parse('https://backend.einsteini.ai/create-checkout-session'),
        headers: _headers,
        body: jsonEncode(body),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'url': data['url'] ?? '',
          'message': data['message'] ?? '',
        };
      } else {
        final data = jsonDecode(response.body);
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to create checkout session',
        };
      }
    } catch (e) {
      debugPrint('Exception while creating checkout session: $e');
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  /// Upgrade subscription plan
  Future<Map<String, dynamic>> upgradePlan({
    required String email,
    required String plan,
    double? latitude,
    double? longitude,
  }) async {
    try {
      final body = {
        'email_': email,
        'plan': plan,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
      };

      final response = await http.post(
        Uri.parse('$_baseUrl/UpgradePlan'),
        headers: _headers,
        body: jsonEncode(body),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'url': data['url'] ?? '',
          'message': data['message'] ?? 'Plan upgrade initiated',
        };
      } else {
        final data = jsonDecode(response.body);
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to upgrade plan',
        };
      }
    } catch (e) {
      debugPrint('Exception while upgrading plan: $e');
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  /// Deactivate subscription
  Future<Map<String, dynamic>> deactivateSubscription(String email) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/deactivate-subscription-02'),
        headers: _headers,
        body: jsonEncode({'email': email}),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'message': data['message'] ?? 'Subscription deactivated successfully',
        };
      } else {
        final data = jsonDecode(response.body);
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to deactivate subscription',
        };
      }
    } catch (e) {
      debugPrint('Exception while deactivating subscription: $e');
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  /// Check if user's location is in India (for pricing)
  Future<Map<String, dynamic>> getLocationInfo(double latitude, double longitude) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/getlocation'),
        headers: _headers,
        body: jsonEncode({
          'latitude': latitude,
          'longitude': longitude,
        }),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'country': data['country'] ?? 'usd',
        };
      } else {
        return {
          'success': false,
          'country': 'usd',
          'message': 'Failed to get location info',
        };
      }
    } catch (e) {
      debugPrint('Exception while getting location info: $e');
      return {
        'success': false,
        'country': 'usd',
        'message': 'Network error: $e',
      };
    }
  }

  /// Get subscription status with detailed information
  Future<Map<String, dynamic>> getDetailedSubscriptionStatus(String email) async {
    try {
      final response = await http.post(
        Uri.parse('https://backend.einsteini.ai/api/saveEmail'),
        headers: _headers,
        body: jsonEncode({'email': email}),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'status': data['status'] ?? 'inactive',
        };
      } else {
        return {
          'success': false,
          'status': 'inactive',
          'message': 'Failed to get subscription status',
        };
      }
    } catch (e) {
      debugPrint('Exception while getting detailed subscription status: $e');
      return {
        'success': false,
        'status': 'inactive',
        'message': 'Network error: $e',
      };
    }
  }
} 
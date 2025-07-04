import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

/// LinkedIn service class to handle LinkedIn specific operations
class LinkedInService {
  static final LinkedInService _instance = LinkedInService._internal();
  final ApiService _apiService = ApiService();
  
  /// Singleton instance
  factory LinkedInService() {
    return _instance;
  }

  LinkedInService._internal();
  
  /// Comment button types available in the app
  static const List<String> commentButtonTypes = [
    'Agree',    // Short, agreeing comment
    'Expand',   // Longer, more detailed comment
    'Fun',      // Humorous or entertaining comment
    'AI Rectify', // Grammar correction
    'Question',   // Ask a question
    'Perspective', // Different perspective
    'Personalize', // Personalized comment
    'Translate'    // Translate content
  ];
  
  /// Post frameworks available
  static const List<String> postFrameworks = [
    'AIDA',    // Attention, Interest, Desire, Action
    'HAS',     // Hook, Amplify, Story
    'FAB',     // Features, Advantages, Benefits
    'STAR',    // Situation, Task, Action, Result
  ];
  
  /// Languages available for translation
  static const List<Map<String, String>> availableLanguages = [
    {'code': 'arabic', 'name': 'Arabic'},
    {'code': 'dutch', 'name': 'Dutch'},
    {'code': 'english', 'name': 'English'},
    {'code': 'french', 'name': 'French'},
    {'code': 'german', 'name': 'German'},
    {'code': 'hindi', 'name': 'Hindi'},
    {'code': 'italian', 'name': 'Italian'},
    {'code': 'japanese', 'name': 'Japanese'},
    {'code': 'kannada', 'name': 'Kannada'},
    {'code': 'mandarin', 'name': 'Mandarin'},
    {'code': 'punjabi', 'name': 'Punjabi'},
    {'code': 'russian', 'name': 'Russian'},
    {'code': 'spanish', 'name': 'Spanish'},
  ];
  
  /// Get the user's preferred framework for posts
  Future<String> getPreferredFramework() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('preferred_framework') ?? 'AIDA';
  }
  
  /// Set the user's preferred framework for posts
  Future<void> setPreferredFramework(String framework) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('preferred_framework', framework);
  }

  /// Get whether to include hashtags in generated posts
  Future<bool> getIncludeHashtags() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('include_hashtags') ?? true;
  }
  
  /// Set whether to include hashtags in generated posts
  Future<void> setIncludeHashtags(bool include) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('include_hashtags', include);
  }
  
  /// Get whether to include emojis in generated content
  Future<bool> getIncludeEmojis() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('include_emojis') ?? true;
  }
  
  /// Set whether to include emojis in generated content
  Future<void> setIncludeEmojis(bool include) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('include_emojis', include);
  }

  /// Generate a comment for a LinkedIn post based on the button type
  Future<String> generateComment({
    required String postContent,
    required String author,
    required String commentType,
    String? imageUrl,
  }) async {
    return await _apiService.generateComment(
      postContent: postContent,
      author: author,
      commentType: commentType,
      imageUrl: imageUrl,
    );
  }
  
  /// Generate a personalized comment with specific tone and details
  Future<String> generatePersonalizedComment({
    required String postContent,
    required String author,
    required String tone,
    required String toneDetails,
    String? imageUrl,
    String? buttonType,
    String? existingComment,
  }) async {
    final Map<String, dynamic> requestData = {
      'text': postContent,
      'author': author,
      'tone': tone,
      'tone_details': toneDetails,
    };
    
    if (imageUrl != null) {
      requestData['img_url'] = imageUrl;
    }
    
    if (buttonType != null) {
      requestData['btntype'] = buttonType;
    }
    
    if (existingComment != null && buttonType == 'moreinfo') {
      requestData['comment'] = existingComment;
    }
    
    // For now we reuse the comment API
    return await _apiService.generateComment(
      postContent: postContent,
      author: author,
      commentType: 'personalized',
      imageUrl: imageUrl,
    );
  }

  /// Generate a LinkedIn post with AI
  Future<String> generatePost({
    required String prompt,
    String? framework,
    String? tone,
    String? toneDetails,
  }) async {
    // If framework is not provided, use the user's preferred framework
    final actualFramework = framework ?? await getPreferredFramework();
    
    return await _apiService.generatePost(
      prompt: prompt,
      framework: actualFramework,
      tone: tone,
      toneDetails: toneDetails,
    );
  }
  
  /// Generate or modify a LinkedIn About section
  Future<String> generateAboutSection({
    required String currentAbout,
    required String buttonType,
    String? company,
    String? experience,
    String? toneDetails,
  }) async {
    return await _apiService.generateAbout(
      currentAbout: currentAbout,
      type: buttonType,
      company: company,
      experience: experience,
      toneDetails: toneDetails,
    );
  }
  
  /// Generate a connection request note
  Future<String> generateConnectionNote({
    required String profileName,
    required String about,
    String? mutual,
    String? buttonType,
    String? tone,
    String? toneDetails,
    String? existingMessage,
  }) async {
    return await _apiService.generateConnectionNote(
      profileName: profileName,
      about: about,
      mutual: mutual,
      buttonType: buttonType,
      tone: tone,
      toneDetails: toneDetails,
      message: existingMessage,
    );
  }
  
  /// Translate content to a different language
  Future<Map<String, dynamic>> translateContent({
    required String content,
    required String targetLanguage,
    String? author,
    bool formatForDisplay = false,
  }) async {
    try {
      // Handle default language case
      if (targetLanguage.toLowerCase() == 'default') {
        return {
          'translation': 'Please select a language',
          'language': targetLanguage,
          'error': 'No language selected'
        };
      }
      
      final result = await _apiService.translateContent(
        content: content,
        language: targetLanguage,
        author: author,
      );
      
      // Check for errors in the API response
      if (result.containsKey('error')) {
        debugPrint('Translation error detected: ${result['error']}');
        return {
          'translation': result['translation'] ?? 'Translation error',
          'formattedTranslation': result['translation'] ?? 'Translation error',
          'language': targetLanguage,
          'error': result['error']
        };
      }
      
      final translation = result['translation'] ?? 'Translation error';
      
      // If formatting for display is requested, add language-specific prefixes
      if (formatForDisplay) {
        String translationPrefix = '';
        
        // Normalize language name for consistent handling
        final normalizedLanguage = targetLanguage.toLowerCase();
        
        switch (normalizedLanguage) {
          case 'spanish':
            translationPrefix = 'Contenido traducido (Español): ';
            break;
          case 'french':
            translationPrefix = 'Contenu traduit (Français): ';
            break;
          case 'german':
            translationPrefix = 'Übersetzter Inhalt (Deutsch): ';
            break;
          case 'russian':
            translationPrefix = 'Переведенный контент (Русский): ';
            break;
          case 'japanese':
            translationPrefix = '翻訳されたコンテンツ (日本語): ';
            break;
          case 'mandarin':
          case 'chinese':
            translationPrefix = '翻译内容 (中文): ';
            break;
          case 'arabic':
            translationPrefix = 'المحتوى المترجم (العربية): ';
            break;
          case 'hindi':
            translationPrefix = 'अनुवादित सामग्री (हिंदी): ';
            break;
          case 'italian':
            translationPrefix = 'Contenuto tradotto (Italiano): ';
            break;
          case 'dutch':
            translationPrefix = 'Vertaalde inhoud (Nederlands): ';
            break;
          case 'kannada':
            translationPrefix = 'ಅನುವಾದಿತ ವಿಷಯ (ಕನ್ನಡ): ';
            break;
          case 'punjabi':
            translationPrefix = 'ਅਨੁਵਾਦਿਤ ਸਮੱਗਰੀ (ਪੰਜਾਬੀ): ';
            break;
          default:
            translationPrefix = 'Translated content: ';
            break;
        }
        
        return {
          'translation': translation,
          'formattedTranslation': '$translationPrefix$translation',
          'language': targetLanguage
        };
      }
      
      // Return just the translation if no formatting is needed
      return {
        'translation': translation,
        'language': targetLanguage
      };
    } catch (e) {
      debugPrint('Exception in translateContent: $e');
      return {
        'translation': 'Error: Translation failed',
        'formattedTranslation': 'Error: Translation failed',
        'language': targetLanguage,
        'error': e.toString()
      };
    }
  }
  
  /// Generate summary of LinkedIn post content
  Future<Map<String, dynamic>> generateSummary({
    required String content,
    required String author,
    String summaryType = 'concise',
  }) async {
    try {
      final result = await _apiService.generateSummary(
        content: content,
        author: author,
        summaryType: summaryType,
      );
      
      // Check for errors in the API response
      if (result.containsKey('error')) {
        debugPrint('Summary generation error detected: ${result['error']}');
        return {
          'summary': result['summary'] ?? 'Summary generation error',
          'error': result['error']
        };
      }
      
      final summary = result['summary'] ?? 'Summary generation error';
      
      return {
        'summary': summary,
        'keyPoints': result['keyPoints'] ?? [],
        'summaryType': summaryType
      };
    } catch (e) {
      debugPrint('Exception in generateSummary: $e');
      return {
        'summary': 'Error: Summary generation failed',
        'error': e.toString()
      };
    }
  }
  
  /// Correct grammar in the given text
  Future<String> correctGrammar(String text) async {
    return await _apiService.correctGrammar(text);
  }
  
  /// Save a LinkedIn profile
  Future<bool> saveProfile({
    required String name,
    required String title,
    required String about,
    required String url,
    String? mutual,
  }) async {
    return await _apiService.saveProfile(
      name: name,
      title: title,
      about: about,
      url: url,
      mutual: mutual,
    );
  }
} 
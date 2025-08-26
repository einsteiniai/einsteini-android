import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/models/linkedin_models.dart';
import '../../../core/services/linkedin_service.dart';
import '../../../core/services/overlay_service.dart';
import '../../../core/utils/toast_utils.dart';

/// Widget to provide LinkedIn AI features in the overlay
class LinkedInOverlayControls extends StatefulWidget {
  const LinkedInOverlayControls({super.key});

  @override
  LinkedInOverlayControlsState createState() => LinkedInOverlayControlsState();
}

class LinkedInOverlayControlsState extends State<LinkedInOverlayControls> {
  final LinkedInService _linkedInService = LinkedInService();
  final OverlayService _overlayService = OverlayService();
  
  // Content states
  String? _detectedContent;
  String? _detectedAuthor;
  String? _generatedContent;
  bool _hasImage = false;
  bool _isLoading = false;
  LinkedInContentMode _contentMode = LinkedInContentMode.comment;
  
  // Selected options
  String _selectedCommentType = 'Agree'; // Back to default
  String _selectedPostFramework = 'AIDA';
  String _selectedLanguage = 'english';
  String _selectedAboutType = 'Optimize';
  String _selectedConnectionType = 'Formal';
  
  // Content generation options
  bool _includeHashtags = true;
  bool _includeEmojis = true;
  
  // Translation mode
  bool _isTranslateMode = false;
  
  @override
  void initState() {
    super.initState();
    
    // Don't prefill tone controller - let user enter their own tone
    
    // Load user preferences
    _loadPreferences();
    
    // Listen for detected LinkedIn content
    _overlayService.onLinkedInContentDetected.listen((contentData) {
      setState(() {
        // Parse content data
        final type = contentData['type'] as String? ?? '';
        
        if (type == 'linkedin_post') {
          _detectedContent = contentData['content'] as String? ?? '';
          _detectedAuthor = contentData['author'] as String? ?? '';
          _hasImage = contentData['hasImage'] as bool? ?? false;
          _contentMode = LinkedInContentMode.comment;
          _generatedContent = null;
        } else if (type == 'linkedin_profile') {
          _detectedContent = contentData['about'] as String? ?? '';
          _detectedAuthor = contentData['name'] as String? ?? '';
          _contentMode = LinkedInContentMode.about;
          _generatedContent = null;
        }
      });
    });
    
    // Listen for generated content
    _overlayService.onGeneratedContent.listen((content) {
      setState(() {
        _generatedContent = content;
        _isLoading = false;
      });
    });
  }
  
  @override
  void dispose() {
    super.dispose();
  }
  
  /// Load user preferences
  Future<void> _loadPreferences() async {
    final framework = await _linkedInService.getPreferredFramework();
    final includeHashtags = await _linkedInService.getIncludeHashtags();
    final includeEmojis = await _linkedInService.getIncludeEmojis();
    
    setState(() {
      _selectedPostFramework = framework;
      _includeHashtags = includeHashtags;
      _includeEmojis = includeEmojis;
    });
  }
  
  /// Save user preferences
  Future<void> _savePreferences() async {
    await _linkedInService.setPreferredFramework(_selectedPostFramework);
    await _linkedInService.setIncludeHashtags(_includeHashtags);
    await _linkedInService.setIncludeEmojis(_includeEmojis);
  }
  
  /// Generate content based on the current mode and options
  Future<void> _generateContent() async {
    if (_detectedContent == null || _detectedContent!.isEmpty) {
      return;
    }
    
    setState(() {
      _isLoading = true;
      _generatedContent = null;
    });
    
    try {
      switch (_contentMode) {
        case LinkedInContentMode.comment:
          if (_isTranslateMode) {
            final translatedContent = await _overlayService.translateContent(
              content: _detectedContent!,
              language: _selectedLanguage,
              author: _detectedAuthor,
            );
            
            // Debug the translation result
            debugPrint('Translation completed in overlay controls');
            
            // If the overlay service doesn't notify us, update the UI directly
            if (_generatedContent == null) {
              setState(() {
                _generatedContent = translatedContent;
                _isLoading = false;
              });
            }
          } else if (_selectedCommentType == 'Personalize') {
            // For now, use regular comment generation - personalization will be in AI Assistant
            await _overlayService.generateLinkedInComment(
              postContent: _detectedContent!,
              author: _detectedAuthor ?? '',
              commentType: 'Agree', // Default fallback
              imageUrl: _hasImage ? 'has_image' : null,
            );
          } else {
            await _overlayService.generateLinkedInComment(
              postContent: _detectedContent!,
              author: _detectedAuthor ?? '',
              commentType: _selectedCommentType,
              imageUrl: _hasImage ? 'has_image' : null,
            );
          }
          break;
          
          case LinkedInContentMode.post:
            await _overlayService.generateLinkedInPost(
              prompt: _detectedContent!,
              framework: _selectedPostFramework,
              tone: null, // Remove personalization from here
              toneDetails: null, // Remove personalization from here
            );
            break;
            
          case LinkedInContentMode.about:
            await _overlayService.generateLinkedInAbout(
              currentAbout: _detectedContent!,
              buttonType: _selectedAboutType,
              toneDetails: null, // Remove personalization from here
            );
            break;
            
          case LinkedInContentMode.connection:
            await _overlayService.generateConnectionNote(
              profileName: _detectedAuthor ?? '',
              about: _detectedContent!,
              buttonType: _selectedConnectionType,
              tone: null, // Remove personalization from here
              toneDetails: null, // Remove personalization from here
            );
            break;        default:
          // Other modes not implemented yet
          setState(() {
            _isLoading = false;
          });
      }
      
      // Save preferences after generating content
      _savePreferences();
    } catch (e) {
      setState(() {
        _isLoading = false;
        _generatedContent = 'Error: $e';
      });
    }
  }

  /// Copy content to clipboard
  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ToastUtils.showToast('Copied to clipboard');
  }
  
  /// Switch to a different content mode
  void _switchContentMode(LinkedInContentMode mode) {
    setState(() {
      _contentMode = mode;
      _isTranslateMode = false;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'LinkedIn AI Assistant',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            
            // Content detection section
            _buildContentDisplay(),
            const SizedBox(height: 16),
            
            // Content mode switcher
            if (_detectedContent != null && _detectedContent!.isNotEmpty)
              _buildModeSwitcher(),
              
            const SizedBox(height: 16),
            
            // Options section based on mode
            _buildOptionsSection(),
            const SizedBox(height: 16),
            
            // Generate button section
            _buildGenerateSection(),
            const SizedBox(height: 16),
            
            // Generated content section
            _buildGeneratedContentSection(),
          ],
        ),
      ),
    );
  }
  
  Widget _buildContentDisplay() {
    if (_detectedContent == null || _detectedContent!.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('No LinkedIn content detected. Open LinkedIn to use this feature.'),
        ),
      );
    }
    
    return Card(
      color: Theme.of(context).colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_detectedAuthor != null && _detectedAuthor!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Text(
                  'From: $_detectedAuthor',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            Text(
              _detectedContent!.length > 200 
                ? '${_detectedContent!.substring(0, 200)}...'
                : _detectedContent!,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (_hasImage)
              const Padding(
                padding: EdgeInsets.only(top: 8.0),
                child: Text('(Image detected in post)'),
              ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildModeSwitcher() {
    return Wrap(
      spacing: 8.0,
      runSpacing: 8.0,
      children: [
        ChoiceChip(
          label: const Text('Comment'),
          selected: _contentMode == LinkedInContentMode.comment,
          onSelected: (selected) {
            if (selected) _switchContentMode(LinkedInContentMode.comment);
          },
        ),
        ChoiceChip(
          label: const Text('Post'),
          selected: _contentMode == LinkedInContentMode.post,
          onSelected: (selected) {
            if (selected) _switchContentMode(LinkedInContentMode.post);
          },
        ),
        ChoiceChip(
          label: const Text('About'),
          selected: _contentMode == LinkedInContentMode.about,
          onSelected: (selected) {
            if (selected) _switchContentMode(LinkedInContentMode.about);
          },
        ),
        ChoiceChip(
          label: const Text('Connection'),
          selected: _contentMode == LinkedInContentMode.connection,
          onSelected: (selected) {
            if (selected) _switchContentMode(LinkedInContentMode.connection);
          },
        ),
        ChoiceChip(
          label: const Text('Translate'),
          selected: _isTranslateMode,
          onSelected: (selected) {
            setState(() {
              _isTranslateMode = selected;
              if (selected) {
                _contentMode = LinkedInContentMode.translate;
              } else {
                _contentMode = LinkedInContentMode.comment;
              }
            });
          },
        ),
      ],
    );
  }
  
  Widget _buildOptionsSection() {
    if (_detectedContent == null || _detectedContent!.isEmpty) {
      return const SizedBox.shrink();
    }
    
    if (_isTranslateMode) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DropdownButtonFormField<String>(
            initialValue: _selectedLanguage,
            decoration: const InputDecoration(
              labelText: 'Target Language',
              border: OutlineInputBorder(),
            ),
            items: LinkedInService.availableLanguages
                .map((lang) => DropdownMenuItem(
                      value: lang['code'],
                      child: Text(lang['name']!),
                    ))
                .toList(),
            onChanged: (value) {
              setState(() {
                _selectedLanguage = value!;
                // Clear any previous translation when language changes
                _generatedContent = null;
              });
            },
          ),
          
          const SizedBox(height: 16),
          
          // Add a dedicated Translate button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : () => _generateContent(),
              icon: _isLoading 
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.translate, color: Colors.white),
              label: Text(_isLoading ? 'Translating...' : 'Translate'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                iconColor: Colors.white,
              ),
            ),
          ),
        ],
      );
    }
    
    switch (_contentMode) {
      case LinkedInContentMode.comment:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Comment Type:',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              children: LinkedInService.commentButtonTypes.map((type) {
                return ChoiceChip(
                  label: Text(type),
                  selected: _selectedCommentType == type,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _selectedCommentType = type;
                      });
                    }
                  },
                );
              }).toList(),
            ),
          ],
        );
        
      case LinkedInContentMode.post:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Post Framework:',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              children: LinkedInService.postFrameworks.map((framework) {
                return ChoiceChip(
                  label: Text(framework),
                  selected: _selectedPostFramework == framework,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _selectedPostFramework = framework;
                      });
                    }
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: CheckboxListTile(
                    title: const Text('Include Hashtags'),
                    value: _includeHashtags,
                    onChanged: (value) {
                      setState(() {
                        _includeHashtags = value ?? true;
                      });
                    },
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                  ),
                ),
                Expanded(
                  child: CheckboxListTile(
                    title: const Text('Include Emojis'),
                    value: _includeEmojis,
                    onChanged: (value) {
                      setState(() {
                        _includeEmojis = value ?? true;
                      });
                    },
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                  ),
                ),
              ],
            ),
          ],
        );
        
      case LinkedInContentMode.about:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'About Section Modification:',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              children: [
                ChoiceChip(
                  label: const Text('Optimize'),
                  selected: _selectedAboutType == 'Optimize',
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _selectedAboutType = 'Optimize';
                      });
                    }
                  },
                ),
                ChoiceChip(
                  label: const Text('Expand'),
                  selected: _selectedAboutType == 'Expand',
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _selectedAboutType = 'Expand';
                      });
                    }
                  },
                ),
                ChoiceChip(
                  label: const Text('Simplify'),
                  selected: _selectedAboutType == 'Simplify',
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _selectedAboutType = 'Simplify';
                      });
                    }
                  },
                ),
                ChoiceChip(
                  label: const Text('Keywords'),
                  selected: _selectedAboutType == 'Keywords',
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _selectedAboutType = 'Keywords';
                      });
                    }
                  },
                ),
              ],
            ),
          ],
        );
        
      case LinkedInContentMode.connection:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Connection Note Style:',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              children: [
                ChoiceChip(
                  label: const Text('Formal'),
                  selected: _selectedConnectionType == 'Formal',
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _selectedConnectionType = 'Formal';
                      });
                    }
                  },
                ),
                ChoiceChip(
                  label: const Text('Friendly'),
                  selected: _selectedConnectionType == 'Friendly',
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _selectedConnectionType = 'Friendly';
                      });
                    }
                  },
                ),
                ChoiceChip(
                  label: const Text('Specific'),
                  selected: _selectedConnectionType == 'Specific',
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _selectedConnectionType = 'Specific';
                      });
                    }
                  },
                ),
              ],
            ),
          ],
        );
        
      default:
        return const SizedBox.shrink();
    }
  }
  
  Widget _buildGenerateSection() {
    if (_detectedContent == null || _detectedContent!.isEmpty) {
      return const SizedBox.shrink();
    }
    
    // Check if generate button should be enabled
    bool canGenerate = false;
    switch (_contentMode) {
      case LinkedInContentMode.comment:
        canGenerate = !_isTranslateMode;
        break;
      case LinkedInContentMode.post:
      case LinkedInContentMode.about:
      case LinkedInContentMode.connection:
      case LinkedInContentMode.translate:
        canGenerate = true;
        break;
    }
    
    final buttonLabel = switch (_contentMode) {
      LinkedInContentMode.comment => _isTranslateMode ? 'Translate' : 'Generate Comment',
      LinkedInContentMode.post => 'Generate Post',
      LinkedInContentMode.about => 'Generate About',
      LinkedInContentMode.connection => 'Generate Note',
      LinkedInContentMode.translate => 'Translate',
    };
    
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: (_isLoading || !canGenerate) ? null : _generateContent,
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12.0),
          child: _isLoading
              ? const CircularProgressIndicator(color: Colors.white)
              : Text(buttonLabel),
        ),
      ),
    );
  }
  
  Widget _buildGeneratedContentSection() {
    if (_generatedContent == null || _generatedContent!.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Generated Content:',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        Card(
          color: Theme.of(context).colorScheme.primaryContainer,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SelectableText(_generatedContent!),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.copy),
                      onPressed: () => _copyToClipboard(_generatedContent!),
                      tooltip: 'Copy to clipboard',
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: _isLoading ? null : _generateContent,
                      tooltip: 'Regenerate',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
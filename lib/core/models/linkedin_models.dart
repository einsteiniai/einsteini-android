/// Class representing a LinkedIn post
class LinkedInPost {
  final String content;
  final String author;
  final String date;
  final int likes;
  final int comments;
  final List<String> images;
  final List<LinkedInComment> commentsList;
  
  LinkedInPost({
    required this.content,
    required this.author,
    required this.date,
    required this.likes,
    required this.comments,
    required this.images,
    required this.commentsList,
  });
  
  factory LinkedInPost.fromJson(Map<String, dynamic> json) {
    return LinkedInPost(
      content: json['content'] ?? '',
      author: json['author'] ?? '',
      date: json['date'] ?? '',
      likes: json['likes'] ?? 0,
      comments: json['comments'] ?? 0,
      images: List<String>.from(json['images'] ?? []),
      commentsList: (json['commentsList'] as List<dynamic>? ?? [])
          .map((comment) => LinkedInComment.fromJson(comment))
          .toList(),
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'content': content,
      'author': author,
      'date': date,
      'likes': likes,
      'comments': comments,
      'images': images,
      'commentsList': commentsList.map((comment) => comment.toJson()).toList(),
    };
  }
}

/// Class representing a LinkedIn comment
class LinkedInComment {
  final String author;
  final String text;
  
  LinkedInComment({
    required this.author,
    required this.text,
  });
  
  factory LinkedInComment.fromJson(Map<String, dynamic> json) {
    return LinkedInComment(
      author: json['author'] ?? '',
      text: json['text'] ?? '',
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'author': author,
      'text': text,
    };
  }
}

/// Class representing a LinkedIn profile
class LinkedInProfile {
  final String name;
  final String title;
  final String about;
  final String url;
  final String? mutual;
  final String? profileImageUrl;
  
  LinkedInProfile({
    required this.name,
    required this.title,
    required this.about,
    required this.url,
    this.mutual,
    this.profileImageUrl,
  });
  
  factory LinkedInProfile.fromJson(Map<String, dynamic> json) {
    return LinkedInProfile(
      name: json['name'] ?? '',
      title: json['title'] ?? '',
      about: json['about'] ?? '',
      url: json['url'] ?? '',
      mutual: json['mutual'],
      profileImageUrl: json['profileImageUrl'],
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'title': title,
      'about': about,
      'url': url,
      'mutual': mutual,
      'profileImageUrl': profileImageUrl,
    };
  }
}

/// Class representing the type of personalization to apply
class PersonalizationOptions {
  final String tone;
  final String toneDetails;
  
  PersonalizationOptions({
    required this.tone,
    required this.toneDetails,
  });
  
  factory PersonalizationOptions.fromJson(Map<String, dynamic> json) {
    return PersonalizationOptions(
      tone: json['tone'] ?? '',
      toneDetails: json['toneDetails'] ?? '',
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'tone': tone,
      'toneDetails': toneDetails,
    };
  }
}

/// Class representing the options for LinkedIn About section generation
class AboutSectionOptions {
  final String writingStyle;
  final String industry;
  final String primaryGoal;
  final String careerStage;
  final String audience;
  final String lengthPreference;
  final String paragraphStyle;
  final bool includeCta;
  final bool includeBulletPoints;
  final String? ctaText;
  final String? contentElements;
  final String? languages;
  final String? specialInstructions;
  
  AboutSectionOptions({
    required this.writingStyle,
    required this.industry,
    required this.primaryGoal,
    required this.careerStage,
    required this.audience,
    required this.lengthPreference,
    required this.paragraphStyle,
    required this.includeCta,
    required this.includeBulletPoints,
    this.ctaText,
    this.contentElements,
    this.languages,
    this.specialInstructions,
  });
  
  /// Convert to a structured prompt string for the AI
  String toPromptString() {
    final List<String> parts = [
      'Write a LinkedIn About section for a $careerStage $industry professional.',
      'Target $audience.',
      'Make it $lengthPreference length with $paragraphStyle.',
    ];
    
    if (includeBulletPoints) {
      parts.add('Use bullet points.');
    }
    
    if (includeCta && ctaText != null && ctaText!.isNotEmpty) {
      parts.add('End with: "$ctaText"');
    }
    
    if (specialInstructions != null && specialInstructions!.isNotEmpty) {
      parts.add(specialInstructions!);
    }
    
    return parts.join(' ');
  }
  
  factory AboutSectionOptions.fromJson(Map<String, dynamic> json) {
    return AboutSectionOptions(
      writingStyle: json['writingStyle'] ?? 'Formal',
      industry: json['industry'] ?? 'Tech',
      primaryGoal: json['primaryGoal'] ?? 'Networking',
      careerStage: json['careerStage'] ?? 'Mid-career',
      audience: json['audience'] ?? 'Industry professionals',
      lengthPreference: json['lengthPreference'] ?? 'Medium',
      paragraphStyle: json['paragraphStyle'] ?? '2-3 short paragraphs',
      includeCta: json['includeCta'] ?? false,
      includeBulletPoints: json['includeBulletPoints'] ?? false,
      ctaText: json['ctaText'],
      contentElements: json['contentElements'],
      languages: json['languages'],
      specialInstructions: json['specialInstructions'],
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'writingStyle': writingStyle,
      'industry': industry,
      'primaryGoal': primaryGoal,
      'careerStage': careerStage,
      'audience': audience,
      'lengthPreference': lengthPreference,
      'paragraphStyle': paragraphStyle,
      'includeCta': includeCta,
      'includeBulletPoints': includeBulletPoints,
      'ctaText': ctaText,
      'contentElements': contentElements,
      'languages': languages,
      'specialInstructions': specialInstructions,
    };
  }
}

/// Enum for LinkedIn content generation modes
enum LinkedInContentMode {
  comment,
  post,
  about,
  connection,
  translate,
}

/// Enum for comment styles
enum CommentStyle {
  agree,
  expand,
  fun,
  aiRectify,
  question,
  perspective,
  personalize,
}

/// Enum for LinkedIn post frameworks
enum PostFramework {
  aida,
  has,
  fab,
  star,
} 
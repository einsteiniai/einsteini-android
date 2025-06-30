# Einsteini - AI Assistant Mobile App

Einsteini is an AI-powered assistant app that enhances your productivity by providing smart content generation features across different platforms.

## LinkedIn AI Features

The Einsteini app now includes powerful LinkedIn AI assistant features that work directly with the LinkedIn Android app:

### Features

1. **AI Comment Generation**
   - Generate contextually relevant comments for LinkedIn posts
   - Multiple comment types: Agree, Expand, Fun, Question, Perspective, and more
   - Personalize comments with custom tone and instructions
   - AI grammar correction for your comments

2. **LinkedIn Post Creation**
   - Create engaging LinkedIn posts using proven frameworks:
     - AIDA (Attention, Interest, Desire, Action)
     - HAS (Hook, Amplify, Story)
     - FAB (Features, Advantages, Benefits)
     - STAR (Situation, Task, Action, Result)
   - Control hashtag and emoji inclusion
   - Personalize with different tones and custom instructions

3. **About Section Optimization**
   - Enhance your LinkedIn About section
   - Options to optimize, expand, simplify, or highlight keywords
   - Custom personalization with specific writing styles

4. **Connection Note Generator**
   - Create personalized connection request notes
   - Choose formal, friendly, or specific styles
   - Include mutual connections and personalized details

5. **Content Translation**
   - Translate LinkedIn content into multiple languages
   - Support for 13 languages including English, Spanish, French, German, etc.

### How It Works

1. **Floating Overlay**
   - Enable the overlay feature in the app settings
   - A floating bubble will appear on your screen
   - Tap the bubble to expand the AI assistant overlay

2. **Accessibility Service**
   - The app uses Android's accessibility service to detect LinkedIn content
   - Content is securely processed without storing your LinkedIn data

3. **AI Processing**
   - Content is analyzed by our advanced AI models
   - Generated content is displayed in the overlay
   - Easily copy and paste into LinkedIn

### Setup

1. Install the app and grant required permissions
2. Enable accessibility service for LinkedIn content detection
3. Enable overlay permission for the floating assistant
4. Open LinkedIn app and navigate to posts, profiles, etc.
5. Use the floating bubble to access AI features

## Technical Details

The app is built using Flutter for the cross-platform UI, with native Android components for the overlay and accessibility services. The AI functionality connects to our secure backend API for content generation.

### Key Components

- **LinkedInService**: Handles LinkedIn API operations and content generation
- **OverlayService**: Manages the floating overlay window
- **EinsteiniAccessibilityService**: Detects LinkedIn content in the Android app
- **LinkedInOverlayControls**: UI components for the LinkedIn AI features

## Privacy

The app processes LinkedIn content locally and only sends the necessary data to our secure API for AI content generation. No user credentials or personal LinkedIn data are stored.

## Core Functionality

- **LinkedIn Content Analysis**: Scrapes and analyzes LinkedIn posts to provide summaries and insights
- **AI Content Generation**: Creates LinkedIn posts and "About Me" sections based on user input  
- **Floating Overlay**: Provides quick access to AI features across different apps on Android
- **System Integration**: Uses Android services (Accessibility and Overlay) to enhance integration

## Technical Architecture

### Mobile App (Flutter)

The app is built with Flutter and organized using a feature-based architecture:

```
lib/
├── core/
│   ├── constants/       # App-wide constants and configuration
│   ├── routes/          # Navigation and routing with go_router
│   ├── services/        # Core services (overlay, history)
│   ├── theme/           # App theme definitions and switching
│   ├── utils/           # Platform interactions and utilities
│   └── widgets/         # Reusable UI components
├── features/
│   ├── home/            # Main screen with tabs for different features
│   │   ├── providers/
│   │   ├── screens/
│   │   └── widgets/
│   └── onboarding/      # Permission setup and initial experience
│       ├── screens/
│       └── widgets/
└── main.dart            # App entry point
```

### Android Native Components

The app includes two key Android services:

1. **EinsteiniAccessibilityService**: Provides screen context awareness
2. **EinsteiniOverlayService**: Delivers a floating bubble UI with AI assistance features

Communication between Flutter and native Android code happens through platform channels.

## Key Features

### LinkedIn Post Analyzer
- Scrapes post content, author, date, likes, comments
- Generates summaries and translations
- Saves analysis history

### Content Creation Assistant
- Creates professional LinkedIn posts
- Generates "About Me" sections for profiles
- Customizes content based on topic, tone, and length

### Floating Overlay (Android only)
- Provides a bubble interface that works across apps
- Expandable UI with AI assistance
- Theme adapts based on system dark/light mode

## Getting Started

### Prerequisites

- Flutter 3.6 or higher
- Dart 3.6 or higher
- Android Studio / Visual Studio Code

### Development Setup

1. Clone the repository:
   ```bash
   git clone https://github.com/your-username/einsteiniapp.git
   cd einsteiniapp
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Run the app:
   ```bash
   flutter run
   ```

## Required Permissions

The app needs the following permissions on Android:
- **SYSTEM_ALERT_WINDOW**: To display overlay UI on top of other apps
- **BIND_ACCESSIBILITY_SERVICE**: To provide context-aware assistance

## Dependencies

Key packages used in this project:
- **flutter_riverpod**: State management
- **go_router**: Navigation
- **shared_preferences**: Local storage
- **lottie**: Animation support
- **permission_handler**: Permission management

## License

This project is proprietary and confidential. All rights reserved.

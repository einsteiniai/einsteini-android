# einsteini.ai Mobile App

A Flutter application that provides AI-assisted LinkedIn engagement tools through both in-app and overlay interfaces.

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

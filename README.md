# einsteini.ai Mobile App

A Flutter application for einsteini.ai, an AI assistant that helps users learn, create, and accomplish more throughout their day.

## Features

- **Onboarding Experience**: Smooth introduction with permissions setup and theme selection
- **Authentication**: Login and signup functionality with social logins
- **AI Assistant**: Chat interface with contextual understanding
- **Accessibility Support**: Works with device accessibility services
- **Overlay Capability**: Provides assistance across different apps
- **Responsive Design**: Works on both iOS and Android in light and dark mode

## Getting Started

### Prerequisites

- Flutter 3.6 or higher
- Dart 3.0 or higher
- Android Studio / Visual Studio Code with Flutter extensions
- iOS Simulator or Android Emulator

### Required Fonts

The app uses the following custom fonts:

1. **Space Grotesk**
   - Regular, Light, Medium, Bold

2. **Inter**
   - Regular, Light, Medium, Bold

Please download these fonts and place them in the `assets/fonts/` directory.

### Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/your-username/einsteini_app.git
   cd einsteini_app
   ```

2. Get dependencies:
   ```bash
   flutter pub get
   ```

3. Create necessary asset folders if not already present:
   ```bash
   mkdir -p assets/animations
   mkdir -p assets/images
   mkdir -p assets/icons
   mkdir -p assets/fonts
   ```

4. Place required font files in the assets/fonts directory.

5. Run the app:
   ```bash
   flutter run
   ```

## Project Structure

```
lib/
├── core/
│   ├── constants/       # App-wide constants
│   ├── routes/          # Navigation and routing
│   ├── theme/           # App theme definitions
│   ├── utils/           # Utility functions
│   └── widgets/         # Reusable widgets
├── features/
│   ├── home/            # Main screen and chat functionality
│   │   ├── providers/
│   │   ├── screens/
│   │   └── widgets/
│   └── onboarding/      # Onboarding experience
│       ├── screens/
│       └── widgets/
└── main.dart            # App entry point
```

## Permissions

The app requires the following permissions:

- **Display over other apps**: To provide AI assistance across different applications
- **Accessibility services**: To understand screen context and provide relevant assistance

These permissions are requested during the onboarding process but can be skipped and configured later in the app settings.

## Development Notes

- The app uses Riverpod for state management
- Go Router for navigation
- Shared Preferences for local storage
- The app supports both light and dark modes

## License

This project is proprietary and confidential. All rights reserved.

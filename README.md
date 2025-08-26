<div align="center">
  <img src="assets/images/einsteini_black.png" alt="Einsteini Logo" width="100" height="100">
  <h1>🚀 Einsteini - AI Assistant Mobile App</h1>
  <p><em>Effortlessly human.</em></p>
  
  [![Flutter](https://img.shields.io/badge/Flutter-3.6+-blue.svg?style=flat&logo=flutter)](https://flutter.dev)
  [![Dart](https://img.shields.io/badge/Dart-3.6+-orange.svg?style=flat&logo=dart)](https://dart.dev)
  [![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](LICENSE)
  [![Contributions Welcome](https://img.shields.io/badge/contributions-welcome-brightgreen.svg?style=flat)](CONTRIBUTING.md)
  
  <p>🌟 <strong>Join our closed beta testing program!</strong> 🌟</p>
  <p><a href="https://play.google.com/apps/internaltest/4699582203949488654">📱 Beta Testing Sign-up</a> | <a href="https://einsteini.ai">🌐 Official Website</a></p>
</div>

---
## 🆕 Current Version

**Version:** 3.0.0+22

## � Release Notes

### v3.0.0
✨ NEW FEATURES
• Direct LinkedIn post sharing from AI-generated content
• About Me generator with backend integration
• New Post/Repost tab switcher UI

🛠 IMPROVEMENTS
• Updated UI colors and versioning
• Improved backend integration and error handling

🐛 BUG FIXES
• Fixed tab switcher state persistence
• Resolved versioning and build issues

🔐 PRIVACY & SECURITY
• No new changes

Download now to experience the latest improvements!

## �📋 Table of Contents

- [About](#-about)
- [Features](#-features)
- [Architecture](#-architecture)
- [Getting Started](#-getting-started)
- [Project Structure](#-project-structure)
- [Contributing](#-contributing)
- [Beta Testing](#-beta-testing)
- [Roadmap](#-roadmap)
- [Support](#-support)
- [License](#-license)

---

## 🎯 About

**Einsteini** is an open-source AI-powered assistant app designed to enhance your LinkedIn productivity and professional networking. Built with Flutter, it provides intelligent content generation, real-time assistance, and seamless integration with LinkedIn through innovative overlay technology.

### 🌟 Why Einsteini?

- **🤖 AI-Powered**: Advanced AI models for content generation and analysis
- **📱 Mobile-First**: Native Android experience with Flutter performance  
- **🔒 Privacy-Focused**: Local processing with secure API communication
- **🛠 Open Source**: Community-driven development and transparency
- **💼 Professional**: Designed specifically for LinkedIn engagement

---

## ✨ Features

### 🎯 LinkedIn AI Assistant

#### 💬 Smart Comment Generation
- Generate contextually relevant comments for LinkedIn posts
- Multiple comment styles: Agree, Expand, Fun, Question, Perspective
- Custom tone and personalization options
- AI-powered grammar correction

#### 📝 Professional Post Creation
Leverage proven content frameworks:
- **AIDA** (Attention, Interest, Desire, Action)
- **HAS** (Hook, Amplify, Story)
- **FAB** (Features, Advantages, Benefits)
- **STAR** (Situation, Task, Action, Result)

#### 🎨 Profile Optimization
- About section enhancement and optimization
- Keyword highlighting and SEO optimization
- Multiple writing style adaptations

#### 🤝 Connection Management
- Personalized connection request notes
- Formal, friendly, and custom message styles
- Mutual connection integration

#### 🌐 Multi-Language Support
Translate content into 13+ languages including:
- English, Spanish, French, German
- Italian, Portuguese, Chinese, Japanese
- And many more...

### 🔧 Technical Features

#### 🎈 Floating Overlay System
- System-wide floating bubble interface
- Expandable AI assistant overlay
- Cross-app functionality for seamless LinkedIn integration

#### 🤖 Accessibility Integration
- Advanced content detection and analysis
- Real-time LinkedIn content extraction
- Secure data processing pipeline

#### 🎨 Modern UI/UX
- Material Design 3 principles
- Dark/Light theme switching
- Smooth animations with Lottie
- Responsive design patterns

#### 💳 Subscription Management
- Integrated Stripe payment processing
- Multiple subscription tiers (Pro/Gold)
- Usage tracking and billing management

---

## 🏗 Architecture

### 🔧 Tech Stack

- **Frontend**: Flutter 3.6+ / Dart 3.6+
- **State Management**: Riverpod 2.3+
- **Navigation**: Go Router 7.0+
- **Backend API**: RESTful API with Stripe integration
- **Authentication**: Google Sign-In, OAuth 2.0
- **Storage**: SharedPreferences, Secure Storage
- **Animations**: Lottie, Flutter Animate

### 🏛 Project Architecture

```
einsteini-android/
├── 📱 lib/                          # Flutter application code
│   ├── 🎯 main.dart                 # Application entry point
│   ├── 🏗 core/                     # Core application infrastructure
│   │   ├── 📋 constants/            # App-wide constants
│   │   │   ├── app_constants.dart   # General app configuration
│   │   │   ├── privacy_policy.dart  # Privacy policy content
│   │   │   └── terms_of_service.dart # Terms of service
│   │   ├── 📊 models/               # Data models
│   │   │   └── subscription_model.dart # Subscription data structures
│   │   ├── 🛣 routes/               # Navigation and routing
│   │   │   └── app_router.dart      # Go Router configuration
│   │   ├── ⚙️ services/             # Core business logic services
│   │   │   ├── overlay_service.dart # Floating overlay management
│   │   │   └── history_service.dart # User interaction history
│   │   ├── 🎨 theme/                # UI theming system
│   │   │   ├── app_theme.dart       # Theme definitions
│   │   │   ├── theme_provider.dart  # Theme state management
│   │   │   └── theme_switcher.dart  # Theme switching logic
│   │   ├── 🔧 utils/                # Utility functions
│   │   │   ├── platform_channel.dart # Native platform communication
│   │   │   └── permission_utils.dart # Permission handling utilities
│   │   └── 🧩 widgets/              # Reusable UI components
│   └── 🌟 features/                 # Feature-based modules
│       ├── 🏠 home/                 # Main application features
│       │   ├── providers/           # Home feature state management
│       │   ├── screens/             # Home UI screens
│       │   │   ├── home_screen.dart # Main dashboard
│       │   │   └── tutorial_screen.dart # User onboarding tutorial
│       │   └── widgets/             # Home-specific UI components
│       │       └── ai_assistant_tab.dart # AI assistant interface
│       ├── 🚀 onboarding/           # User onboarding flow
│       │   ├── screens/             # Onboarding UI screens
│       │   │   ├── welcome_screen.dart # Welcome and introduction
│       │   │   ├── auth_screen.dart # Authentication flow
│       │   │   ├── theme_selection_screen.dart # Theme customization
│       │   │   ├── overlay_permission_screen.dart # Overlay setup
│       │   │   ├── accessibility_permission_screen.dart # Accessibility setup
│       │   │   └── location_permission_screen.dart # Location services
│       │   └── widgets/             # Onboarding-specific widgets
│       └── 💳 subscription/         # Subscription management
│           └── screens/             # Subscription UI screens
│               └── subscription_screen.dart # Payment and billing
├── 🤖 android/                      # Android-specific code
│   ├── app/
│   │   ├── 📄 build.gradle          # Android build configuration
│   │   └── src/main/
│   │       ├── 📱 AndroidManifest.xml # App permissions and services
│   │       └── kotlin/com/einsteini/app/ # Kotlin native code
│   │           ├── MainActivity.kt  # Main Android activity
│   │           ├── EinsteiniAccessibilityService.kt # Content detection service
│   │           └── EinsteiniOverlayService.kt # Floating overlay service
│   ├── 🔐 key.properties            # Signing key configuration
│   └── 🏗 gradle.properties         # Gradle build properties
├── 🎨 assets/                       # Static assets
│   ├── animations/                  # Lottie animation files
│   │   ├── accessibility_permission.json
│   │   └── overlay_permission.json
│   ├── fonts/                       # Custom font files
│   │   ├── DMSans_*.ttf            # DM Sans font family
│   │   └── TikTokSans_*.ttf        # TikTok Sans font family
│   ├── icons/                       # Application icons
│   └── images/                      # Static images
│       ├── einsteini_black.png     # Light theme logo
│       └── einsteini_white.png     # Dark theme logo
├── 🍎 ios/                          # iOS-specific code (future support)
├── 🐧 linux/                        # Linux desktop support (future)
├── 🍎 macos/                        # macOS desktop support (future)
├── 🌐 web/                          # Web platform support (future)
├── 🪟 windows/                      # Windows desktop support (future)
├── 🧪 test/                         # Unit and widget tests
│   └── widget_test.dart            # Basic widget testing
├── 📋 pubspec.yaml                  # Flutter dependencies and configuration
├── 🔧 analysis_options.yaml        # Dart analyzer configuration
├── 🚀 build.bat                     # Build script for releases
├── 🎨 flutter_launcher_icons.yaml  # App icon configuration
├── 📖 README.md                     # Project documentation (this file)
├── 📄 CONTRIBUTING.md               # Contribution guidelines
├── 📊 PLAY_STORE_CHECKLIST.md      # App store submission checklist
├── 📚 PLAY_STORE_PUBLISHING_GUIDE.md # Publishing documentation
└── 💳 SUBSCRIPTION_INTEGRATION.md  # Subscription system documentation
```

### 🔄 Data Flow

1. **User Interaction** → Flutter UI components
2. **State Management** → Riverpod providers
3. **Platform Communication** → Method channels
4. **Native Services** → Android Accessibility & Overlay services
5. **AI Processing** → Secure API communication
6. **Content Generation** → UI display and user interaction

---

## 🚀 Getting Started

### 📋 Prerequisites

Ensure you have the following installed:

- **Flutter SDK**: 3.6.0 or higher
- **Dart SDK**: 3.6.0 or higher  
- **Android Studio**: Latest stable version
- **VS Code**: With Flutter/Dart extensions (optional)
- **Git**: For version control

### 🛠 Development Setup

1. **Clone the Repository**
   ```bash
   git clone https://github.com/einsteiniai/einsteini-android.git
   cd einsteini-android
   ```

2. **Install Dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure Environment**
   ```bash
   # Create your own key.properties file for Android signing
   cp android/key.properties.example android/key.properties
   
   # Edit the file with your signing key information
   nano android/key.properties
   ```

4. **Run the Application**
   ```bash
   # Development mode
   flutter run

   # Release mode  
   flutter run --release
   ```

5. **Build for Production**
   ```bash
   # Android APK
   flutter build apk --release
   
   # Android App Bundle (recommended for Play Store)
   flutter build appbundle --release
   ```

### 🔧 Configuration

#### Android Permissions Setup

The app requires special permissions for full functionality:

1. **Overlay Permission** - For floating bubble interface
2. **Accessibility Service** - For LinkedIn content detection  
3. **Location Permission** - For subscription pricing (optional)

These permissions are guided through the onboarding flow.

#### Backend API Configuration

Update the API endpoints in your configuration:

```dart
// lib/core/constants/app_constants.dart
static const String baseApiUrl = 'https://your-api-url.com';
static const String stripePublishableKey = 'pk_live_your_stripe_key';
```

---

## 📁 Project Structure

### 🏗 Core Architecture Principles

- **🎯 Feature-Based**: Organized by business functionality
- **📱 Platform Agnostic**: Shared business logic across platforms  
- **🧩 Modular Design**: Loosely coupled, highly cohesive components
- **🔄 Reactive**: Stream-based state management with Riverpod
- **🛡 Type Safe**: Strong typing with Dart's null safety

### 🧪 Testing Structure

```
test/
├── unit/                    # Unit tests for business logic
├── widget/                  # Widget tests for UI components  
├── integration/             # Integration tests for workflows
└── mocks/                   # Mock objects for testing
```

### 📋 Key Dependencies

| Category | Package | Purpose |
|----------|---------|---------|
| **State Management** | `flutter_riverpod` | Reactive state management |
| **Navigation** | `go_router` | Declarative routing |
| **UI/UX** | `google_fonts`, `lottie` | Typography and animations |
| **Storage** | `shared_preferences`, `flutter_secure_storage` | Data persistence |
| **Networking** | `http` | API communication |
| **Permissions** | `permission_handler` | System permissions |
| **Authentication** | `google_sign_in`, `flutter_appauth` | Social login |
| **Payments** | Stripe integration | Subscription management |

---

## 🤝 Contributing

We welcome contributions from the community! This project is open-source and thrives on collaborative development.

### 🌟 How to Contribute

1. **🍴 Fork the Repository**
   ```bash
   # Fork on GitHub, then clone your fork
   git clone https://github.com/YOUR_USERNAME/einsteini-android.git
   ```

2. **🌿 Create a Feature Branch**
   ```bash
   git checkout -b feature/amazing-new-feature
   ```

3. **✨ Make Your Changes**
   - Follow the existing code style and patterns
   - Add tests for new functionality
   - Update documentation as needed

4. **🧪 Test Your Changes**
   ```bash
   # Run all tests
   flutter test
   
   # Test the app thoroughly
   flutter run --profile
   ```

5. **📝 Commit Your Changes**
   ```bash
   git commit -m "feat: add amazing new feature"
   ```
   
   Please follow [Conventional Commits](https://conventionalcommits.org/) format.

6. **🚀 Push and Create PR**
   ```bash
   git push origin feature/amazing-new-feature
   ```
   
   Then create a Pull Request on GitHub.

### 🎯 Areas for Contribution

- **🐛 Bug Fixes**: Help us squash bugs and improve stability
- **✨ New Features**: Add new AI capabilities or UI improvements  
- **📚 Documentation**: Improve README, add code comments, create tutorials
- **🧪 Testing**: Increase test coverage and add integration tests
- **🎨 UI/UX**: Design improvements and accessibility enhancements
- **🌐 Internationalization**: Add support for more languages
- **⚡ Performance**: Optimize app performance and reduce bundle size

### 📏 Code Style Guidelines

- **Dart**: Follow [Effective Dart](https://dart.dev/guides/language/effective-dart) guidelines
- **Flutter**: Adhere to [Flutter style guide](https://github.com/flutter/flutter/wiki/Style-guide-for-Flutter-repo)
- **Formatting**: Use `dart format` before committing
- **Linting**: Address all analyzer warnings and errors

### 🛡 Code Review Process

1. **Automated Checks**: PRs must pass all CI/CD checks
2. **Peer Review**: At least one maintainer approval required
3. **Testing**: New features must include appropriate tests
4. **Documentation**: Update relevant documentation

---

## 🧪 Beta Testing

### 🚀 Join Our Closed Beta Program!

We're actively seeking beta testers to help improve Einsteini before public launch.

#### 📱 How to Join

1. **Sign Up**: [Beta Testing Registration](https://play.google.com/apps/internaltest/4699582203949488654)
2. **Install**: Download the beta version from the Play Store
3. **Test**: Use the app and explore all features
4. **Feedback**: Report bugs and suggest improvements

#### 🎯 What We're Looking For

- **🐛 Bug Reports**: Crashes, UI issues, unexpected behavior
- **💡 Feature Feedback**: Usability improvements and new ideas
- **📱 Device Testing**: Different Android versions and device types
- **🌐 Network Testing**: Various network conditions and speeds

#### 🏆 Beta Tester Benefits

- **⚡ Early Access**: Be the first to try new features
- **🎁 Premium Features**: Free access to Pro features during beta
- **🏅 Recognition**: Beta tester badge in the app
- **💬 Direct Line**: Priority support and direct developer communication

#### 📊 Beta Testing Metrics

Help us track:
- **App Performance**: Loading times, battery usage, memory consumption
- **Feature Usage**: Which features are most/least used
- **User Journey**: Onboarding completion rates and drop-off points
- **AI Quality**: Accuracy and usefulness of generated content

---

## 🗺 Roadmap

### 🎯 Version 2.3.0 (Q1 2025)
- **🔥 Hot Reload Configuration**: Dynamic API endpoint switching
- **🎨 Advanced Theming**: Custom color schemes and typography
- **📊 Analytics Dashboard**: Usage statistics and insights
- **🌐 Web Platform**: Progressive Web App (PWA) support

### 🚀 Version 2.4.0 (Q2 2025)
- **🤖 Enhanced AI Models**: GPT-4 integration and improved responses
- **📱 iOS Support**: Full iOS app with feature parity
- **🔗 Platform Expansion**: Twitter/X and Instagram integration
- **🎯 Smart Scheduling**: AI-powered optimal posting times

### 🌟 Version 3.0.0 (Current Release)
- **Direct LinkedIn post sharing from AI-generated content**
- **About Me generator with backend integration**
- **New Post/Repost tab switcher UI**
- **UI and backend improvements**
- **Bug fixes and stability enhancements**

### 🔮 Future Vision (Q4 2025+)
- **🧠 Advanced AI**: Custom fine-tuned models for users
- **🏢 Enterprise Features**: Company-wide deployment and management
- **🔌 API Platform**: Third-party integrations and developer tools
- **🎯 Industry Specialization**: Vertical-specific AI models

---

## 🆘 Support

### 📞 Getting Help

- **📖 Documentation**: Check this README and inline code comments
- **🐛 Bug Reports**: [Create an issue](https://github.com/einsteiniai/einsteini-android/issues) with detailed information
- **💬 Discussions**: [GitHub Discussions](https://github.com/einsteiniai/einsteini-android/discussions) for questions and ideas
- **📧 Email**: [developers@einsteini.ai](mailto:developers@einsteini.ai)

### 🔧 Common Issues

<details>
<summary>🚫 Permission Issues</summary>

**Problem**: Overlay or accessibility permissions not working

**Solution**: 
1. Go to Android Settings → Apps → Einsteini
2. Enable "Display over other apps"  
3. Go to Settings → Accessibility → Einsteini → Toggle ON
4. Restart the app

</details>

<details>
<summary>⚡ Performance Issues</summary>

**Problem**: App running slowly or consuming battery

**Solution**:
1. Clear app cache and data
2. Ensure you're on latest Android version
3. Close other resource-intensive apps
4. Report device model and Android version to developers

</details>

<details>
<summary>🔐 Authentication Problems</summary>

**Problem**: Google Sign-In not working

**Solution**:
1. Ensure Google Play Services are updated
2. Clear Google Account cache
3. Try signing in with a different Google account
4. Check internet connection stability

</details>

### 📊 System Requirements

**Minimum Requirements**:
- Android 7.0 (API level 24) or higher
- 2GB RAM
- 100MB free storage
- Internet connection for AI features

**Recommended**:
- Android 10.0 (API level 29) or higher  
- 4GB RAM
- 500MB free storage
- Stable WiFi or 4G connection

---

## 📄 License

This project is licensed under the **Apache License 2.0** - see the [LICENSE](LICENSE) file for details.

```
Apache License 2.0

Copyright 2025 Einsteini AI

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
```

---

<div align="center">
  
### 🌟 Star the Project

If you find Einsteini useful, please ⭐ star this repository to show your support!

### 🤝 Connect with Us

[![Website](https://img.shields.io/badge/Website-einsteini.ai-blue?style=flat&logo=google-chrome)](https://einsteini.ai)
[![Twitter](https://img.shields.io/badge/Twitter-@einsteiniai-1DA1F2?style=flat&logo=twitter)](https://twitter.com/einsteiniai)
[![LinkedIn](https://img.shields.io/badge/LinkedIn-Einsteini%20AI-0A66C2?style=flat&logo=linkedin)](https://linkedin.com/company/einsteini-ai)
[![Email](https://img.shields.io/badge/Email-hello@einsteini.ai-EA4335?style=flat&logo=gmail)](mailto:hello@einsteini.ai)

### 📈 Project Stats

![GitHub stars](https://img.shields.io/github/stars/einsteiniai/einsteini-android?style=social)
![GitHub forks](https://img.shields.io/github/forks/einsteiniai/einsteini-android?style=social)
![GitHub watchers](https://img.shields.io/github/watchers/einsteiniai/einsteini-android?style=social)

---

**Made with ❤️ by the Einsteini Team**

*Empowering professionals with AI-driven content creation*

</div>

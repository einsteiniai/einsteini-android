# 🤝 Contributing to Einsteini

First off, thank you for considering contributing to Einsteini! 🎉 

This document provides guidelines for contributing to the Einsteini AI Assistant mobile app. We welcome contributions from developers of all skill levels and backgrounds.

## 📋 Table of Contents

- [Code of Conduct](#-code-of-conduct)
- [Getting Started](#-getting-started)
- [Development Workflow](#-development-workflow)
- [Coding Standards](#-coding-standards)
- [Testing Guidelines](#-testing-guidelines)
- [Pull Request Process](#-pull-request-process)
- [Issue Guidelines](#-issue-guidelines)
- [Community](#-community)

---

## 📜 Code of Conduct

This project and everyone participating in it is governed by our Code of Conduct. By participating, you are expected to uphold this code.

### Our Pledge

We pledge to make participation in our project a harassment-free experience for everyone, regardless of:
- Age, body size, disability, ethnicity, gender identity and expression
- Level of experience, education, socio-economic status
- Nationality, personal appearance, race, religion, or sexual identity and orientation

### Expected Behavior

- **Be respectful** and inclusive in language and actions
- **Be collaborative** and help fellow contributors
- **Be constructive** when giving feedback
- **Focus on the project** and keep discussions relevant
- **Be patient** with newcomers and different perspectives

### Unacceptable Behavior

- Harassment, discrimination, or offensive language
- Personal attacks or trolling
- Publishing private information without consent
- Any conduct that would be inappropriate in a professional setting

---

## 🚀 Getting Started

### Prerequisites

Before you start contributing, ensure you have:

1. **Flutter SDK 3.6+** installed and configured
2. **Dart SDK 3.6+** 
3. **Android Studio** or **VS Code** with Flutter extensions
4. **Git** for version control
5. A **GitHub account** for pull requests

### Environment Setup

1. **Fork the Repository**
   ```bash
   # Go to https://github.com/einsteiniai/einsteini-android
   # Click "Fork" in the top-right corner
   ```

2. **Clone Your Fork**
   ```bash
   git clone https://github.com/YOUR_USERNAME/einsteini-android.git
   cd einsteini-android
   ```

3. **Add Upstream Remote**
   ```bash
   git remote add upstream https://github.com/einsteiniai/einsteini-android.git
   ```

4. **Install Dependencies**
   ```bash
   flutter pub get
   ```

5. **Verify Setup**
   ```bash
   flutter doctor
   flutter test
   ```

### Project Structure Understanding

Before contributing, familiarize yourself with our architecture:

```
lib/
├── 🎯 main.dart              # App entry point
├── 🏗 core/                  # Core infrastructure
│   ├── constants/           # App constants
│   ├── models/             # Data models
│   ├── routes/             # Navigation
│   ├── services/           # Business logic services
│   ├── theme/              # UI theming
│   ├── utils/              # Utilities
│   └── widgets/            # Reusable components
└── 🌟 features/             # Feature modules
    ├── home/               # Main features
    ├── onboarding/         # User setup
    └── subscription/       # Payment system
```

---

## 🔄 Development Workflow

### Branch Strategy

We use **Git Flow** with the following branches:

- **`main`**: Production-ready code
- **`develop`**: Integration branch for features
- **`feature/`**: Individual features (`feature/ai-improvements`)
- **`bugfix/`**: Bug fixes (`bugfix/overlay-crash`)
- **`hotfix/`**: Critical production fixes

### Creating a Feature Branch

```bash
# Update your fork
git checkout develop
git pull upstream develop

# Create feature branch
git checkout -b feature/amazing-new-feature

# Push branch to your fork
git push -u origin feature/amazing-new-feature
```

### Commit Message Guidelines

We follow [Conventional Commits](https://conventionalcommits.org/) specification:

```
<type>[optional scope]: <description>

[optional body]

[optional footer(s)]
```

#### Commit Types

- **`feat`**: New feature
- **`fix`**: Bug fix
- **`docs`**: Documentation changes
- **`style`**: Code style changes (formatting, etc.)
- **`refactor`**: Code refactoring
- **`perf`**: Performance improvements
- **`test`**: Adding or updating tests
- **`chore`**: Build process or auxiliary tool changes

#### Examples

```bash
feat(ai): add GPT-4 integration for better responses
fix(overlay): resolve crash on Android 12+ devices
docs(readme): update installation instructions
style(home): format code according to style guide
refactor(auth): simplify Google Sign-In flow
test(subscription): add unit tests for payment flow
```

### Keeping Your Fork Updated

```bash
# Fetch upstream changes
git fetch upstream

# Update develop branch
git checkout develop
git merge upstream/develop

# Update your feature branch
git checkout feature/your-feature
git merge develop
```

---

## 📏 Coding Standards

### Dart Style Guide

We strictly follow [Effective Dart](https://dart.dev/guides/language/effective-dart) guidelines:

#### Naming Conventions

```dart
// Classes: PascalCase
class UserProfile extends StatelessWidget { }

// Variables and functions: camelCase
String userName = 'einsteini';
void generateContent() { }

// Constants: lowerCamelCase
const String baseApiUrl = 'https://api.einsteini.ai';

// Private members: leading underscore
String _privateVariable;
void _privateMethod() { }
```

#### File Organization

```dart
// 1. Dart SDK imports
import 'dart:convert';
import 'dart:io';

// 2. Package imports
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// 3. Local imports
import '../models/user_model.dart';
import '../services/api_service.dart';
```

#### Code Formatting

- **Line Length**: Maximum 80 characters
- **Indentation**: 2 spaces (no tabs)
- **Trailing Commas**: Always use for function parameters and collections

```dart
// ✅ Good
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: const Text('Einsteini'),
      backgroundColor: Colors.blue,
    ),
    body: const Center(
      child: Text('Welcome to Einsteini'),
    ),
  );
}

// ❌ Bad
Widget build(BuildContext context) {
return Scaffold(
appBar: AppBar(title: const Text('Einsteini'), backgroundColor: Colors.blue),
body: const Center(child: Text('Welcome to Einsteini'))
);
}
```

### Flutter Best Practices

#### State Management

Use **Riverpod** for state management:

```dart
// Provider definition
final userProvider = StateNotifierProvider<UserNotifier, UserState>((ref) {
  return UserNotifier(ref.watch(apiServiceProvider));
});

// Consumer widget
class UserProfile extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userState = ref.watch(userProvider);
    
    return userState.when(
      data: (user) => Text(user.name),
      loading: () => CircularProgressIndicator(),
      error: (error, stack) => Text('Error: $error'),
    );
  }
}
```

#### Widget Structure

```dart
class CustomButton extends StatelessWidget {
  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
  });

  final String text;
  final VoidCallback onPressed;
  final IconData? icon;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: isLoading ? null : onPressed,
      icon: isLoading 
        ? const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : Icon(icon),
      label: Text(text),
    );
  }
}
```

#### Error Handling

```dart
// ✅ Good: Proper error handling
Future<UserModel?> fetchUser(String id) async {
  try {
    final response = await http.get(Uri.parse('$baseUrl/users/$id'));
    
    if (response.statusCode == 200) {
      return UserModel.fromJson(jsonDecode(response.body));
    } else {
      throw ApiException(
        'Failed to fetch user: ${response.statusCode}',
        statusCode: response.statusCode,
      );
    }
  } on SocketException {
    throw NetworkException('No internet connection');
  } on FormatException {
    throw ApiException('Invalid response format');
  } catch (e) {
    throw ApiException('Unexpected error: $e');
  }
}
```

### Documentation Standards

#### Class Documentation

```dart
/// A widget that displays user profile information with AI-generated insights.
/// 
/// This widget fetches user data from the API and uses AI to generate
/// professional recommendations and content suggestions.
/// 
/// Example:
/// ```dart
/// UserProfileWidget(
///   userId: '123',
///   showRecommendations: true,
/// )
/// ```
class UserProfileWidget extends StatelessWidget {
  /// Creates a user profile widget.
  /// 
  /// The [userId] parameter is required and must not be null.
  /// Set [showRecommendations] to true to display AI-generated suggestions.
  const UserProfileWidget({
    super.key,
    required this.userId,
    this.showRecommendations = false,
  });

  /// The unique identifier for the user.
  final String userId;

  /// Whether to show AI-generated recommendations.
  final bool showRecommendations;
  
  // ... rest of implementation
}
```

#### Method Documentation

```dart
/// Generates AI-powered content based on the given prompt and context.
/// 
/// This method sends a request to the AI service with the provided [prompt]
/// and optional [context]. The [temperature] parameter controls creativity
/// (0.0 = conservative, 1.0 = creative).
/// 
/// Returns a [Future] that resolves to the generated content string.
/// Throws [ApiException] if the request fails.
/// Throws [NetworkException] if there's no internet connection.
/// 
/// Example:
/// ```dart
/// final content = await generateContent(
///   prompt: 'Write a LinkedIn post about AI',
///   context: 'Professional networking',
///   temperature: 0.7,
/// );
/// ```
Future<String> generateContent({
  required String prompt,
  String? context,
  double temperature = 0.5,
}) async {
  // Implementation...
}
```

---

## 🧪 Testing Guidelines

### Test Structure

Our testing strategy includes:

1. **Unit Tests**: Business logic and services
2. **Widget Tests**: UI components and interactions
3. **Integration Tests**: Full app workflows
4. **Golden Tests**: UI consistency verification

### Writing Unit Tests

```dart
// test/services/ai_service_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:einsteiniapp/core/services/ai_service.dart';

// Generate mocks
import 'ai_service_test.mocks.dart';

void main() {
  group('AIService', () {
    late AIService aiService;
    late MockHttpClient mockHttpClient;

    setUp(() {
      mockHttpClient = MockHttpClient();
      aiService = AIService(httpClient: mockHttpClient);
    });

    group('generateContent', () {
      test('should return generated content on success', () async {
        // Arrange
        const prompt = 'Test prompt';
        const expectedContent = 'Generated content';
        
        when(mockHttpClient.post(any, body: anyNamed('body')))
          .thenAnswer((_) async => http.Response('{"content":"$expectedContent"}', 200));

        // Act
        final result = await aiService.generateContent(prompt: prompt);

        // Assert
        expect(result, equals(expectedContent));
        verify(mockHttpClient.post(any, body: anyNamed('body'))).called(1);
      });

      test('should throw ApiException on HTTP error', () async {
        // Arrange
        when(mockHttpClient.post(any, body: anyNamed('body')))
          .thenAnswer((_) async => http.Response('Error', 500));

        // Act & Assert
        expect(
          () => aiService.generateContent(prompt: 'test'),
          throwsA(isA<ApiException>()),
        );
      });
    });
  });
}
```

### Writing Widget Tests

```dart
// test/features/home/widgets/ai_assistant_tab_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:einsteiniapp/features/home/widgets/ai_assistant_tab.dart';

void main() {
  group('AIAssistantTab', () {
    testWidgets('should display input field and generate button', (tester) async {
      // Arrange
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: AIAssistantTab(),
            ),
          ),
        ),
      );

      // Act
      await tester.pump();

      // Assert
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Generate Content'), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget);
    });

    testWidgets('should show loading indicator when generating', (tester) async {
      // Test implementation...
    });
  });
}
```

### Running Tests

```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/services/ai_service_test.dart

# Run tests with coverage
flutter test --coverage

# Run integration tests
flutter drive --target=test_driver/app.dart
```

### Test Coverage Requirements

- **Minimum Coverage**: 80% for new code
- **Critical Paths**: 95% coverage required
- **UI Components**: Widget tests for all custom widgets
- **Services**: Unit tests for all public methods

---

## 🔄 Pull Request Process

### Before Creating a PR

1. **✅ Ensure your code follows our style guidelines**
   ```bash
   dart format lib/ test/
   dart analyze
   ```

2. **🧪 Run all tests and ensure they pass**
   ```bash
   flutter test
   flutter test integration_test/
   ```

3. **📱 Test on different devices/screen sizes**
   ```bash
   flutter run --release  # Test release build
   ```

4. **📚 Update documentation if needed**
   - Update README.md for new features
   - Add/update code comments
   - Update API documentation

### Creating the PR

1. **Push your feature branch**
   ```bash
   git push origin feature/your-feature-name
   ```

2. **Create PR on GitHub**
   - Go to the repository on GitHub
   - Click "New Pull Request"
   - Select your feature branch
   - Fill out the PR template

### PR Template

```markdown
## 🎯 Description

Brief description of the changes made.

## 🔄 Type of Change

- [ ] Bug fix (non-breaking change which fixes an issue)
- [ ] New feature (non-breaking change which adds functionality)
- [ ] Breaking change (fix or feature that would cause existing functionality to not work as expected)
- [ ] Documentation update

## 🧪 Testing

- [ ] Unit tests added/updated
- [ ] Widget tests added/updated
- [ ] Integration tests pass
- [ ] Manual testing completed

## 📱 Screenshots

Include screenshots for UI changes.

## ✅ Checklist

- [ ] My code follows the style guidelines
- [ ] I have performed a self-review of my code
- [ ] I have commented my code in hard-to-understand areas
- [ ] I have made corresponding changes to the documentation
- [ ] My changes generate no new warnings
- [ ] I have added tests that prove my fix/feature works
- [ ] New and existing tests pass locally
```

### Review Process

1. **Automated Checks**: CI/CD pipeline runs automatically
2. **Peer Review**: At least one maintainer reviews the code
3. **Testing**: Reviewer tests the changes locally
4. **Feedback**: Address any requested changes
5. **Approval**: PR gets approved and merged

### After Merge

1. **Delete your feature branch** (optional)
   ```bash
   git branch -d feature/your-feature-name
   git push origin --delete feature/your-feature-name
   ```

2. **Update your local repository**
   ```bash
   git checkout develop
   git pull upstream develop
   ```

---

## 🐛 Issue Guidelines

### Before Creating an Issue

1. **Search existing issues** to avoid duplicates
2. **Check closed issues** for similar problems
3. **Verify the issue** in the latest version
4. **Test in different environments** if possible

### Bug Reports

Use the bug report template:

```markdown
## 🐛 Bug Description

A clear and concise description of the bug.

## 🔄 Steps to Reproduce

1. Go to '...'
2. Click on '...'
3. Scroll down to '...'
4. See error

## 🎯 Expected Behavior

What you expected to happen.

## 📱 Actual Behavior

What actually happened.

## 🖥 Environment

- Device: [e.g. Samsung Galaxy S21]
- OS: [e.g. Android 12]
- App Version: [e.g. 2.2.2]
- Flutter Version: [e.g. 3.6.0]

## 📷 Screenshots

Add screenshots if applicable.

## 📋 Additional Context

Any other context about the problem.
```

### Feature Requests

```markdown
## 🌟 Feature Request

A clear and concise description of the feature.

## 🎯 Problem Statement

What problem does this feature solve?

## 💡 Proposed Solution

Describe your ideal solution.

## 🔄 Alternatives Considered

Other solutions you've considered.

## 📈 Additional Context

Any other context or screenshots.
```

### Issue Labels

We use the following labels:

- **`bug`**: Something isn't working
- **`enhancement`**: New feature or request
- **`documentation`**: Improvements or additions to docs
- **`good first issue`**: Good for newcomers
- **`help wanted`**: Extra attention is needed
- **`priority: high`**: Critical issues
- **`ui/ux`**: User interface/experience issues

---

## 👥 Community

### Communication Channels

- **GitHub Discussions**: General questions and ideas
- **Issues**: Bug reports and feature requests
- **Email**: [developers@einsteini.ai](mailto:developers@einsteini.ai)
- **Discord**: [Join our server](https://discord.gg/einsteini) (coming soon)

### Getting Help

1. **Read the documentation** first
2. **Search existing issues** for similar problems  
3. **Ask in GitHub Discussions** for general questions
4. **Create an issue** for bugs or specific problems
5. **Join our Discord** for real-time chat

### Mentorship Program

We offer mentorship for new contributors:

- **🎯 Beginner-friendly issues** labeled `good first issue`
- **👥 Mentor assignment** for complex features
- **📚 Learning resources** and documentation
- **🎯 Pair programming** sessions (upon request)

### Recognition

Contributors are recognized through:

- **📋 Contributors list** in README
- **🏅 GitHub achievements** and badges
- **🌟 Featured contributions** in release notes
- **🎁 Swag and rewards** for significant contributions

---

## 📚 Additional Resources

### Learning Resources

- **Flutter**: [Official Flutter Documentation](https://flutter.dev/docs)
- **Dart**: [Dart Language Tour](https://dart.dev/guides/language/language-tour)
- **Riverpod**: [Riverpod Documentation](https://riverpod.dev/)
- **Material Design**: [Material Design Guidelines](https://m3.material.io/)

### Tools and Extensions

**VS Code Extensions:**
- Flutter
- Dart
- Flutter Widget Snippets
- Awesome Flutter Snippets
- Error Lens

**Android Studio Plugins:**
- Flutter Inspector
- Dart
- Flutter Enhancement Suite

### Useful Commands

```bash
# Development
flutter run --debug              # Run in debug mode
flutter run --profile           # Run in profile mode
flutter run --release           # Run in release mode

# Building
flutter build apk --release     # Build Android APK
flutter build appbundle        # Build Android App Bundle
flutter build ios              # Build iOS app

# Testing
flutter test                    # Run unit tests
flutter test --coverage       # Run tests with coverage
flutter driver test_driver/    # Run integration tests

# Analysis
flutter analyze                # Analyze code
dart format lib/ test/        # Format code
flutter doctor                # Check Flutter setup
```

---

## 🎉 Thank You!

Thank you for contributing to Einsteini! Your efforts help make AI-powered productivity tools accessible to everyone. 

Every contribution, no matter how small, makes a difference. Whether it's fixing a typo, reporting a bug, or implementing a major feature, we appreciate your time and effort.

**Happy coding!** 🚀

---

<div align="center">

**Questions?** Feel free to reach out to us at [developers@einsteini.ai](mailto:developers@einsteini.ai)

**Made with ❤️ by the Einsteini Community**

</div>

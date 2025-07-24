# Google Play Store Publishing Guide for Einsteini App

This guide walks you through the process of publishing your Flutter app to the Google Play Store.

## Prerequisites

- Google Play Developer Account (requires $25 one-time registration fee)
- Keystore file for app signing (already created: `einsteini-keystore.jks`)
- App screenshots and promotional graphics
- Privacy policy URL (mentioned in your AndroidManifest.xml: https://einsteini.ai/privacy)

## Step 1: Complete App Signing Setup

1. Fill in your keystore details in `android/key.properties` (template already created)
   ```
   storeFile=../einsteini-keystore.jks
   storePassword=your_keystore_password
   keyAlias=your_key_alias
   keyPassword=your_key_password
   ```
   Replace the password and alias with your actual values.

2. Ensure `key.properties` is in your .gitignore to avoid committing sensitive information.

## Step 2: Prepare Release Build

1. Update your app version in `pubspec.yaml` if needed (currently 1.0.1+2).
   - The format is `version: X.Y.Z+N` where:
     - X.Y.Z is the versionName (user-facing version number)
     - N is the versionCode (must be incremented for each update)

2. Build the Android App Bundle (preferred by Google Play):
   ```
   flutter build appbundle
   ```
   
   The bundle will be created at:
   `build/app/outputs/bundle/release/app-release.aab`

3. Alternatively, you can build an APK (less preferred):
   ```
   flutter build apk --release
   ```
   
   The APK will be created at:
   `build/app/outputs/flutter-apk/app-release.apk`

## Step 3: Set Up Google Play Console

1. Sign up for a Google Play Developer account at https://play.google.com/apps/publish/

2. Complete your account setup:
   - Accept Developer Agreement
   - Pay the $25 registration fee
   - Provide company details if applicable
   - Set up merchant account if you plan to offer in-app purchases

3. Create a new application:
   - Click "Create app" button
   - Enter app name: "Einsteini" (or your preferred store listing name)
   - Default language: English (US)
   - App or Game: App
   - Free or Paid: Choose appropriately
   - Click "Create app"

## Step 4: Configure Store Listing

1. **Store listing section**:
   - Short description (up to 80 characters)
   - Full description (up to 4000 characters)
   - Upload app icon, feature graphic, and screenshots
     - Phone screenshots (minimum 2)
     - 7" tablet screenshots (optional)
     - 10" tablet screenshots (optional)
   - Add promotional video (optional)
   - Application type and category
   - Contact details (email, website, phone)

2. **Content rating**:
   - Complete the content rating questionnaire
   - Your app will receive appropriate rating (E, T, M, etc.)

3. **Pricing & distribution**:
   - Select countries where your app will be available
   - Set pricing if applicable
   - Select content guidelines compliance

4. **Privacy policy**:
   - Enter your privacy policy URL (https://einsteini.ai/privacy)

5. **App access**:
   - If your app isn't fully functional without signing in, provide test account credentials

## Step 5: Upload Your App Bundle

1. Navigate to **Release > Production** in the console

2. Create a new release:
   - Click "Create new release"
   - Upload the AAB file (`app-release.aab`)
   - Enter release notes
   - Save and review release

3. Roll out the release:
   - You can choose staged rollout (percentage of users)
   - Or full production release

## Step 6: App Review and Publication

1. Submit your app for review:
   - Google Play team will review your app
   - Review process typically takes hours to several days
   - Check the status in the Google Play Console

2. Address any policy violations if flagged during review:
   - You'll receive email notifications about issues
   - Fix issues and submit a new bundle if needed

3. After approval, your app will be published based on your rollout settings.

## Step 7: Post-Launch Management

1. **Monitor performance**:
   - Use Google Play Console analytics
   - Track installs, ratings, reviews

2. **Plan updates**:
   - Increment versionCode for each update
   - Use release tracks (internal testing, closed testing, open testing, production)

3. **Respond to user feedback**:
   - Reply to user reviews
   - Address common issues in updates

## Special Considerations for Einsteini App

1. **Permissions justification**:
   - Be prepared to explain the need for accessibility and overlay permissions
   - Google may request a demonstration video showing how these permissions are used

2. **Accessibility Service**:
   - Google is strict about accessibility services
   - You must demonstrate that the accessibility service is being used properly
   - Include detailed explanation in your store listing

3. **Overlay Permission**:
   - Provide clear user guidance on enabling this permission
   - Document its purpose and functionality

4. **Privacy Compliance**:
   - Ensure GDPR and privacy policy compliance
   - Disclose all data collection and usage

## Resources

- [Google Play Console Help](https://support.google.com/googleplay/android-developer/)
- [Flutter Deployment Documentation](https://docs.flutter.dev/deployment/android)
- [App Signing Documentation](https://developer.android.com/studio/publish/app-signing) 
# Android Build Instructions

## App Signing for Release

To avoid Google Play Protect warnings when installing the app, you need to properly sign the app with a valid keystore.

### 1. Generate a Keystore

Run the following command to generate a keystore file:

```bash
keytool -genkey -v -keystore ~/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

You'll be prompted to:
- Enter a password for the keystore
- Enter your name, organization details, and location
- Enter a password for the key (can be the same as the keystore password)

### 2. Set up the Keystore in the Project

1. Copy the `key.properties.template` file to `key.properties`:

```bash
cp key.properties.template key.properties
```

2. Edit the `key.properties` file with your keystore details:

```
storeFile=/path/to/your/upload-keystore.jks
storePassword=your_keystore_password
keyAlias=upload
keyPassword=your_key_password
```

3. Make sure to add `key.properties` and your keystore file to `.gitignore` to avoid committing sensitive information.

### 3. Build the Release APK

Run the following command to build a signed release APK:

```bash
flutter build apk --release
```

The signed APK will be located at:
`build/app/outputs/flutter-apk/app-release.apk`

## Avoiding Google Play Protect Warnings

The app requires sensitive permissions for its functionality (overlay and accessibility services). To minimize Google Play Protect warnings:

1. Make sure your app is properly signed with a valid keystore (see above)
2. Consider distributing through the Google Play Store rather than direct APK installation
3. If distributing outside the Play Store, request users to:
   - Tap "Install Anyway" if they see a Google Play Protect warning
   - If completely blocked, they can temporarily disable Play Protect in Google Play settings
   - In Google Play app, go to Settings > Play Protect > Gear icon > disable "Scan apps" temporarily 
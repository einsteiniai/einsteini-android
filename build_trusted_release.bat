@echo off
echo ============================================
echo Building trusted einsteini_v1.0.1.apk...
echo ============================================

echo Cleaning project...
flutter clean

echo Getting packages...
flutter pub get

echo Creating directories for assets...
mkdir -p android\app\src\main\assets

echo Building einsteini_v1.0.1.apk...
flutter build apk --release --verbose

if %ERRORLEVEL% EQU 0 (
    echo Build successful! Copying to root folder...
    copy build\app\outputs\flutter-apk\app-release.apk einsteini_v1.0.1.apk
    echo Done! File saved as einsteini_v1.0.1.apk
    
    echo ============================================
    echo Please install this APK on your device.
    echo If Google Play Protect still shows a warning:
    echo 1. Tap "Install anyway" 
    echo 2. Or disable Play Protect temporarily in 
    echo    Google Play Store > Settings > Play Protect
    echo ============================================
) else (
    echo Build failed.
)
pause 
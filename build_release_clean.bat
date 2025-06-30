@echo off
echo Cleaning project...
flutter clean

echo Getting packages...
flutter pub get

echo Building einsteini_v1.0.1.apk...
flutter build apk --release

if %ERRORLEVEL% EQU 0 (
    echo Build successful! Copying to root folder...
    copy build\app\outputs\flutter-apk\app-release.apk einsteini_v1.0.1.apk
    echo Done! File saved as einsteini_v1.0.1.apk
) else (
    echo Build failed.
)
pause 
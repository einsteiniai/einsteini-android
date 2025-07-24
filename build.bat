@echo off
setlocal enabledelayedexpansion

echo ==============================================================
echo                 Einsteini App Build Script
echo ==============================================================
echo.

:menu
cls
echo Choose a build option:
echo.
echo 1. Clean Project (Deep clean with cache clearing)
echo 2. Clean Fonts (Remove unused fonts and fix references)
echo 3. Development Build
echo 4. Play Store Release (AAB with mapping files)
echo 5. Exit
echo.
set /p choice=Enter your choice (1-5): 

if "%choice%"=="1" goto clean
if "%choice%"=="2" goto cleanfonts
if "%choice%"=="3" goto devbuild
if "%choice%"=="4" goto playstorerelease
if "%choice%"=="5" goto end

echo Invalid choice. Please try again.
timeout /t 2 >nul
goto menu

:clean
echo.
echo ==============================================================
echo                   PERFORMING DEEP CLEAN
echo ==============================================================
echo.

REM Clean Flutter
echo Cleaning Flutter project...
flutter clean

REM Clean Android directories more thoroughly
echo Cleaning Android directories...
if exist "build" rmdir /s /q build
if exist "android\.gradle" rmdir /s /q android\.gradle
if exist "android\app\build" rmdir /s /q android\app\build
if exist "android\.idea" rmdir /s /q android\.idea
if exist ".dart_tool" rmdir /s /q .dart_tool
if exist ".gradle" rmdir /s /q .gradle

REM Completely stop Gradle daemon
echo Stopping Gradle daemon...
cd android
call gradlew --stop
cd ..

REM Delete all backup files and folders from Android resources
echo Removing ALL backup files and folders...
for /r android\app\src\main\res %%f in (*backup*) do (
    echo Removing: %%f
    del /q "%%f"
)
for /r android\app\src\main\res %%f in (*.bak) do (
    echo Removing: %%f
    del /q "%%f"
)
for /d /r android\app\src\main\res %%d in (*backup*) do (
    echo Removing dir: %%d
    rmdir /s /q "%%d"
)

REM Get fresh dependencies
echo Getting fresh dependencies...
flutter pub get

echo Clean completed successfully!
timeout /t 3 >nul
goto menu

:cleanfonts
echo.
echo ==============================================================
echo                   CLEANING FONT FILES
echo ==============================================================
echo.

cd android\app\src\main\res

REM Fix font references without creating backups
echo Fixing font references...
if exist "values\styles.xml" (
    powershell -Command "(Get-Content values\styles.xml) -replace '@font/space_grotesk', '@font/dm_sans' | Set-Content values\styles.xml"
    powershell -Command "(Get-Content values\styles.xml) -replace '@font/inter', '@font/dm_sans' | Set-Content values\styles.xml"
    echo Updated values\styles.xml
)
if exist "layout\content_block.xml" (
    powershell -Command "(Get-Content layout\content_block.xml) -replace '@font/space_grotesk', '@font/dm_sans' | Set-Content layout\content_block.xml"
    powershell -Command "(Get-Content layout\content_block.xml) -replace '@font/inter', '@font/dm_sans' | Set-Content layout\content_block.xml"
    echo Updated layout\content_block.xml
)

REM Remove unused font files
echo Removing unused font files...
cd font
if exist "spacegrotesk_*.ttf" del spacegrotesk_*.ttf
if exist "space_grotesk.xml" del space_grotesk.xml
if exist "inter_*.ttf" del inter_*.ttf
if exist "inter.xml" del inter.xml
echo Removed unused font files

REM Rename font files to follow Android resource naming conventions
echo Renaming font files to follow Android resource naming conventions...

REM Rename DMSans fonts
if exist "DMSans_24pt-Medium.ttf" (
    rename "DMSans_24pt-Medium.ttf" "dmsans_24pt_medium.ttf"
    echo Renamed DMSans_24pt-Medium.ttf to dmsans_24pt_medium.ttf
)
if exist "DMSans_24pt-Regular.ttf" (
    rename "DMSans_24pt-Regular.ttf" "dmsans_24pt_regular.ttf"
    echo Renamed DMSans_24pt-Regular.ttf to dmsans_24pt_regular.ttf
)

REM Rename TikTokSans fonts
if exist "TikTokSans_28pt-Regular.ttf" (
    rename "TikTokSans_28pt-Regular.ttf" "tiktoksans_28pt_regular.ttf"
    echo Renamed TikTokSans_28pt-Regular.ttf to tiktoksans_28pt_regular.ttf
)
if exist "TikTokSans_28pt-Bold.ttf" (
    rename "TikTokSans_28pt-Bold.ttf" "tiktoksans_28pt_bold.ttf"
    echo Renamed TikTokSans_28pt-Bold.ttf to tiktoksans_28pt_bold.ttf
)

cd ..\..\..\..\..\..\

echo Font cleanup completed successfully!
timeout /t 3 >nul
goto menu

:devbuild
echo.
echo ==============================================================
echo                   DEVELOPMENT BUILD
echo ==============================================================
echo.

REM Get dependencies
echo Getting dependencies...
flutter pub get

REM Build debug version
echo Building debug APK...
flutter build apk --debug

echo Development build completed!
echo APK file located at: build\app\outputs\flutter-apk\app-debug.apk
pause
goto menu

:playstorerelease
echo.
echo ==============================================================
echo             PLAY STORE RELEASE BUILD
echo ==============================================================
echo.

REM Ask if user wants to clean first
set /p cleanfirst=Do you want to clean the project first? (y/n): 
if /i "%cleanfirst%"=="y" call :cleansubprocess

REM Ask if user wants to clean fonts
set /p cleanfonts=Do you want to clean and fix fonts? (y/n): 
if /i "%cleanfonts%"=="y" call :cleanfontssubprocess

REM Ask if user wants to disable minification
set /p disableMinify=Do you want to disable minification (solves Play Core issues)? (y/n): 
if /i "%disableMinify%"=="y" call :disableMinifySubprocess

REM Get fresh dependencies
echo Getting fresh dependencies...
flutter pub get

REM Rebuild Gradle from scratch
echo Clean building Gradle project...
cd android
call gradlew clean
cd ..

REM Build the release app bundle with obfuscation and debug symbols
echo Building release app bundle with obfuscation and debug symbols...
echo (This will generate mapping file and native debug symbols)
flutter build appbundle --release --obfuscate --split-debug-info=build/debug-info

REM If the build fails with R8 errors, offer to build without minification
IF %ERRORLEVEL% NEQ 0 (
    echo.
    echo =====================================================
    echo Build failed with R8/ProGuard errors
    echo =====================================================
    echo.
    echo This might be due to issues with Play Core libraries.
    echo.
    set /p tryWithoutMinify=Would you like to try building without minification? (y/n): 
    if /i "%tryWithoutMinify%"=="y" (
        call :disableMinifySubprocess
        echo Building without minification...
        flutter build appbundle --release
    )
)

IF %ERRORLEVEL% EQU 0 (
    echo =====================================================
    echo SUCCESS! Build completed successfully
    echo =====================================================
    echo The app bundle is at: build\app\outputs\bundle\release\app-release.aab
    echo The mapping file is at: build\app\outputs\mapping\release\mapping.txt
    echo The debug symbols are at: build\debug-info\
    echo.
    echo To upload to Play Store:
    echo 1. Upload the app-release.aab file
    echo 2. Upload the mapping.txt file in the Play Console
    echo 3. The native debug symbols are included in the bundle
    echo.
    echo Don't forget to upload the mapping file for crash deobfuscation!
    echo.
) ELSE (
    echo =====================================================
    echo Build failed with error code: %ERRORLEVEL%
    echo =====================================================
    echo.
    echo Check the log messages above for details.
    echo.
)

pause
goto menu

:cleansubprocess
call :clean
return

:cleanfontssubprocess
call :cleanfonts
return

:disableMinifySubprocess
echo Disabling minification in build.gradle...
cd android\app
powershell -Command "(Get-Content build.gradle) -replace 'minifyEnabled true', 'minifyEnabled false' -replace 'shrinkResources true', 'shrinkResources false' | Set-Content build.gradle"
echo Minification disabled.
cd ..\..
return

:end
echo Thank you for using Einsteini App Build Script!
endlocal
exit 
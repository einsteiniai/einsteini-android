@echo off
echo Updating package name from com.example.einsteiniapp to com.einsteini.app in all files...

REM Update package declarations in Kotlin files
echo Updating Kotlin files...
for %%f in (android\app\src\main\kotlin\com\example\einsteiniapp\*.kt) do (
    powershell -Command "(Get-Content '%%f') -replace 'package com.example.einsteiniapp', 'package com.einsteini.app' | Set-Content '%%f'"
)

REM Update MainActivity.kt reference to AccessibilityService
powershell -Command "(Get-Content 'android\app\src\main\kotlin\com\example\einsteiniapp\MainActivity.kt') -replace 'com.example.einsteiniapp.EinsteiniAccessibilityService', 'com.einsteini.app.EinsteiniAccessibilityService' | Set-Content 'android\app\src\main\kotlin\com\example\einsteiniapp\MainActivity.kt'"

REM Update IntentFilter in EinsteiniOverlayService.kt
powershell -Command "(Get-Content 'android\app\src\main\kotlin\com\example\einsteiniapp\EinsteiniOverlayService.kt') -replace 'com.example.einsteiniapp.THEME_CHANGED', 'com.einsteini.app.THEME_CHANGED' | Set-Content 'android\app\src\main\kotlin\com\example\einsteiniapp\EinsteiniOverlayService.kt'"

REM Update iOS and macOS files
echo Updating iOS files...
powershell -Command "Get-ChildItem -Path 'ios' -Recurse -Include '*.xcconfig','*.pbxproj' | ForEach-Object { (Get-Content $_.FullName) -replace 'com.example.einsteiniapp', 'com.einsteini.app' | Set-Content $_.FullName }"

REM Update macOS files
echo Updating macOS files...
powershell -Command "Get-ChildItem -Path 'macos' -Recurse -Include '*.xcconfig','*.pbxproj' | ForEach-Object { (Get-Content $_.FullName) -replace 'com.example.einsteiniapp', 'com.einsteini.app' | Set-Content $_.FullName }"

REM Update Linux files
echo Updating Linux files...
powershell -Command "if (Test-Path 'linux\CMakeLists.txt') { (Get-Content 'linux\CMakeLists.txt') -replace 'com.example.einsteiniapp', 'com.einsteini.app' | Set-Content 'linux\CMakeLists.txt' }"

echo Done! Successfully updated package name in all files.
echo.
echo IMPORTANT: Now run move_kotlin_files.bat to move Kotlin files to the new package directory:
echo From: android\app\src\main\kotlin\com\example\einsteiniapp\
echo To:   android\app\src\main\kotlin\com\einsteini\app\
echo.

pause 
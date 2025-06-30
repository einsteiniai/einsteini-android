@echo off
echo Moving Kotlin files to the new package structure...

REM Create the new directory structure
mkdir android\app\src\main\kotlin\com\einsteini\app 2>nul

REM Copy all Kotlin files to the new directory
copy android\app\src\main\kotlin\com\example\einsteiniapp\*.kt android\app\src\main\kotlin\com\einsteini\app\

echo Files copied successfully!
echo.
echo IMPORTANT: After building, you should delete the old directory:
echo android\app\src\main\kotlin\com\example\einsteiniapp\
echo.
echo Now run build_trusted_release.bat to build the app with the new package name.

pause 
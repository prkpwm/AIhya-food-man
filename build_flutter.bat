@echo off
echo ========================================
echo  Flutter Build - AIhya Food Order App
echo ========================================

cd line_oa_food_order

echo.
echo [1/3] Getting dependencies...
flutter pub get
if %errorlevel% neq 0 (
    echo ERROR: flutter pub get failed
    pause
    exit /b 1
)

echo.
echo [2/3] Building APK (release)...
flutter build apk --release
if %errorlevel% neq 0 (
    echo ERROR: build failed
    pause
    exit /b 1
)

echo.
echo [3/3] Done!
echo APK: line_oa_food_order\build\app\outputs\flutter-apk\app-release.apk
echo.

set APK_PATH=%cd%\build\app\outputs\flutter-apk\app-release.apk
echo Opening output folder...
explorer /select,"%APK_PATH%"

pause

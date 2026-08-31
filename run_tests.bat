@echo off
echo ========================================================
echo         Running Flutter CI Test Suite Locally
echo ========================================================
echo.

echo [1/4] Fetching dependencies...
call flutter pub get
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] flutter pub get failed!
    exit /b %ERRORLEVEL%
)

echo.
echo [2/4] Running Static Analysis...
call flutter analyze --no-fatal-infos
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] flutter analyze detected issues!
    exit /b %ERRORLEVEL%
)

echo.
echo [3/4] Running Unit, Widget, Mock and Flow Tests...
call flutter test --coverage
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] One or more tests failed!
    exit /b %ERRORLEVEL%
)

echo.
echo ========================================================
echo   SUCCESS: All Flutter CI Tests Passed Successfully!
echo ========================================================

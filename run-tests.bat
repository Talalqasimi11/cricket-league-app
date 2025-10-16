@echo off
REM Cricket League App Test Runner for Windows
REM This script provides an easy way to run different types of tests

setlocal enabledelayedexpansion

REM Function to print colored output (Windows doesn't support colors in batch easily)
echo [INFO] Cricket League App Test Runner
echo.

if "%1"=="" goto :help
if "%1"=="help" goto :help
if "%1"=="setup" goto :setup
if "%1"=="test" goto :test
if "%1"=="full" goto :full
if "%1"=="backend" goto :backend
if "%1"=="frontend" goto :frontend
if "%1"=="cleanup" goto :cleanup
goto :help

:help
echo Usage: %0 [OPTION]
echo.
echo Options:
echo   setup     - Set up test environment (install deps, create DB, etc.)
echo   test      - Run tests (assumes environment is set up)
echo   full      - Full test suite (setup + test + cleanup)
echo   backend   - Test backend only
echo   frontend  - Test frontend only
echo   cleanup   - Clean up test environment
echo   help      - Show this help message
echo.
echo Examples:
echo   %0 setup    # Set up test environment
echo   %0 test     # Run tests
echo   %0 full     # Complete test suite
echo   %0 cleanup  # Clean up after tests
goto :end

:setup
echo [INFO] Setting up test environment...
call :check_prerequisites
call :install_dependencies
call :setup_environment
goto :end

:test
echo [INFO] Running tests...
call :start_backend
call :run_tests
call :stop_backend
goto :end

:full
echo [INFO] Running full test suite...
call :check_prerequisites
call :install_dependencies
call :setup_environment
call :start_backend
call :run_tests
call :cleanup
goto :end

:backend
echo [INFO] Testing backend only...
call :start_backend
cd backend
call npm test
cd ..
call :stop_backend
goto :end

:frontend
echo [INFO] Testing frontend only...
cd frontend
call flutter test
cd ..
goto :end

:cleanup
echo [INFO] Cleaning up...
call :stop_backend
if exist test-cleanup.js (
    node test-cleanup.js
)
if exist backend.log del backend.log
echo [SUCCESS] Cleanup completed
goto :end

:check_prerequisites
echo [INFO] Checking prerequisites...
where node >nul 2>&1
if errorlevel 1 (
    echo [ERROR] Node.js is not installed
    exit /b 1
)
where npm >nul 2>&1
if errorlevel 1 (
    echo [ERROR] npm is not installed
    exit /b 1
)
where mysql >nul 2>&1
if errorlevel 1 (
    echo [ERROR] MySQL is not installed or not in PATH
    exit /b 1
)
where flutter >nul 2>&1
if errorlevel 1 (
    echo [ERROR] Flutter is not installed or not in PATH
    exit /b 1
)
echo [SUCCESS] All prerequisites are installed
goto :eof

:install_dependencies
echo [INFO] Installing dependencies...
if exist package.json (
    call npm install
    echo [SUCCESS] Root dependencies installed
)
if exist backend\package.json (
    cd backend
    call npm install
    cd ..
    echo [SUCCESS] Backend dependencies installed
)
if exist frontend\pubspec.yaml (
    cd frontend
    call flutter pub get
    cd ..
    echo [SUCCESS] Frontend dependencies installed
)
goto :eof

:setup_environment
echo [INFO] Setting up test environment...
if not exist backend\.env (
    echo [WARNING] Backend .env file not found. Creating template...
    (
        echo DB_HOST=localhost
        echo DB_USER=root
        echo DB_PASS=your_password
        echo DB_NAME=cricket_league
        echo PORT=5000
        echo.
        echo JWT_SECRET=your_long_random_secret_at_least_32_chars
        echo JWT_REFRESH_SECRET=your_long_random_refresh_secret_at_least_32_chars
        echo JWT_AUD=cric-league-app
        echo JWT_ISS=cric-league-auth
        echo.
        echo CORS_ORIGINS=http://localhost:3000,http://localhost:5000,http://127.0.0.1:5000,http://10.0.2.2:5000
        echo.
        echo NODE_ENV=development
        echo COOKIE_SECURE=false
        echo ROTATE_REFRESH_ON_USE=false
    ) > backend\.env
    echo [WARNING] Please update backend\.env with your database credentials
)
echo [SUCCESS] Test environment setup completed
goto :eof

:start_backend
echo [INFO] Starting backend server...
netstat -an | find "5000" >nul 2>&1
if not errorlevel 1 (
    echo [WARNING] Port 5000 is already in use. Attempting to free it...
    for /f "tokens=5" %%a in ('netstat -ano ^| find "5000"') do taskkill /PID %%a /F >nul 2>&1
)
cd backend
start /b npm start > ..\backend.log 2>&1
cd ..
echo [INFO] Waiting for backend server to start...
timeout /t 5 /nobreak >nul
echo [SUCCESS] Backend server started
goto :eof

:stop_backend
echo [INFO] Stopping backend server...
for /f "tokens=5" %%a in ('netstat -ano ^| find "5000"') do taskkill /PID %%a /F >nul 2>&1
echo [SUCCESS] Backend server stopped
goto :eof

:run_tests
echo [INFO] Running tests...
if exist test-cricket-app.js (
    node test-cricket-app.js
) else (
    echo [ERROR] Test runner not found. Please ensure test-cricket-app.js exists.
    exit /b 1
)
goto :eof

:end
endlocal

# Cricket League App - Frontend

A Flutter application for managing cricket leagues, tournaments, and live scoring.

## Getting Started

This project is a Flutter application that provides a comprehensive cricket league management system with features like:
- User authentication and team management
- Tournament creation and management
- Live ball-by-ball scoring
- Player statistics and scorecards
- Real-time match updates

## Prerequisites

- Flutter SDK (latest stable version)
- Dart SDK
- Android Studio / VS Code with Flutter extensions
- Backend server running (see backend README for setup)

## Installation

1. Clone the repository
2. Navigate to the frontend directory
3. Install dependencies:
   ```bash
   flutter pub get
   ```
4. Run the application:
   ```bash
   flutter run
   ```

## API Configuration

The app automatically detects the platform and uses appropriate API URLs, but you can configure them for different scenarios.

### Default Behavior

The app automatically detects your platform and uses the appropriate default URL:
- **Android Emulator**: `http://10.0.2.2:5000`
- **iOS Simulator**: `http://localhost:5000`
- **Web Browser**: `http://localhost:5000`
- **Desktop (Windows/macOS/Linux)**: `http://localhost:5000`

### Runtime Configuration (New Feature)

You can configure the API URL at runtime through the app:

1. Open the app and navigate to **Settings** → **Account**
2. Tap on **API Configuration** in the Developer Settings section
3. Enter your custom API URL (e.g., `http://192.168.1.100:5000`)
4. Tap **Test Connection** to verify the backend is reachable
5. The URL will be saved and used for all API calls

**Features:**
- Test connection before saving
- Reset to platform default
- Helpful troubleshooting hints
- Secure storage of custom configuration

### Compile-Time Configuration

For advanced users, you can set the API URL at compile time using environment variables:

```bash
flutter run --dart-define=API_BASE_URL=http://192.168.1.100:5000
```

**Note**: Compile-time configuration takes precedence over runtime configuration.

### Physical Device Setup

To connect from a physical Android/iOS device:

1. **Find your computer's IP address:**
   - **Windows**: Open Command Prompt, run `ipconfig`
   - **macOS**: Open Terminal, run `ifconfig | grep inet`
   - **Linux**: Open Terminal, run `ip addr show` or `hostname -I`

2. **Ensure backend is running and accessible:**
   ```bash
   # Test from your computer
   curl http://localhost:5000/health
   
   # Test from your device (replace with your IP)
   curl http://192.168.1.100:5000/health
   ```

3. **Configure the app:**
   - Open the app on your device
   - Go to Settings → Account → API Configuration
   - Enter `http://YOUR_IP:5000` (e.g., `http://192.168.1.100:5000`)
   - Tap "Test Connection"
   - If successful, the URL will be saved

4. **Update backend CORS (if needed):**
   - Add your device's origin to the backend's CORS_ORIGINS in `.env` file
   - Restart the backend server

### Troubleshooting

#### Connection Issues

- **Connection refused**: Backend server is not running or firewall is blocking port 5000
- **Network unreachable**: Ensure your device and computer are on the same network (same WiFi)
- **CORS errors**: Add your origin to backend's CORS_ORIGINS and restart the server
- **401 Unauthorized**: This is an authentication issue, not a connection issue

#### Testing Backend Accessibility

```bash
# Test from computer
curl http://localhost:5000/health

# Test from device (replace with your IP)
curl http://192.168.1.100:5000/health

# Expected response:
{"status":"ok","version":"dev","db":"up"}
```

#### Common Solutions

1. **Firewall**: Ensure port 5000 is not blocked by Windows Firewall or macOS Security
2. **Network**: Both devices must be on the same WiFi network
3. **Backend**: Make sure the backend server is running (`npm start` in backend directory)
4. **CORS**: Add your device's origin to backend CORS configuration

## Development

### Project Structure

```
lib/
├── core/                 # Core utilities and API client
├── features/            # Feature-based modules
│   ├── auth/           # Authentication screens
│   ├── matches/        # Match management
│   ├── teams/          # Team management
│   └── tournaments/    # Tournament management
├── screens/            # General screens
│   ├── settings/       # Settings and configuration
│   └── support/        # Support and feedback
└── main.dart          # App entry point
```

### Key Features

- **Platform-aware API client** with automatic URL detection
- **Secure token storage** using Flutter Secure Storage
- **Real-time updates** for live scoring
- **Offline support** with data caching
- **Responsive design** for mobile and web
- **Dark/Light theme** support

### Dependencies

- `http`: HTTP client for API calls
- `flutter_secure_storage`: Secure storage for tokens and configuration
- `provider`: State management
- `shared_preferences`: Local storage

## Building for Production

```bash
# Android
flutter build apk --release

# iOS
flutter build ios --release

# Web
flutter build web --release
```

## Support

For issues and questions:
1. Check the troubleshooting section above
2. Review the backend README for server configuration
3. Check the app's Developer Settings for connection testing

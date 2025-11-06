# Cricket League Management Application - File Structure Documentation

## Project Overview

This document provides a comprehensive overview of the file structure for the Cricket League Management Application, a full-stack solution consisting of:

- **Frontend**: Flutter mobile application (iOS & Android)
- **Backend**: Node.js REST API with WebSocket support
- **Admin Panel**: React.js web application for system administration
- **Database**: MySQL with migration scripts

---

## Root Directory Structure

```
cricket-league-app/
├── .gitignore                    # Git ignore rules
├── package.json                  # Root package configuration
├── PRD.md                        # Product Requirements Document
├── QUICK_START.md                # Quick start guide
├── README.md                     # Project README
├── admin-panel/                  # React.js admin panel
├── backend/                      # Node.js backend API
├── cricket-league-db/            # Database schema and migrations
├── docs/                         # Documentation files
└── frontend/                     # Flutter mobile application
```

---

## 1. Admin Panel (`admin-panel/`)

React.js web application for system administration and management.

```
admin-panel/
├── package.json                  # Dependencies and scripts
├── package-lock.json             # Lockfile for dependencies
├── README.md                     # Admin panel documentation
├── public/
│   └── index.html                # HTML template
├── src/
│   ├── App.js                    # Main React application
│   ├── index.js                  # Application entry point
│   ├── components/               # React components
│   │   ├── Dashboard.js          # Main dashboard with statistics
│   │   ├── ErrorBoundary.js      # Error boundary component
│   │   ├── Footer.js             # Application footer
│   │   ├── Header.js             # Application header
│   │   ├── Login.js              # Admin login component
│   │   ├── MatchManagement.js    # Match management interface
│   │   ├── ReportingDashboard.js # Reporting and analytics
│   │   ├── Sidebar.js            # Navigation sidebar
│   │   ├── SystemHealth.js       # System health monitoring
│   │   ├── TeamManagement.js     # Team management interface
│   │   ├── Toast.js              # Toast notification component
│   │   ├── TournamentManagement.js # Tournament management
│   │   └── UserManagement.js     # User administration
│   ├── services/
│   │   └── api.js                # API service layer
│   └── utils/
│       ├── auth.js               # Authentication utilities
│       ├── constants.js          # Application constants
│       └── formatting.js         # Data formatting utilities
└── testsprite_tests/             # Test automation files
    ├── standard_prd.json
    ├── testsprite_backend_test_plan.json
    └── testsprite_frontend_test_plan.json
```

---

## 2. Backend (`backend/`)

Node.js REST API server with WebSocket support for real-time features.

```
backend/
├── .env.example                  # Environment variables template
├── index.js                      # Server entry point
├── jest.config.js                # Jest testing configuration
├── package.json                  # Dependencies and scripts
├── package-lock.json             # Lockfile for dependencies
├── README.md                     # Backend documentation
├── __tests__/                    # Unit and integration tests
│   ├── auth.test.js              # Authentication tests
│   ├── feedback.test.js          # Feedback system tests
│   ├── liveScoring.test.js       # Live scoring tests
│   ├── README.md                 # Test documentation
│   ├── teams.test.js             # Team management tests
│   └── tournaments.test.js       # Tournament tests
├── config/                       # Configuration files
│   ├── db.js                     # Database configuration
│   └── validateEnv.js            # Environment validation
├── controllers/                  # Route controllers
│   ├── adminController.js        # Admin panel controllers
│   ├── authController.js         # Authentication controllers
│   ├── BallByBallController.js   # Ball-by-ball scoring
│   ├── feedbackController.js     # Feedback system
│   ├── liveScoreController.js    # Live scoring controllers
│   ├── liveScoreViewerController.js # Score viewing controllers
│   ├── matchFinalizationController.js # Match completion
│   ├── matchInningsController.js # Innings management
│   ├── playerController.js       # Player management
│   ├── playerMatchStatsController.js # Player statistics
│   ├── playerStatsController.js  # Player stats controllers
│   ├── scorecardController.js    # Scorecard generation
│   ├── teamController.js         # Team management
│   ├── teamTournamentSummaryController.js # Tournament summaries
│   ├── tournamentController.js   # Tournament management
│   ├── tournamentMatchController.js # Tournament matches
│   └── tournamentTeamController.js # Tournament teams
├── middleware/                   # Express middleware
│   ├── authMiddleware.js         # Authentication middleware
│   └── rateLimit.js              # Rate limiting middleware
├── routes/                       # API route definitions
│   ├── adminRoutes.js            # Admin panel routes
│   ├── authRoutes.js             # Authentication routes
│   ├── ballByBallRoutes.js       # Ball-by-ball routes
│   ├── feedbackRoutes.js         # Feedback routes
│   ├── liveScoreRoutes.js        # Live scoring routes
│   ├── liveScoreViewerRoutes.js  # Score viewing routes
│   ├── matchFinalizationRoutes.js # Match finalization routes
│   ├── matchInningsRoutes.js     # Innings routes
│   ├── playerMatchStatsRoutes.js # Player stats routes
│   ├── playerRoutes.js           # Player management routes
│   ├── playerStatsRoutes.js      # Player statistics routes
│   ├── scorecardRoutes.js        # Scorecard routes
│   ├── teamRoutes.js             # Team routes
│   ├── teamTournamentSummaryRoutes.js # Tournament summary routes
│   ├── tournamentMatchRoutes.js  # Tournament match routes
│   ├── tournamentRoutes.js       # Tournament routes
│   ├── tournamentTeamRoutes.js   # Tournament team routes
│   └── uploadRoutes.js           # File upload routes
├── testsprite_tests/             # Test automation files
│   ├── standard_prd.json
│   ├── testsprite_backend_test_plan.json
│   └── testsprite_backend_test_plan.json
├── uploads/                      # File upload directory
│   ├── players/                  # Player image uploads
│   └── teams/                    # Team logo uploads
└── utils/                        # Utility functions
    ├── authzPolicy.js            # Authorization policies
    ├── errorMessages.js          # Error message constants
    ├── inputValidation.js        # Input validation utilities
    ├── responseUtils.js          # Response formatting
    ├── safeLogger.js             # Safe logging utilities
    ├── uploadUtils.js            # File upload utilities
    ├── urlValidation.js          # URL validation
    └── validationMessages.js     # Validation messages
```

---

## 3. Database (`cricket-league-db/`)

MySQL database schema and migration scripts.

```
cricket-league-db/
├── admin_migration.sql           # Admin-related migrations
├── complete_schema.sql           # Complete database schema
├── README.md                     # Database documentation
├── README.md.txt                 # Additional documentation
└── schema.sql                    # Core database schema
```

---

## 4. Frontend (`frontend/`)

Flutter mobile application for iOS and Android platforms.

```
frontend/
├── .gitignore                    # Flutter-specific git ignore
├── .metadata                     # Flutter project metadata
├── analysis_options.yaml         # Dart analysis configuration
├── devtools_options.yaml         # DevTools configuration
├── pubspec.yaml                  # Flutter dependencies
├── README.md                     # Frontend documentation
├── android/                      # Android platform files
│   ├── .gitignore
│   ├── build.gradle.kts          # Android build configuration
│   ├── gradle.properties         # Gradle properties
│   ├── settings.gradle.kts       # Gradle settings
│   ├── app/
│   │   ├── build.gradle.kts      # App build configuration
│   │   └── src/
│   │       ├── debug/
│   │       │   └── AndroidManifest.xml
│   │       ├── main/
│   │       │   ├── AndroidManifest.xml
│   │       │   ├── java/
│   │       │   │   └── io/
│   │       │   │       └── flutter/
│   │       │   │           └── plugins/
│   │       │   │               └── GeneratedPluginRegistrant.java
│   │       │   ├── kotlin/
│   │       │   │   └── com/
│   │       │   │       └── example/
│   │       │   │           └── frontend/
│   │       │   │               └── MainActivity.kt
│   │       │   └── res/          # Android resources
│   │       │       ├── drawable/
│   │       │       ├── drawable-v21/
│   │       │       ├── mipmap-hdpi/
│   │       │       ├── mipmap-mdpi/
│   │       │       ├── mipmap-xhdpi/
│   │       │       ├── mipmap-xxhdpi/
│   │       │       ├── mipmap-xxxhdpi/
│   │       │       └── values/
│   │       └── profile/
│   │           └── AndroidManifest.xml
│   └── gradle/
│       └── wrapper/               # Gradle wrapper
├── assets/                       # Application assets
│   ├── fonts/                    # Custom fonts
│   │   ├── OFL.txt
│   │   ├── Poppins-Black.ttf
│   │   ├── Poppins-BlackItalic.ttf
│   │   ├── Poppins-Bold.ttf
│   │   ├── Poppins-BoldItalic.ttf
│   │   ├── Poppins-ExtraBold.ttf
│   │   ├── Poppins-ExtraBoldItalic.ttf
│   │   ├── Poppins-ExtraLight.ttf
│   │   ├── Poppins-ExtraLightItalic.ttf
│   │   ├── Poppins-Italic.ttf
│   │   ├── Poppins-Light.ttf
│   │   ├── Poppins-LightItalic.ttf
│   │   ├── Poppins-Medium.ttf
│   │   ├── Poppins-MediumItalic.ttf
│   │   ├── Poppins-Regular.ttf
│   │   ├── Poppins-SemiBold.ttf
│   │   ├── Poppins-SemiBoldItalic.ttf
│   │   ├── Poppins-Thin.ttf
│   │   └── Poppins-ThinItalic.ttf
│   └── images/                   # Image assets
├── build/                        # Build artifacts
├── integration_test/             # Integration tests
│   └── app_test.dart
├── ios/                          # iOS platform files
│   ├── .gitignore
│   ├── Flutter/
│   │   ├── AppFrameworkInfo.plist
│   │   ├── Debug.xcconfig
│   │   ├── Release.xcconfig
│   │   └── ephemeral/
│   ├── Runner/
│   │   ├── AppDelegate.swift
│   │   ├── Info.plist
│   │   ├── Runner-Bridging-Header.h
│   │   ├── Assets.xcassets/
│   │   ├── Base.lproj/
│   │   └── Tests/
│   │       └── RunnerTests.swift
│   └── Runner.xcodeproj/
│       ├── project.pbxproj
│       └── xcshareddata/
├── lib/                          # Flutter source code
│   ├── lib_dummy_marker.txt      # Marker file
│   ├── main.dart                 # Application entry point
│   ├── core/                     # Core functionality
│   │   ├── api_client.dart       # API client
│   │   ├── api_errors.dart       # API error handling
│   │   ├── auth_provider.dart    # Authentication provider
│   │   ├── cache_service.dart    # Caching service
│   │   ├── connectivity_service.dart # Network connectivity
│   │   ├── error_handler.dart    # Error handling
│   │   ├── json_utils.dart       # JSON utilities
│   │   ├── network_manager.dart  # Network management
│   │   ├── providers.dart        # State providers
│   │   ├── retry_policy.dart     # Retry policies
│   │   ├── secure_storage.dart   # Secure storage
│   │   ├── theme_notifier.dart   # Theme management
│   │   ├── websocket_manager.dart # WebSocket management
│   │   ├── websocket_service.dart # WebSocket service
│   │   ├── websocket_service.dart.new # Updated WebSocket service
│   │   ├── caching/
│   │   │   └── cache_manager.dart # Cache management
│   │   ├── database/             # Local database layer
│   │   │   ├── base_repository.dart # Base repository
│   │   │   ├── hive_service.dart # Hive database service
│   │   │   ├── match_repository.dart # Match repository
│   │   │   ├── player_repository.dart # Player repository
│   │   │   ├── team_repository.dart # Team repository
│   │   │   └── tournament_repository.dart # Tournament repository
│   │   ├── offline/              # Offline functionality
│   │   │   └── offline_manager.dart # Offline manager
│   │   ├── performance/          # Performance monitoring
│   │   │   ├── build_optimizer.dart # Build optimization
│   │   │   └── performance_monitor.dart # Performance monitoring
│   │   └── theme/                # Theme configuration
│   │       ├── colors.dart       # Color definitions
│   │       ├── theme_config.dart # Theme configuration
│   │       └── theme_data.dart   # Theme data
│   ├── features/                 # Feature-based architecture
│   │   ├── auth/                 # Authentication feature
│   │   │   └── screens/
│   │   │       ├── forgot_password_screen.dart
│   │   │       ├── login_screen.dart
│   │   │       └── register_screen.dart
│   │   ├── matches/              # Matches feature
│   │   │   ├── models/
│   │   │   │   └── ball_model.dart
│   │   │   ├── providers/
│   │   │   │   ├── live_match_provider.dart
│   │   │   │   └── match_provider.dart
│   │   │   └── screens/
│   │   │       ├── create_match_screen.dart
│   │   │       ├── live_match_scoring_screen.dart
│   │   │       ├── live_match_view_screen.dart
│   │   │       ├── match_statistics_screen.dart
│   │   │       ├── matches_screen.dart
│   │   │       ├── post_match_screen.dart
│   │   │       ├── scorecard_screen.dart
│   │   │       └── select_lineup_screen.dart
│   │   ├── teams/                # Teams feature
│   │   │   ├── models/
│   │   │   │   └── player.dart
│   │   │   ├── providers/
│   │   │   │   ├── player_provider.dart
│   │   │   │   └── team_provider.dart
│   │   │   └── screens/
│   │   │       ├── my_team_screen.dart
│   │   │       ├── player_dashboard_screen.dart
│   │   │       └── team_dashboard_screen.dart
│   │   └── tournaments/          # Tournaments feature
│   │       ├── models/
│   │       │   └── tournament_model.dart
│   │       ├── providers/
│   │       │   └── tournament_provider.dart
│   │       ├── screens/
│   │       │   ├── tournament_create_screen.dart
│   │       │   ├── tournament_details_creator_screen.dart
│   │       │   ├── tournament_details_viewer_screen.dart
│   │       │   ├── tournament_draws_screen.dart
│   │       │   ├── tournament_team_registration_screen.dart
│   │       │   └── tournaments_screen.dart
│   │       └── widgets/
│   │           ├── tournament_card.dart
│   │           └── tournament_filter_tabs.dart
│   ├── models/                   # Data models
│   │   ├── ball_by_ball.dart
│   │   ├── feedback.dart
│   │   ├── match_innings.dart
│   │   ├── match.dart
│   │   ├── match.g.dart          # Generated model
│   │   ├── pending_operation.dart
│   │   ├── pending_operation.g.dart # Generated model
│   │   ├── player_match_stats.dart
│   │   ├── player.dart
│   │   ├── player.g.dart         # Generated model
│   │   ├── scorecard.dart
│   │   ├── team_tournament_summary.dart
│   │   ├── team.dart
│   │   ├── team.g.dart           # Generated model
│   │   ├── tournament_team.dart
│   │   ├── tournament.dart
│   │   └── tournament.g.dart      # Generated model
│   ├── screens/                  # Screen-based architecture
│   │   ├── home/
│   │   │   └── home_screen.dart
│   │   ├── player/
│   │   │   └── viewer/
│   │   │       └── player_dashboard_screen.dart
│   │   ├── settings/
│   │   │   ├── account_screen.dart
│   │   │   └── developer_settings_screen.dart
│   │   ├── splash/
│   │   │   └── splash_screen.dart
│   │   ├── support/
│   │   │   ├── contact_screen.dart
│   │   │   └── feedback_screen.dart
│   │   └── team/
│   │       └── viewer/
│   │           └── team_dashboard_screen.dart
│   ├── services/                 # Service layer
│   │   ├── api_client.dart
│   │   └── api_service.dart
│   └── widgets/                  # Reusable widgets
│       ├── bottom_nav.dart
│       ├── image_upload_widget.dart
│       ├── optimized_image.dart
│       └── shared/
│           ├── app_bar_widget.dart
│           ├── app_header.dart
│           ├── buttons.dart
│           ├── form_fields.dart
│           ├── index.dart
│           └── status_widgets.dart
├── test/                         # Unit tests
│   ├── api_integration_test.dart
│   ├── auth_provider_test.dart
│   ├── login_validation_test.dart
│   └── widgets_test.dart
├── web/                          # Web platform files
│   ├── flutter_service_worker.js
│   └── offline.html
└── windows/                      # Windows platform files
    ├── .gitignore
    ├── CMakeLists.txt
    ├── flutter/
    │   └── runner/
    └── runner/
```

---

## 5. Documentation (`docs/`)

Project documentation directory.

```
docs/
# (Currently empty - can be expanded with API docs, architecture diagrams, etc.)
```

---

## File Type Summary

### Configuration Files
- `.env.example` - Environment variables template
- `package.json` - Node.js dependencies and scripts
- `pubspec.yaml` - Flutter dependencies and configuration
- `jest.config.js` - Testing configuration
- `analysis_options.yaml` - Dart code analysis rules

### Source Code Files
- **JavaScript/Node.js**: `.js` files in backend and admin-panel
- **Dart/Flutter**: `.dart` files in frontend/lib
- **React**: `.js` files in admin-panel/src

### Generated Files
- `.g.dart` - Generated Dart models (likely from json_serializable)
- `GeneratedPluginRegistrant.java` - Flutter plugin registration

### Test Files
- `.test.js` - Jest test files
- `.test.dart` - Flutter test files
- `app_test.dart` - Integration tests

### Platform-Specific Files
- **Android**: Gradle files, Kotlin/Java source, resources
- **iOS**: Swift/Objective-C, Xcode project files, plist files
- **Web**: Service worker, HTML templates
- **Windows**: CMake configuration

### Assets and Resources
- **Fonts**: Poppins font family in various weights
- **Images**: App icons, launch screens
- **Uploads**: User-uploaded content (player photos, team logos)

---

## Architecture Overview

### Backend Architecture
- **Framework**: Express.js with middleware architecture
- **Database**: MySQL with connection pooling
- **Real-time**: Socket.IO with Redis adapter
- **Authentication**: JWT with refresh token rotation
- **File Storage**: Local filesystem with organized directories
- **Testing**: Jest with integration and unit tests

### Frontend Architecture
- **Framework**: Flutter with provider pattern
- **State Management**: Provider for dependency injection
- **Local Storage**: Hive NoSQL database
- **Offline Support**: Comprehensive offline manager with conflict resolution
- **Networking**: Custom API client with retry policies
- **Real-time**: WebSocket integration for live updates

### Admin Panel Architecture
- **Framework**: React.js with hooks
- **State Management**: React Context API
- **Styling**: Tailwind CSS
- **HTTP Client**: Axios with interceptors
- **UI Components**: Custom component library

### Database Design
- **Schema**: Relational MySQL schema
- **Migrations**: Automated migration system
- **Indexing**: Optimized indexes for performance
- **Relationships**: Foreign key constraints and cascading deletes

---

## Development Workflow

### Backend Development
1. API routes defined in `routes/` directory
2. Business logic in `controllers/` directory
3. Utilities and helpers in `utils/` directory
4. Tests in `__tests__/` directory
5. Configuration in `config/` directory

### Frontend Development
1. Feature-based architecture in `features/` directory
2. Core functionality in `core/` directory
3. Data models in `models/` directory
4. Reusable widgets in `widgets/` directory
5. Screen-based navigation in `screens/` directory

### Admin Panel Development
1. Components in `src/components/` directory
2. API services in `src/services/` directory
3. Utilities in `src/utils/` directory
4. Main application in `src/App.js`

---

## Key Directories and Their Purposes

| Directory | Purpose |
|-----------|---------|
| `admin-panel/` | React.js web application for system administration |
| `backend/` | Node.js REST API server with WebSocket support |
| `cricket-league-db/` | MySQL database schema and migration scripts |
| `frontend/` | Flutter mobile application |
| `docs/` | Project documentation |
| `frontend/lib/core/` | Core Flutter functionality (API, auth, database, etc.) |
| `frontend/lib/features/` | Feature-based architecture for Flutter app |
| `frontend/lib/models/` | Data models for Flutter app |
| `frontend/lib/widgets/` | Reusable UI components |
| `backend/controllers/` | API route handlers |
| `backend/routes/` | API route definitions |
| `backend/utils/` | Backend utility functions |
| `backend/__tests__/` | Backend test files |

---

## File Naming Conventions

### Flutter/Dart Files
- `snake_case.dart` for most files
- `PascalCase.dart` for widgets and screens
- `.g.dart` suffix for generated files

### JavaScript/Node.js Files
- `camelCase.js` for most files
- `PascalCase.js` for classes and constructors

### React Components
- `PascalCase.js` for component files

### Database Files
- `snake_case.sql` for SQL files
- `YYYY-MM-DD_description.sql` for migrations

---

## Build and Deployment

### Backend
- **Development**: `npm run dev` (with nodemon)
- **Production**: `npm start`
- **Testing**: `npm test`

### Frontend
- **Development**: `flutter run`
- **Build Android**: `flutter build apk`
- **Build iOS**: `flutter build ios`
- **Testing**: `flutter test`

### Admin Panel
- **Development**: `npm start`
- **Build**: `npm run build`
- **Testing**: `npm test`

---

## Version Information

- **Project Version**: 1.0.0
- **Flutter Version**: Compatible with SDK >= 3.9.0
- **Node.js Version**: >= 18.18.0
- **React Version**: Latest stable
- **Database**: MySQL 8.0+

---

**Last Updated**: November 3, 2025
**Documentation Version**: 1.0

# 🛡️ IntegriScan

[![Flutter](https://img.shields.io/badge/Flutter-3.0%2B-%2302569B?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.0%2B-%230175C2?logo=dart)](https://dart.dev)
[![Platform](https://img.shields.io/badge/Platform-iOS%20%7C%20Android-%234285F4)](https://flutter.dev)
[![License](https://img.shields.io/badge/License-MIT-%23E25D5D)](LICENSE)
![100% On-Device / Privacy-First](https://img.shields.io/badge/100%25_On--Device-Privacy--First-%2310B981)

> **AI-powered Skin & Scalp Pathology Assistant** designed specifically for diverse skin tones, with a focus on Filipino dermatological patterns. All processing occurs 100% on-device - zero data leaves your phone.

---

## ─── 📱 ARCHITECTURAL OVERVIEW ───

IntegriScan is an Offline-First Hybrid Mobile Application that follows a clean, modular Flutter architecture with clear separation of concerns. All persistent data (Clinical Logs, Scan History, Symptom lists, Disease Library, and app settings) is stored locally using Hive & Hive Flutter, enabling $0 cloud database costs, zero network latency, and instant 100% offline access. The application employs session caching where Firebase Auth handles initial online login, then writes an `isLoggedIn` session flag into a local Hive `authBox`, allowing the app to boot directly to the main dashboard in Airplane Mode without network timeouts. The application uses the Provider package for state management and follows Flutter's recommended patterns for scalable applications.

```
lib/
├── main.dart                  # Application entry point
├── theme/                     # Theme and state management
│   ├── theme_provider.dart    # Dark/light theme state (ChangeNotifier)
│   ├── auth_provider.dart     # Authentication state (ChangeNotifier)
│   ├── app_colors.dart        # Color palettes for light/dark modes
│   ├── button_styles.dart     # Reusable button themes
│   └── spacing.dart           # Consistent spacing utilities
├── models/                    # Data models
│   ├── user.dart              # Authentication user model
│   ├── symptom.dart           # Symptom enumeration for triage
│   ├── body_area.dart         # Body area mapping with SVG icons
│   ├── clinical_log.dart      # Clinical log entry model
│   ├── scan_history_item.dart # Scan history model
│   └── display_item.dart      # Generic display item for suggestions
├── screens/                   # UI Screens (one per bottom nav tab)
│   ├── home_screen.dart       # Dashboard with metrics and quick actions
│   ├── pathology_triage_screen.dart # 4-step pathology assessment wizard
│   ├── clinical_logs_screen.dart    # Time-series log viewer with filtering
│   ├── account_screen.dart    # Profile management and settings
│   └── login_screen.dart      # Authentication screens
├── widgets/                   # Reusable UI components
│   ├── dashboard_header.dart  # App header with logo and user info
│   ├── metrics_banner.dart    # Statistics display component
│   ├── score_hero_card.dart   # Prominent metric display (used in home/triage)
│   ├── symptom_chip.dart      # Interactive symptom selection chips
│   ├── animated_body_part_dropdown.dart # Body area selector
│   ├── skin_fact_card.dart    # Educational skin fact carousel
│   ├── education_carousel.dart # Rotating educational tips
│   ├── ai_suggestion_card.dart # AI-generated recommendations
│   ├── quick_link_tile.dart   # Navigation tiles with icons
│   ├── scan_action_sheet.dart # Photo capture/upload modal
│   ├── scan_photo_preview.dart # Image preview with editing tools
│   ├── high_risk_banner.dart  # Risk alert banner
│   ├── custom_bottom_nav.dart # Bottom navigation with FAB
│   ├── svg_icon.dart          # SVG icon wrapper with fallbacks
│   ├── enhanced_loading.dart  # Custom loading animations
│   ├── skeleton_screens.dart  # Placeholder loading UI
│   └── retry_network_image.dart # Fault-tolerant image loader
├── utils/                     # Utility functions
│   ├── error_handler.dart     # User-friendly error mapping
│   └── retry_util.dart        # Retry mechanism for async operations
└── assets/                    # Static assets
    └── icons/                 # Application icons
```

### Key Architectural Decisions

**State Management**: Provider package with `ChangeNotifier` for global state (theme, auth)

**Navigation**: `IndexedStack` in `MainShell` preserves tab state, avoiding rebuilds on tab switches

**Image Handling**: Efficient image processing with temporary file management and cleanup

**Modularity**: Each feature is encapsulated in its own screen with clear input/output contracts

**Privacy-First**: All data remains on-device using `path_provider` and local storage - no network calls for core functionality

---

## ─── ⚙️ TECHNICAL STACK & SUBSYSTEMS ───

### Technology Stack

| Category | Technology | Purpose |
|----------|------------|---------|
| UI Framework | Flutter 3.0+ | Cross-platform UI development |
| Language | Dart 3.0+ | App logic and UI |
| State Management | Provider | Global state (theme, auth) |
| Local Persistence | Hive & Hive Flutter | NoSQL database for all local data ($0 cost, 100% offline) |
| Image Handling | image_picker, crop | Photo capture and editing |
| Navigation | IndexedStack + AnimatedSwitcher | Tab preservation and step transitions |
| Animation | Flutter's animation framework | Smooth UI transitions |
| Utilities | path_provider, package_info_plus | System integration |
| Dev Tools | Flutter DevTools, flutter_lints | Debugging and linting |

### 🏠 Home Dashboard UI and State Configuration

**File**: `lib/screens/home_screen.dart`

The HomeScreen serves as the application dashboard, presenting an at-a-glance overview of skin health metrics:

- **Skin Health Score**: Prominent hero card displaying a normalized score (0-100) with trend visualization using `_scoreTrend` historical data
- **Weekly Scan Activity**: Custom bar chart (`_WeeklyBars` class) showing scan frequency over past 7 days
- **Quick Actions**: Three primary navigation tiles:
  - Pathology Triage (health_and_safety icon) → triage workflow
  - Clinical Logs (receipt_long icon) → scan history viewer  
  - Skin AI Chatbot (smart_toy icon) → coming soon placeholder
- **AI Suggestions Feed**: Context-aware recommendations based on historical scan patterns
- **Educational Carousel**: Rotating skin facts from `constants/skin_facts.dart`
- **High-Risk Banner**: Conditionally displayed when `_highRiskFlag` is true (set by triage results)
- **Demo Controls**: "Simulate high-risk AI result" button for testing banner visibility

**State Dependencies**: 
- Consumes `ThemeProvider` via `context.watch<ThemeProvider>().colors` for dynamic theming
- Receives callback functions from `MainShell` for navigation and state updates
- Uses `Provider` theme extension for accessing custom color properties

### 🔍 Pathology Triage (4-Step Wizard Execution Logic)

**File**: `lib/screens/pathology_triage_screen.dart`

A comprehensive 5-step workflow (with one transient analyzing step) for dermatological assessment:

#### Step-by-Step Execution Flow

1. **Area Selection** (`_AreaStep`)
   - User selects affected body area from `BodyArea.all` (SCALP, FACE, NECK, ARMS, TORSO, LEGS)
   - Uses `AnimatedBodyPartDropdown` for smooth selection UX
   - Output: `_selectedAreaId` stored in state

2. **Symptom Logging** (`_SymptomStep`) 
   - Multi-select from 9 predefined symptoms in `Symptom.all`:
     - Itching, Redness, Flaking, Bumps, Discoloration, Swelling, Pain, Oozing, Hair Loss
   - Each symptom includes tooltip with clinical description
   - Uses `Wrap` layout with `SymptomChip` components for touch-friendly selection
   - Output: `_selectedSymptomIds` Set<String> tracking selected symptom IDs

3. **Image Capture** (`_CaptureStep`)
   - Options: Take live photo (camera) or upload from gallery
   - Uses `image_picker` with constraints: max 1080x1080px, quality 85%
   - Output: `_capturedImageFile` (XFile reference)

4. **Preview & Edit** (`_PhotoPreviewStep`)
   - Image rotation (±90° increments) via `_rotationAngle` state
   - Cropping functionality using `crop` package
   - Retake option to restart capture
   - Output: `_croppedImageFile` (final edited image)

5. **Analysis & Results** (`_ResultView`)
   - **Risk Calculation Algorithm**:
     ```dart
     final flagCount = _selectedSymptomIds.length;
     final hasSevereSigns = _selectedSymptomIds.contains('bumps') &&
         _selectedSymptomIds.contains('discoloration');
     
     final risk = hasSevereSigns || flagCount >= 5
         ? _TriageRisk.high
         : flagCount >= 2
             ? _TriageRisk.moderate
             : _TriageRisk.low;
     ```
   - **Risk Levels**:
     - Low (≥2 symptoms OR no severe combination): Score 92/100, Green banner
     - Moderate (2-4 symptoms): Score 61/100, Amber banner  
     - High (5+ symptoms OR bumps+discoloration): Score 28/100, Red banner
   - **Result Display**: `ScoreHeroCard` with override color, symptom count, body area label
   - **Callbacks**: 
     - `onTriageComplete(bool isHighRisk)` notifies `MainShell` to show/hide risk banner
          - `onStartOver()` resets all state for new assessment

**Technical Implementation**:
- Uses `IndexedStack`-like pattern with `AnimatedSwitcher` for smooth step transitions
- State management via `setState()` on `_Step` enum (0-4) plus `_analyzing` flag
- Temporary file handling with automatic cleanup in `_cleanupTempFiles()`
- Image provider abstraction: `_displayImageProvider` returns `FileImage` from cropped/original
- Analysis simulation: `Future.delayed(const Duration(milliseconds: 1800))` for realistic UX

### 📓 Clinical Logs (Time-Series Chronological Engine)

**File**: `lib/screens/clinical_logs_screen.dart`

Sophisticated longitudinal tracking system for scan history and trend analysis:

#### Data Model (`lib/models/clinical_log.dart`)
```dart
class ClinicalLogEntry {
  final String id;
  final String bodyArea;           // e.g. "Left Forearm", "Scalp - Crown"
  final String condition;          // AI-suggested label
  final DateTime loggedAt;         // Timestamp
  final double confidence;         // 0.0-1.0 AI confidence
  final RiskLevel risk;            // low/moderate/high enum
  final LogStatus status;          // monitoring/resolved/escalated enum
  final List<double> trend;        // Historical confidence for sparkline
  final IconData icon;             // Condition-specific SVG fallback
  final List<String> recommendations;// Actionable next steps
  final String? imagePath;         // Local asset path to captured image
}
```

#### Core Features

**Chronological Storage & Retrieval**
- In-memory generation via `_generateLogs()` (demo data with realistic progression)
- Real implementation would use local database (shared_preferences, Hive, or SQLite)
- Timezone-aware date handling with `DateTime` objects

**Multi-Dimensional Filtering System** (`_applyFiltersAndSort()`)
1. **Date Range**: Customizable via `showDateRangePicker()` with presets (7d, 30d, 3mo)
2. **Body Parts**: Multi-select from auto-populated `_availableBodyParts` list
3. **Risk Levels**: Filter by `RiskLevel.values` (low/moderate/high)
4. **Status**: Filter by `LogStatus.values` (monitoring/resolved/escalated) 
5. **Minimum Confidence**: Slider from 0.0-1.0 with percentage display
6. **Sort Options**: 8 different sort criteria including date, risk, body part, confidence

**Visualization Components**
- **TableCalendar**: Heatmap-style calendar with event dots representing scan frequency
  - Today highlight: `colors.accent.withValues(alpha: 0.2)` circle
  - Selected day: Solid `colors.acent` circle
  - Event loading: `markers[day] ?? []` map from date to log entries
- **Scan Streak Counter**: Calculates consecutive days scanned (including today/yesterday)
- **Monthly Trend**: Compares current vs previous month volume with ↑/↓/→ indicators
- **Weekly Date Range**: Dynamic header showing "MMM d - MMM d" format

**Interaction Patterns**
- **Tap-to-Expand**: Calendar day tap opens `_showScanPhotoPreviewDialog()` grid view
- **Long-Press Actions**: Share, Edit, Delete, Mark as Reviewed (menu popup)
- **Full-Screen Viewer**: Gesture-dismissible image viewer with progress indicators
- **Empty State**: Educational placeholder with CTA to log first scan

**Performance Optimizations**
- `RetryUtil.retryOperation()` for async data loading with exponential backoff
- Skeleton shimmer loaders during data fetching (`ShimmerSkeleton` widgets)
- Efficient list filtering without rebuilding entire dataset
- Memoized marker computation via `_computeMarkers()`

### 👤 Account Controls, Styling Profiles, and Local Storage Layout

**File**: `lib/screens/account_screen.dart`

Comprehensive user management and personalization center:

#### Authentication State (`lib/theme/auth_provider.dart`)
- **User Model** (`lib/models/user.dart`):
  ```dart
  class User {
    final String id;
    final String email;
    final String displayName;
    final String? photoUrl;
    final bool isEmailVerified;
  }
  ```
- **Providers**: 
  - `ThemeProvider`: Manages dark/light mode via `_isDarkMode` boolean
  - `AuthProvider`: Handles user session with `_user`, `_isLoading`, `_errorMessage`

#### Account Screen Components

**Profile Section**
- Avatar with camera overlay for editing (using `Stack` + `Positioned`)
- Fallback to initials circle when no photo URL
- Email verification status badge (warning color when unverified)
- Display name and email typography hierarchy

**App Information Section**
- Dynamic version loading via `package_info_plus`:
  ```dart
  final PackageInfo packageInfo = await PackageInfo.fromPlatform();
  'Version ${packageInfo.version} (Build ${packageInfo.buildNumber})'
  ```
- Fallback to hardcoded version on error
- Loading state with `CircularProgressIndicator`

**Actions Section** (Conditional on auth state)
- **Scan History**: Quick access to Clinical Logs tab (toast notification)
- **Settings Expansion Tile**:
  - Dark Mode Switch: Two-way binding with `ThemeProvider.setDarkMode()`
  - Notifications Toggle: Placeholder for future backend integration
  - AI Sensitivity Slider: Placeholder for model confidence threshold adjustment
- **Legal Documents**:
  - Privacy Policy: Routes to `PrivacyPolicyScreen` 
  - Terms of Service: Routes to `TermsOfServiceScreen`
- **Sign Out**: Secure logout via `authProvider.logout()` with state cleanup

#### Local Storage Architecture
- **Authentication**: Session state managed via `AuthProvider` with persistent login flag stored in Hive `authBox`
- **Theme Preference**: Persisted via Hive `settingsBox`
- **Clinical Logs**: Stored in Hive `clinicalLogsBox` with automatic cleanup policies
- **Scan History**: Stored in Hive `scanHistoryBox`
- **Symptom Lists & Disease Library**: Stored in Hive `referenceDataBox`
- **App Settings**: Stored in Hive `settingsBox`
- **Image Files**: Stored in app cache directory (via `path_provider`) with cleanup policies
- **Avatar Images**: Would be stored remotely with local caching in production

#### Security Considerations
- Password validation: min 6 chars, email format check
- Error handling: Centralized via `ErrorHandler.getUserFriendlyErrorMessage()`
- Loading states: Prevents duplicate submissions during async operations
- Memory cleanup: Avatar selection avoids reading full bytes into memory unnecessarily

---

## ─── 🛠️ INSTALLATION & COMPILATION PIPELINE ───

### Prerequisites
- Flutter SDK 3.0.0+ (verify with `flutter --version`)
- Dart SDK 3.0.0+ (included with Flutter)
- Android Studio / Xcode (for platform-specific tooling)
- Git (for version control)

### Local Development Setup

#### 1. Repository Setup
```bash
# Clone the repository
git clone https://github.com/yourusername/IntegriScan.git
cd IntegriScan

# Verify Flutter installation
flutter doctor

# Optional: Enable Flutter web for testing
# flutter config --enable-web
```

#### 2. Dependency Installation
```bash
# Fetch all packages defined in pubspec.yaml
flutter pub get

# Verify key dependencies are installed
flutter pub outdated
```

#### 2.1. Generate Hive Adapters
```bash
# Generate Hive TypeAdapters for data models
flutter pub run build_runner build --delete-conflicting-outputs
```

#### 3. Platform Configuration

**Android Setup**:
```bash
# Accept Android licenses (first time only)
flutter doctor --android-licenses

# Optional: Connect Android device or start emulator
adb devices
# or launch emulator from Android Studio
```

**iOS Setup** (macOS only):
```bash
# Install CocoaPods
sudo gem install cocoapods

# Navigate to iOS directory and install pods
cd ios
pod install
cd ..
```

#### 4. Application Execution

**Development Mode** (with hot reload):
```bash
# Run on connected device/emulator
flutter run

# For web debugging (if enabled)
flutter run -d chrome
```

**Release Builds**:
```bash
# Android APK (development)
flutter build apk --debug

# Android APK (release)
flutter build apk --release --obfuscate --split-debug-info=build/app/outputs/symbols

# iOS (release)
flutter build ios --release --no-codesign

# Web production build
flutter build web --release
```

#### 5. Testing
```bash
# Unit and widget tests
flutter test

# Integration tests (requires device/emulator)
flutter integration_test run test/app_test.dart

# Test coverage
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
```

#### 6. Code Quality
```bash
# Dart analysis
flutter analyze

# Format code
flutter format .

# Linting
flutter pub run flutter_lints:2.0.0
```

### Troubleshooting Common Issues

**Dependency Conflicts**:
```bash
# Force redownload dependencies
flutter pub cache repair
flutter pub get
```

**Build Failures**:
```bash
# Clean build artifacts
flutter clean
flutter pub get
```

**Device Connection Issues**:
```bash
# Verify device authorization
flutter devices
# On device: authorize USB debugging when prompted
```

**iOS Specific**:
```bash
# Clear build folder and rebuild
cd ios
pod deintegrate && pod install
cd ..
flutter clean
flutter pub get
```

### CI/CD Considerations

For automated pipelines, the following commands are recommended:
```bash
# Install dependencies
flutter pub get

# Run static analysis
flutter analyze --fatal-infos

# Run tests
flutter test --coverage

# Build artifacts
flutter build apk --release
flutter build ios --release --no-codesign
```

---

## ─── 🔒 COMPLIANCE & PRIVACY MATRIX ───

IntegriScan implements a strict privacy-first architecture where **all data processing occurs 100% on-device**. No personal health information, images, or scan results ever leave the user's device unless explicitly shared by the user.

### Data Flow & Storage Architecture

| Data Type | Storage Location | Transmission | Persistence | User Control |
|-----------|------------------|--------------|-------------|--------------|
| User Profile (Auth Flag) | Hive `authBox` | ❌ Never transmitted | Persistent (survives app restart) | Edit/Delete via Account Screen |
| Theme Preference | Hive `settingsBox` | ❌ Never transmitted | Persistent | Toggle in Settings |
| Clinical Logs | Hive `clinicalLogsBox` | ❌ Never transmitted | Persistent | View/Edit/Delete/Share per entry |
| Captured Images | App cache directory (path_provider) | ❌ Never transmitted | Auto-cleaned after use | Immediate review before processing |
| Scan Metadata | Hive `scanHistoryBox` | ❌ Never transmitted | Persistent | Inherits log entry controls |

### Technical Privacy Safeguards

1. **Zero Network Dependencies for Core Functionality**:
   - All UI rendering, state management, and image processing occurs locally
   - Only network calls: Optional version check (package_info_plus), future auth backend
   - No analytics, telemetry, or crash reporting enabled by default

2. **Image Handling Protocol**:
   - Images captured via `image_picker` remain in temporary storage
   - Processing uses file paths (`XFile.path`) rather than loading full byte arrays into memory
   - Automatic cleanup of temporary files in `_cleanupTempFiles()` method
   - No image caching or persistence beyond immediate processing workflow

3. **State Management Boundaries**:
   - Providers (`ThemeProvider`, `AuthProvider`) hold state only in memory
   - No serialization to disk or transmission without explicit user action
   - Authentication state cleared on logout and app termination

4. **Data Minimization Principles**:
   - Only essential data collected for immediate functionality
   - No persistent identifiers or device fingerprinting
   - Clinical logs store condition labels, not raw image data or detailed diagnoses
   - Location data never accessed or collected

5. **User Consent & Transparency**:
   - Clear permission dialogues for camera/photo access (handled by image_picker)
   - Explicit actions required for data sharing (Share button in log viewer)
   - Privacy Policy and Terms of Service accessible from Account screen
   - No hidden data collection or background processing

### Compliance Framework Alignment

**HIPAA-Adjacent Safeguards** (for educational/wellness context):
- **Access Control**: Authentication required for personal data access
- **Audit Controls**: User-initiated actions logged via UI interactions (conceptual)
- **Integrity**: Local processing ensures data isn't altered in transit
- **Transmission Security**: No transmission of PHI by design

**GDPR Principles**:
- **Data Minimization**: Only collects data necessary for core functionality
- **Storage Limitation**: Session-only storage in demo; would implement retention policies in production
- **User Rights**: Access, rectification, erasure via UI controls
- **Privacy by Design**: Architecture prevents accidental data leakage

**Medical Device Software Considerations**:
- Clearly marked as educational/tracking tool (see Medical Disclaimer)
- No claims of diagnostic capability
- Decision support limited to risk stratification for user awareness
- Strong emphasis on professional consultation for high-risk results

### Production-Ready Enhancements

For deployed versions, additional privacy measures would include:
- **Secure Storage**: Encrypted local database (Hive with encryption, SQLCipher, Encrypted SharedPreferences)
- **Biometric Authentication**: Optional Face ID/Touch ID for app access
- **Export Controls**: Encrypted export with user-controlled decryption
- **Remote Wipe**: Ability to clear all data via authenticated web portal
- **Open Source Transparency**: Public codebase allows independent security auditing

---

## ─── ⚠️ MEDICAL DISCLAIMER ───

> **IMPORTANT MEDICAL DISCLAIMER**
> 
> **IntegriScan is an educational skin and scalp tracking utility designed for wellness awareness and preventive care monitoring. It is NOT a medical diagnostic device, nor is it intended to replace professional medical advice, diagnosis, or treatment.**
> 
> #### Scope of Functionality
> - **Educational Tool**: Provides general skin health information and tracking capabilities
> - **Tracking Utility**: Enables users to monitor changes in skin conditions over time
> - **Awareness Support**: Helps users identify patterns that may warrant professional consultation
> - **Resource Facilitator**: Assists in preparing for healthcare consultations with historical data
> 
> #### Limitations & Restrictions
> ❌ **Does NOT diagnose** any medical conditions, including but not limited to:
> - Skin cancer (melanoma, carcinoma, etc.)
> - Infectious skin conditions (fungal, bacterial, viral)
> - Chronic dermatological disorders (psoriasis, eczema, rosacea)
> - Allergic reactions or autoimmune skin disorders
> 
> ❌ **Does NOT provide** medical advice, treatment recommendations, or clinical assessments
> ❌ **Does NOT replace** the need for in-person evaluation by licensed healthcare professionals
> ❌ **Does NOT analyze** histopathological, genetic, or molecular markers
> ❌ **Does NOT interpret** lab results, biopsies, or clinical test data
> 
> #### Intended Use Case
> IntegriScan is designed for:
> - Tracking visible changes in moles, lesions, or skin areas over time
> - Monitoring symptom progression or improvement
> - Preparing objective data for dermatologist consultations
> - Increasing personal awareness of skin health patterns
> - Supporting preventive care routines and self-examination reminders
> 
> #### Required Professional Consultation
> Users should **always consult with a qualified healthcare provider** for:
> - Any new, changing, or unusual skin growths, lesions, or discolorations
> - Persistent symptoms lasting more than 2 weeks
> - Signs of infection (increased pain, redness, swelling, warmth, pus)
> - Bleeding, itching, or pain in skin areas
> - Family history of skin cancer or significant sun exposure
> - Before starting or modifying any treatment regimen
> 
> #### Liability Limitation
> The developers, contributors, and distributors of IntegriScan:
> - Make no warranties, express or implied, regarding accuracy or completeness
> - Assume no liability for medical decisions based solely on app-generated information
> - Are not responsible for delayed diagnosis resulting from reliance on the app
> - Recommend the app be used as a complement to, not substitute for, professional care
> 
> #### Regulatory Status
> IntegriScan:
> - Is not cleared, approved, or certified by the FDA, CE, or any other regulatory body as a medical device
> - Is not intended for use in the detection, diagnosis, mitigation, treatment, or prevention of any disease
> - Should not be used in emergency situations or as a substitute for emergency medical services
> - Is subject to local laws and regulations regarding health and wellness applications
> 
> By using IntegriScan, you acknowledge that you have read, understood, and agree to this disclaimer. When in doubt about any skin condition, seek immediate professional medical evaluation.

---

*Last updated: August 27, 2026*  
*Version: 1.0.0+1*  
*Built with Flutter ❤️ for healthier skin awareness*
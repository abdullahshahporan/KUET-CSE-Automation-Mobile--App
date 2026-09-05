> **Current development and security setup:** follow [docs/SETUP.md](docs/SETUP.md). Use the matching authenticated backend and database migrations; legacy anonymous authentication and writes are no longer supported.

# KUET CSE Automation (Mobile App)

<div align="center">

![Flutter](https://img.shields.io/badge/Flutter-3.10.3+-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-3.10.3+-0175C2?style=for-the-badge&logo=dart&logoColor=white)
![Supabase](https://img.shields.io/badge/Supabase-3ECF8E?style=for-the-badge&logo=supabase&logoColor=white)

A reusable Flutter client for a **Department Automation System**, providing connected academic workflows for **students**, **teachers**, and **class representatives**.

[Features](#features) • [Tech Stack](#tech-stack) • [Installation](#installation) • [Configuration](#configuration) • [Usage](#usage) • [Architecture](#architecture)

</div>

---

## 📱 Overview

KUET CSE Automation is a role-aware mobile application designed to digitize and simplify department-level academic operations. It shares data and secure backend routes with the [web portal and TV Player repository](https://github.com/abdullahshahporan/KUET-CSE-Automation-Web-Portal).

> ℹ️ **Named implementation:** “KUET CSE Automation” is the name of the current reference deployment. The application architecture and workflows can be configured and rebranded for other academic departments or institutions.

### Key Highlights

- 🎓 **Dual-Role Support**: Separate interfaces for Students and Teachers
- 🔐 **Secure Authentication**: Server-validated sign-in, persisted sessions, and optional device biometrics
- 🌓 **Theme Support**: Beautiful Light and Dark themes with instant switching
- 📍 **Geo-Attendance**: Time-, location-, enrolment-, code-, and biometric-aware attendance
- 🔔 **Connected Notifications**: In-app inbox, Supabase Realtime, FCM push, reminders, and deep links
- 📊 **Real-time Data**: Live updates from the shared Supabase backend
- 📱 **Native Feel**: Material Design with custom animations and components
- 🔄 **Session Persistence**: Automatic login with session management

---

## ✨ Features

### 🎨 Common Features

#### Splash Screen
- Animated splash screen with fade-in effects
- Automatic session detection and navigation
- CSE branding and theming

#### Authentication
- **Sign In**: Email/password authentication through the secure web backend
- **Biometric Unlock**: Optional device biometric sign-in after initial credential verification
- **Change Password**: Secure password update functionality
- **Session Management**: Persistent state using secure storage and local preferences
- **Role-based Routing**: Automatic redirection based on user role (Student/Teacher)

#### Theme System
- **Light/Dark Mode**: Toggle between themes instantly
- **Persistent Theme**: Theme preference saved across sessions
- **Custom Color Palette**: Carefully designed color schemes for both modes
- **Animated Transitions**: Smooth theme switching animations

#### Notifications and Reminders
- **Persistent Inbox**: Per-user notification history and read state
- **Realtime Updates**: Supabase Realtime subscription with optional background polling
- **Push Delivery**: Firebase Cloud Messaging for foreground, background, and terminated-app delivery
- **Local Reminders**: Scheduled class and examination reminders
- **Deep Links**: Open the relevant attendance, schedule, examination, notification, or request screen

### 👨‍🎓 Student Features

#### Home Dashboard
- **Welcome Section**: Personalized greeting with student name
- **Quick Actions Grid**: 
  - Class Schedule
  - Exam Schedule
  - Attendance Tracker
  - Notice Board
- **Recent Updates**: Latest announcements and notices

#### Schedule Management
- **Unified Schedule View**: Tabbed interface for Class and Exam schedules
- **Class Schedule**: 
  - Day-wise class timings
  - Course details with room numbers
  - Teacher information
- **Exam Schedule**: 
  - Upcoming exam dates and times
  - Course-wise exam details
  - Countdown to exams

#### Attendance System
- **Attendance Overview**: Visual representation of attendance
- **Course-wise Breakdown**: Attendance percentage per course
- **Attendance History**: Date-wise attendance records
- **Alerts**: Low attendance warnings
- **Geo-Attendance Rooms**: Discover active rooms for the student's cohort
- **Verified Submission**: Check time window, enrolment, Haversine distance, optional room code, duplicate state, and device biometrics
- **Presence Monitoring**: Detect extended departure from the allowed radius after check-in

#### Academic Results
- **Result Presentation**: Theory/laboratory cards and GPA-oriented layouts
- **Current Status**: The bundled screen contains demonstration data; production result retrieval and publishing must be connected by the deployment

#### Curriculum
- **Year-wise View**: Browse curriculum by academic year
- **Course Details**: 
  - Course code and title
  - Credit hours
  - Course type (Theory/Lab/Sessional)
- **Curriculum Planning**: Complete 4-year program overview

#### Profile Management
- **Personal Information**: Student details and bio
- **Academic Info**: Roll number, year, term, section
- **Settings**: Account settings and preferences
- **Logout**: Secure session termination

#### Resources
- **Categorized Catalog**: Browse study-resource categories and details
- **Reference Links**: Open configured learning resources with the device browser

#### Notice Board
- **Department Notices**: Latest announcements from CSE department
- **Category Filters**: Filter notices by type (Academic/Event/General)
- **Search**: Quick search through notices
- **Details View**: Full notice content with timestamps

#### Class-Representative Workflows
- **Room Booking**: Check permanent routines and date-specific reservations before requesting a room
- **Conflict Handling**: First-come-first-served allocation with occupied/free period visibility
- **Examination Management**: Create, update, and remove cohort examination entries
- **Synchronization**: Approved bookings feed shared schedules, notifications, and TV display data

### 👨‍🏫 Teacher Features

#### Teacher Home Dashboard
- **Course Overview**: List of assigned courses
- **Today's Schedule**: Current day's classes at a glance
- **Quick Stats**: Student count, pending tasks
- **Course Cards**: Visual course representation with details

#### Course Management
- **Course Details**: 
  - Enrolled students list
  - Course information
  - Meeting schedule
- **Announcements**: Send course- or cohort-targeted notices
- **Quick Actions**: Open roll call, geo-attendance, component entry, schedules, and course rosters

#### Attendance Management
- **Roll Call**: Mark enrolled students present, late, or absent
- **Geo-Attendance Room**: Select a physical room and configure radius, duration, grace interval, and verification code
- **Live Submissions**: Review attendance status and submitted distances while a room is active
- **Session Control**: Close active rooms and inspect recent attendance rooms

#### Grading System
- **Component-entry UI**: CT, assignment, quiz, laboratory, attendance, and other assessment fields
- **Current Status**: The mobile save action is not yet connected to persistent result publication

#### Schedule Management
- **View Schedule**: Personal teaching schedule
- **Room Information**: Classroom assignments
- **Timing Details**: Class timings and duration
- **Room Requests**: Inspect classroom/laboratory schedules and request available slots

#### Student Management
- **Student List**: View enrolled students
- **Student Details**: Access student profiles
- **Communication**: Send announcements to the relevant students

#### Announcements
- **Create Notices**: Post announcements from the teacher workflow
- **Targeted Notices**: Send course- or cohort-specific updates
- **Delivery**: Feed the shared in-app and push-notification pipeline

#### Teacher Profile
- **Personal Information**: Teacher details and credentials
- **Assigned Courses**: List of teaching assignments
- **Contact Information**: Email and contact details
- **Account Controls**: Edit profile information and change the password

#### FAB Menu
- **Quick Actions**: Floating action button for common tasks
- **Create Announcement**: Rapid announcement entry
- **Request Room**: Rapid access to the teacher room-request workflow

#### Teacher Assistant
- **Verified Schedule Answers**: Assigned courses, today/tomorrow, next class, weekly, and next-week schedules
- **Server-side Identity**: Assistant requests are tied to the authenticated teacher session
- **Optional General AI**: Gemini or OpenAI can answer non-private general support questions when configured on the web backend

---

## 🛠 Tech Stack

### Frontend
- **Framework**: Flutter 3.10.3+
- **Language**: Dart 3.10.3+
- **State Management**: 
  - Provider (Theme management)
  - Riverpod (Complex state management)
- **UI Components**: Material Design
- **Animations**: Custom animated components

### Backend
- **Database**: Supabase (PostgreSQL)
- **Authentication**: Custom authentication with bcrypt
- **Storage**: Supabase Storage (for files/images)
- **Real-time**: Supabase Real-time subscriptions

### Key Dependencies
```yaml
dependencies:
  flutter: sdk: flutter
  cupertino_icons: ^1.0.8
  intl: ^0.20.2                    # Date/time formatting
  provider: ^6.1.5+1               # State management
  flutter_riverpod: ^3.1.0         # Advanced state management
  supabase_flutter: ^2.12.0        # Backend integration
  bcrypt: ^1.2.0                   # Password hashing
  shared_preferences: ^2.5.4       # Local storage
```

### Development
- **Linting**: flutter_lints ^6.0.0
- **Testing**: flutter_test (built-in)
- **IDE**: VS Code / Android Studio

---

## 📦 Installation

### Prerequisites

Before you begin, ensure you have:
- **Flutter SDK** 3.10.3 or higher ([Install Flutter](https://flutter.dev/docs/get-started/install))
- **Dart SDK** 3.10.3 or higher (comes with Flutter)
- **Android Studio** or **VS Code** with Flutter extensions
- **Android SDK** (for Android development)
- **Xcode** (for iOS development, macOS only)
- **Git** for version control

### Step 1: Clone the Repository

```bash
git clone https://github.com/abdullahshahporan/KUET-CSE-Automation-Mobile--App.git
cd KUET-CSE-Automation-Mobile--App
```

### Step 2: Install Dependencies

```bash
flutter pub get
```

### Step 3: Configure Supabase

1. Create a Supabase project at [supabase.com](https://supabase.com)
2. Create a file `lib/config/supabase_config.dart`:

```dart
class SupabaseConfig {
  static const String supabaseUrl = 'YOUR_SUPABASE_URL';
  static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';
}
```

3. Set up your Supabase database schema (see [Database Schema](#database-schema) section)

### Step 4: Verify Installation

```bash
flutter doctor
```

Ensure all checks pass. Fix any issues reported.

### Step 5: Run the App

```bash
# Run on connected device or emulator
flutter run

# For specific platform
flutter run -d android
flutter run -d ios
```

### Building for Production

#### Android (APK)
```bash
flutter build apk --release
```

#### Android (App Bundle)
```bash
flutter build appbundle --release
```

#### iOS
```bash
flutter build ios --release
```

The built files will be located in:
- Android APK: `build/app/outputs/flutter-apk/app-release.apk`
- Android Bundle: `build/app/outputs/bundle/release/app-release.aab`
- iOS: `build/ios/archive/Runner.xcarchive`

---

## ⚙️ Configuration

### Database Schema

The mobile app uses the same normalized Supabase/PostgreSQL schema as the web
portal. Apply the schema and migrations from the
[web/TV repository](https://github.com/abdullahshahporan/KUET-CSE-Automation-Web-Portal)
rather than creating a separate mobile database.

The shared data model covers profiles, students, teachers, courses, offerings,
enrolments, curriculum, rooms, recurring routine slots, date-specific
bookings, examinations, normalized attendance sessions and records,
geo-attendance rooms/codes/logs, notices, notification targets/read state,
device tokens, push outbox entries, CMS content, and TV display configuration.

### Environment Variables

Copy the provided templates and configure the deployment-specific endpoints:

- `lib/config/supabase_config.dart.template` → `lib/config/supabase_config.dart`
- `lib/config/push_config.dart.template` → `lib/config/push_config.dart`
- `lib/config/ai_config.dart.template` → `lib/config/ai_config.dart`

Keep private server/provider credentials out of the mobile application. The
Supabase service-role key, FCM service account, and AI-provider keys belong on
the web/server side and must never be compiled into the app.

---

## 📖 Usage

### First Time Setup

1. **Launch the App**: Open the app on your device
2. **Wait for Splash Screen**: The app will check for existing sessions
3. **Sign In**: If no session exists, you'll be redirected to the sign-in screen
4. **Enter Credentials**: Use credentials provisioned by the department deployment
5. **Role Detection**: The app automatically detects if you're a student or teacher
6. **Navigate**: Explore features based on your role

### Student Workflow

1. **Dashboard**: View quick actions and recent updates
2. **Check Schedule**: Tap "Class Schedule" or "Exam Schedule"
3. **Track Attendance**: Monitor your attendance percentage
4. **Join Geo-Attendance**: Open an active room, verify location/code, and confirm with device biometrics
5. **Use CR Tools**: Authorized class representatives can manage room and examination workflows
6. **Read Notices and Resources**: Stay updated with announcements and configured study links

### Teacher Workflow

1. **View Courses**: See all assigned courses on home screen
2. **Mark Attendance**: Run roll call or open a geo-attendance room
3. **Post Announcements**: Create targeted updates for students
4. **Manage Students**: View enrolled course rosters
5. **Request Rooms**: Inspect availability and submit a room request
6. **Use the Assistant**: Ask authenticated course and schedule questions

---

## 🏗 Architecture

### Project Structure

```
lib/
├── Auth/                        # Authentication screens
│   ├── Sign_In_Screen.dart
│   └── change_password_screen.dart
├── Student Folder/              # Student-specific features
│   ├── Attendance/              # Attendance tracking
│   ├── Common Screen/           # Shared screens (splash, navbar)
│   ├── Curriculum/              # Curriculum viewer
│   ├── Home/                    # Student home dashboard
│   │   └── Features/            # Feature screens
│   │       ├── Attendance/
│   │       ├── Notice/
│   │       └── Schedule/
│   ├── Home_Central/            # Central home screen
│   ├── Profile/                 # Student profile
│   ├── Resource/                # Study resources
│   ├── Result/                  # Academic results
│   ├── data/                    # Static data
│   ├── models/                  # Data models
│   └── providers/               # State providers
├── Teacher/                     # Teacher-specific features
│   ├── Announcements/           # Notice management
│   ├── Attendance/              # Attendance marking
│   ├── Fab_Menu/                # Quick actions menu
│   ├── Grading/                 # Grade entry system
│   ├── Room_info/               # Room information
│   ├── Schedule/                # Teacher schedule
│   ├── Students/                # Student management
│   ├── Teacher_Profile/         # Teacher profile
│   ├── course_detail_screen.dart
│   ├── data/                    # Static data
│   ├── teacher_home_content.dart
│   └── teacher_navbar/          # Teacher navigation
├── config/                      # Configuration files
│   └── supabase_config.dart     # Supabase credentials (gitignored)
├── services/                    # Backend services
│   └── supabase_service.dart    # Supabase integration
├── shared/                      # Shared widgets
│   └── profile_widgets.dart
├── theme/                       # Theme configuration
│   ├── animated_components.dart
│   └── app_colors.dart
├── app.dart                     # Root app widget
├── app_theme.dart               # Theme provider
└── main.dart                    # Entry point
```

### Design Patterns

- **Provider Pattern**: For theme management
- **Riverpod**: For complex state management
- **Service Pattern**: Centralized Supabase service
- **Repository Pattern**: Data access layer (implicit in services)
- **Widget Composition**: Reusable widget components

### Data Flow

1. **UI Layer**: Flutter widgets (screens and components)
2. **State Management**: Provider/Riverpod for state
3. **Service Layer**: Feature services coordinate secure web APIs, Supabase queries, notifications, and device capabilities
4. **Backend**: Next.js API routes plus Supabase PostgreSQL, Realtime, and push-dispatch services
5. **Device Layer**: Secure storage, local preferences, biometrics, geolocation, FCM, background services, and local notifications

---

## 🧪 Testing

### Run Tests

```bash
# Run all tests
flutter test

# Run with coverage
flutter test --coverage

# Run specific test file
flutter test test/widget_test.dart
```

### Test Structure

```
test/
└── widget_test.dart    # Widget tests
```

---

## 🔐 Security

### Authentication Security
- **Password Hashing**: Bcrypt with salt for password storage
- **Server Validation**: Credentials are verified through the web backend rather than exposing password records to the client
- **Session Management**: Sensitive session state uses secure device storage
- **Biometric Gate**: Optional local biometrics protect sign-in convenience and geo-attendance submission

### Data Security
- **Role-based Access**: Students and Teachers have separate data access
- **Identity Binding**: Sensitive backend routes derive identity from the authenticated session
- **Query Filtering**: Queries are filtered by role, enrolment, course assignment, term, and section where applicable
- **SQL Injection Prevention**: Supabase parameterized queries
- **HTTPS**: All API calls over secure HTTPS

### Best Practices
- Supabase credentials in gitignored config file
- No hardcoded secrets in source code
- Row-level security policies in Supabase
- Input validation on all forms
- Service-role, FCM service-account, and AI-provider keys remain server-side

---

## 🤝 Contributing

We welcome contributions! Here's how you can help:

### Getting Started

1. **Fork the repository**
2. **Create a feature branch**
   ```bash
   git checkout -b feature/your-feature-name
   ```
3. **Make your changes**
4. **Test your changes**
   ```bash
   flutter test
   flutter analyze
   ```
5. **Commit with meaningful messages**
   ```bash
   git commit -m "Add: Brief description of changes"
   ```
6. **Push to your fork**
   ```bash
   git push origin feature/your-feature-name
   ```
7. **Create a Pull Request**

### Coding Standards

- Follow [Effective Dart](https://dart.dev/guides/language/effective-dart) guidelines
- Use meaningful variable and function names
- Comment complex logic
- Keep functions small and focused
- Write tests for new features
- Run `flutter analyze` before committing

### Commit Message Format

```
Type: Brief description

Optional detailed explanation

Types: Add, Update, Fix, Remove, Refactor, Style, Test, Docs
```

---

## 📝 Known Issues & Limitations

- iOS version not fully tested (Android primary target)
- Result screens and teacher component-entry screens are not yet connected to a complete persistent publishing workflow
- Resource content is a configured catalog; in-app teacher file upload is not implemented
- Full offline operation is not supported because authoritative academic records remain server-backed
- Geo-attendance quality depends on device permission, GPS accuracy, room coordinates, and deployment anti-spoofing controls

---

## 🗺 Roadmap

### Phase 1 (Current)
- ✅ Basic authentication
- ✅ Student dashboard
- ✅ Teacher dashboard
- ✅ Roll-call and geo-attendance tracking
- ✅ Class and examination schedules
- ✅ CR room and examination workflows
- ✅ Realtime inbox, FCM push, and local reminders
- ✅ Teacher schedule assistant

### Phase 2 (In Progress)
- 🔄 Persistent grading and result publication
- 🔄 Deployment-managed resource publishing
- 🔄 Improved result analytics
- 🔄 Wider automated test coverage

### Phase 3 (Planned)
- 📋 Assignment submission system
- 📋 Online examination module
- 📋 Discussion forum
- 📋 Parent portal
- 📋 Analytics dashboard

### Phase 4 (Future)
- 📋 API for third-party integrations
- 📋 AI-powered recommendations

---

## 📄 License

Distributed under the **MIT License**. See [`LICENSE.txt`](./LICENSE.txt) for details.

---

## 👥 Authors

**Abdullah Md. Shahporan**


**Asif Jawad**

**Department of Computer Science and Engineering**

**Khulna University of Engineering & technology**





<div align="center">



[⬆ Back to Top](#kuet-cse-automation-mobile-app)

</div>

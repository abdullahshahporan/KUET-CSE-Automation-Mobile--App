# KUET CSE Automation (Mobile App)

<div align="center">

![Flutter](https://img.shields.io/badge/Flutter-3.10.3+-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-3.10.3+-0175C2?style=for-the-badge&logo=dart&logoColor=white)
![Supabase](https://img.shields.io/badge/Supabase-3ECF8E?style=for-the-badge&logo=supabase&logoColor=white)

A comprehensive Flutter mobile application for **KUET Computer Science & Engineering** department to streamline academic management for both **Students** and **Teachers**. The app provides a centralized platform for managing schedules, attendance, resources, grades, announcements, and more.

[Features](#features) • [Tech Stack](#tech-stack) • [Installation](#installation) • [Configuration](#configuration) • [Usage](#usage) • [Architecture](#architecture)

</div>

---

## 📱 Overview

KUET CSE Automation is a full-featured mobile application designed to digitize and simplify academic operations at the Computer Science & Engineering department of KUET. The app supports role-based access for Students and Teachers, with dedicated interfaces and features for each role.

### Key Highlights

- 🎓 **Dual-Role Support**: Separate interfaces for Students and Teachers
- 🔐 **Secure Authentication**: Supabase-powered authentication with bcrypt password hashing
- 🌓 **Theme Support**: Beautiful Light and Dark themes with instant switching
- 📊 **Real-time Data**: Live updates from Supabase backend
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
- **Sign In**: Email/password authentication with bcrypt verification
- **Change Password**: Secure password update functionality
- **Session Management**: Persistent login with SharedPreferences
- **Role-based Routing**: Automatic redirection based on user role (Student/Teacher)

#### Theme System
- **Light/Dark Mode**: Toggle between themes instantly
- **Persistent Theme**: Theme preference saved across sessions
- **Custom Color Palette**: Carefully designed color schemes for both modes
- **Animated Transitions**: Smooth theme switching animations

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

#### Academic Results
- **Year and Term Selection**: View results by academic year and term
- **Theory Courses**: Detailed marks breakdown (CT, Mid, Final)
- **Lab Courses**: Lab performance and grades
- **GPA Calculation**: Automatic GPA computation

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
- **Study Materials**: Access to course materials
- **Lecture Notes**: Downloadable content
- **Previous Papers**: Past exam papers
- **Reference Materials**: Additional learning resources

#### Notice Board
- **Department Notices**: Latest announcements from CSE department
- **Category Filters**: Filter notices by type (Academic/Event/General)
- **Search**: Quick search through notices
- **Details View**: Full notice content with timestamps

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
- **Material Upload**: Share course materials
- **Announcements**: Course-specific notices

#### Attendance Management
- **Mark Attendance**: Easy attendance marking interface
- **Date Selection**: Mark attendance for any date
- **Student List**: Complete class roster
- **Attendance Reports**: Generate and view attendance reports
- **Statistics**: Attendance trends and analytics

#### Grading System
- **Enter Marks**: Input CT, Mid, Final marks
- **Grade Calculation**: Automatic grade computation
- **Result Publishing**: Publish results to students
- **Performance Analytics**: Class performance overview

#### Schedule Management
- **View Schedule**: Personal teaching schedule
- **Room Information**: Classroom assignments
- **Timing Details**: Class timings and duration

#### Student Management
- **Student List**: View enrolled students
- **Student Details**: Access student profiles
- **Performance Tracking**: Monitor student progress
- **Communication**: Send messages to students

#### Announcements
- **Create Notices**: Post department-wide announcements
- **Targeted Notices**: Send course-specific notices
- **Edit/Delete**: Manage existing announcements
- **Schedule Posts**: Schedule announcements for future

#### Teacher Profile
- **Personal Information**: Teacher details and credentials
- **Assigned Courses**: List of teaching assignments
- **Office Hours**: Set and display office hours
- **Contact Information**: Email and contact details

#### FAB Menu
- **Quick Actions**: Floating action button for common tasks
- **Create Notice**: Quick announcement posting
- **Mark Attendance**: Fast access to attendance marking
- **Add Material**: Quick material upload

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

Your Supabase database should include the following tables:

#### Profiles Table
```sql
CREATE TABLE profiles (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  email TEXT UNIQUE NOT NULL,
  password_hash TEXT NOT NULL,  -- bcrypt hashed password
  role TEXT NOT NULL CHECK (role IN ('student', 'teacher')),
  full_name TEXT NOT NULL,
  created_at TIMESTAMP DEFAULT NOW()
);
```

#### Students Table
```sql
CREATE TABLE students (
  id UUID PRIMARY KEY REFERENCES profiles(id),
  roll_number TEXT UNIQUE NOT NULL,
  year INTEGER NOT NULL,
  term INTEGER NOT NULL,
  section TEXT NOT NULL,
  -- Add other student-specific fields
);
```

#### Teachers Table
```sql
CREATE TABLE teachers (
  id UUID PRIMARY KEY REFERENCES profiles(id),
  employee_id TEXT UNIQUE NOT NULL,
  department TEXT DEFAULT 'CSE',
  designation TEXT,
  -- Add other teacher-specific fields
);
```

#### Additional Tables
You'll need tables for:
- `courses` - Course information
- `schedules` - Class schedules
- `attendance` - Attendance records
- `results` - Student results
- `notices` - Announcements
- `resources` - Study materials

### Environment Variables

The app uses a gitignored config file for sensitive data:
- `lib/config/supabase_config.dart` - Contains Supabase credentials

**Never commit this file to version control!**

---

## 📖 Usage

### First Time Setup

1. **Launch the App**: Open the app on your device
2. **Wait for Splash Screen**: The app will check for existing sessions
3. **Sign In**: If no session exists, you'll be redirected to the sign-in screen
4. **Enter Credentials**: Use your KUET CSE credentials
5. **Role Detection**: The app automatically detects if you're a student or teacher
6. **Navigate**: Explore features based on your role

### Student Workflow

1. **Dashboard**: View quick actions and recent updates
2. **Check Schedule**: Tap "Class Schedule" or "Exam Schedule"
3. **Track Attendance**: Monitor your attendance percentage
4. **View Results**: Check your marks and GPA
5. **Access Resources**: Download study materials
6. **Read Notices**: Stay updated with announcements

### Teacher Workflow

1. **View Courses**: See all assigned courses on home screen
2. **Mark Attendance**: Use FAB or navigate to Attendance section
3. **Enter Grades**: Access Grading section to input marks
4. **Post Announcements**: Create notices for students
5. **Manage Students**: View and manage enrolled students
6. **Share Materials**: Upload course materials

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
3. **Service Layer**: SupabaseService handles all backend communication
4. **Backend**: Supabase PostgreSQL database
5. **Storage**: SharedPreferences for local session data

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
- **Client-side Verification**: Password verification on client
- **Session Management**: Secure session tokens with SharedPreferences
- **Timeout**: Automatic session expiration

### Data Security
- **Role-based Access**: Students and Teachers have separate data access
- **Query Filtering**: All queries filtered by user role and permissions
- **SQL Injection Prevention**: Supabase parameterized queries
- **HTTPS**: All API calls over secure HTTPS

### Best Practices
- Supabase credentials in gitignored config file
- No hardcoded secrets in source code
- Row-level security policies in Supabase
- Input validation on all forms

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
- File upload feature for resources is work in progress
- Real-time notifications not yet implemented
- Offline mode is limited

---

## 🗺 Roadmap

### Phase 1 (Current)
- ✅ Basic authentication
- ✅ Student dashboard
- ✅ Teacher dashboard
- ✅ Attendance tracking
- ✅ Schedule viewing

### Phase 2 (In Progress)
- 🔄 Resource file uploads
- 🔄 Push notifications
- 🔄 Improved result analytics
- 🔄 Chat system for students/teachers

### Phase 3 (Planned)
- 📋 Assignment submission system
- 📋 Online examination module
- 📋 Discussion forum
- 📋 Parent portal
- 📋 Analytics dashboard

### Phase 4 (Future)
- 📋 Mobile-responsive web version
- 📋 Desktop application
- 📋 API for third-party integrations
- 📋 AI-powered recommendations

---

## 📄 License

This project is currently unlicensed. If you plan to use or contribute to this project, please contact the authors for licensing information.

---

## 👥 Authors

**Abdullah Md. Shahporan**
- GitHub: [@abdullahshahporan](https://github.com/abdullahshahporan)

**Asif Jawad**

### Contributors

We appreciate all contributors who have helped make this project better!

---

## 📞 Support

### Issues
If you encounter any issues, please:
1. Check the [Known Issues](#known-issues--limitations) section
2. Search existing [GitHub Issues](https://github.com/abdullahshahporan/KUET-CSE-Automation-Mobile--App/issues)
3. Create a new issue with:
   - Clear description
   - Steps to reproduce
   - Expected vs actual behavior
   - Screenshots if applicable
   - Device and Flutter version info

### Questions
For questions and discussions:
- Open a [GitHub Discussion](https://github.com/abdullahshahporan/KUET-CSE-Automation-Mobile--App/discussions)
- Contact the authors

---

## 🙏 Acknowledgments

- **KUET CSE Department** for inspiration and requirements
- **Flutter Team** for the amazing framework
- **Supabase** for the powerful backend platform
- **Open Source Community** for various packages and tools

---

## 📊 Project Stats

- **Lines of Code**: ~3,300+ (Dart)
- **Screens**: 30+
- **Features**: 40+
- **Supported Roles**: 2 (Student, Teacher)
- **Minimum Flutter Version**: 3.10.3
- **Target Platforms**: Android (Primary), iOS (Secondary)

---

<div align="center">

**Made with ❤️ for KUET CSE Department**

[⬆ Back to Top](#kuet-cse-automation-mobile-app)

</div>

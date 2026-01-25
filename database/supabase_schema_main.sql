-- Minimal Supabase schema for KUET CSE Automation
-- Contains only the core object definitions (extensions, enums, tables, and indexes)

-- Extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- Enums
CREATE TYPE user_role AS ENUM ('ADMIN', 'TEACHER', 'STUDENT', 'OFFICER_STAFF');
CREATE TYPE user_status AS ENUM ('ACTIVE', 'DISABLED');
CREATE TYPE course_type AS ENUM ('THEORY', 'LAB', 'PROJECT_THESIS');
CREATE TYPE attendance_status AS ENUM ('PRESENT', 'ABSENT', 'LATE', 'EXCUSED');
CREATE TYPE exam_type AS ENUM ('CLASS_TEST', 'TERM_FINAL', 'LAB_REPORT', 'LAB_QUIZ', 'ASSIGNMENT');
CREATE TYPE cr_role AS ENUM ('CR', 'ACR');

-- Users
CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  email VARCHAR UNIQUE NOT NULL,
  full_name VARCHAR,
  phone VARCHAR,
  role user_role,
  status user_status DEFAULT 'ACTIVE',
  created_at TIMESTAMP DEFAULT NOW(),
  CONSTRAINT users_email_lowercase CHECK (email = LOWER(email))
);
CREATE INDEX idx_users_email ON users (email);
CREATE INDEX idx_users_role ON users (role);

-- Students profile
CREATE TABLE students (
  roll_no VARCHAR PRIMARY KEY,
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  department_name VARCHAR DEFAULT 'CSE',
  batch VARCHAR,
  section VARCHAR,
  admission_year INTEGER
);
CREATE INDEX idx_students_user_id ON students(user_id);

-- Teachers
CREATE TABLE teachers (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  faculty_position VARCHAR,
  department VARCHAR DEFAULT 'CSE'
);
CREATE INDEX idx_teachers_user_id ON teachers(user_id);

-- Courses
CREATE TABLE courses (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  code VARCHAR UNIQUE NOT NULL,
  title VARCHAR NOT NULL,
  type course_type,
  credits NUMERIC(3,1)
);

-- Course offerings
CREATE TABLE course_offerings (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  course_id UUID REFERENCES courses(id) ON DELETE CASCADE,
  teacher_id UUID REFERENCES teachers(id),
  batch VARCHAR,
  section VARCHAR,
  is_active BOOLEAN DEFAULT TRUE
);
CREATE INDEX idx_offerings_course ON course_offerings(course_id);

-- Class sessions
CREATE TABLE class_sessions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  offering_id UUID REFERENCES course_offerings(id) ON DELETE CASCADE,
  session_date DATE NOT NULL,
  topic VARCHAR
);

-- Attendance records
CREATE TABLE attendance_records (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  session_id UUID REFERENCES class_sessions(id) ON DELETE CASCADE,
  student_roll VARCHAR REFERENCES students(roll_no) ON DELETE CASCADE,
  status attendance_status DEFAULT 'ABSENT'
);

-- Exams
CREATE TABLE exams (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  offering_id UUID REFERENCES course_offerings(id) ON DELETE CASCADE,
  exam_type exam_type,
  scheduled_at TIMESTAMP
);

-- Exam scores
CREATE TABLE exam_scores (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  exam_id UUID REFERENCES exams(id) ON DELETE CASCADE,
  student_roll VARCHAR REFERENCES students(roll_no) ON DELETE CASCADE,
  score NUMERIC(5,2)
);

-- Notices
CREATE TABLE notices (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  title VARCHAR NOT NULL,
  body TEXT,
  target_batch VARCHAR,
  created_at TIMESTAMP DEFAULT NOW()
);

-- Rooms
CREATE TABLE rooms (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name VARCHAR UNIQUE NOT NULL,
  capacity INTEGER,
  location VARCHAR
);

-- Room bookings
CREATE TABLE room_bookings (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  room_id UUID REFERENCES rooms(id) ON DELETE CASCADE,
  booked_by UUID REFERENCES users(id) ON DELETE SET NULL,
  start_time TIMESTAMP,
  end_time TIMESTAMP
);

-- WARNING: This schema is for context only and is not meant to be run.
-- Table order and constraints may not be valid for execution.

CREATE TABLE public.admins (
  user_id uuid NOT NULL,
  admin_uid text NOT NULL DEFAULT ('A-'::text || substr(replace((gen_random_uuid())::text, '-'::text, ''::text), 1, 10)) UNIQUE,
  full_name text NOT NULL,
  phone text,
  permissions jsonb DEFAULT '{"all": true}'::jsonb,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  updated_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT admins_pkey PRIMARY KEY (user_id),
  CONSTRAINT admins_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.profiles(user_id)
);
CREATE TABLE public.attendance_records (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  session_id uuid NOT NULL,
  enrollment_id uuid NOT NULL,
  status USER-DEFINED NOT NULL,
  marked_by_teacher_user_id uuid,
  remarks text,
  marked_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT attendance_records_pkey PRIMARY KEY (id),
  CONSTRAINT attendance_records_session_id_fkey FOREIGN KEY (session_id) REFERENCES public.class_sessions(id),
  CONSTRAINT attendance_records_enrollment_id_fkey FOREIGN KEY (enrollment_id) REFERENCES public.enrollments(id),
  CONSTRAINT attendance_records_marked_by_teacher_user_id_fkey FOREIGN KEY (marked_by_teacher_user_id) REFERENCES public.teachers(user_id)
);
CREATE TABLE public.class_sessions (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  offering_id uuid NOT NULL,
  room_number text,
  starts_at timestamp with time zone NOT NULL,
  ends_at timestamp with time zone NOT NULL,
  topic text,
  notes text,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT class_sessions_pkey PRIMARY KEY (id),
  CONSTRAINT class_sessions_offering_id_fkey FOREIGN KEY (offering_id) REFERENCES public.course_offerings(id),
  CONSTRAINT class_sessions_room_number_fkey FOREIGN KEY (room_number) REFERENCES public.rooms(room_number)
);
CREATE TABLE public.course_offerings (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  course_id uuid NOT NULL,
  teacher_user_id uuid NOT NULL,
  term text NOT NULL CHECK (term ~ '^[1-4]-[1-2]$'::text),
  session text NOT NULL,
  batch text,
  academic_year text,
  is_active boolean NOT NULL DEFAULT true,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT course_offerings_pkey PRIMARY KEY (id),
  CONSTRAINT course_offerings_course_id_fkey FOREIGN KEY (course_id) REFERENCES public.courses(id),
  CONSTRAINT course_offerings_teacher_user_id_fkey FOREIGN KEY (teacher_user_id) REFERENCES public.teachers(user_id)
);
CREATE TABLE public.courses (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  code text NOT NULL UNIQUE CHECK (code = upper(code)),
  title text NOT NULL,
  credit numeric NOT NULL CHECK (credit > 0::numeric),
  course_type text DEFAULT 'Theory'::text,
  description text,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT courses_pkey PRIMARY KEY (id)
);
CREATE TABLE public.curriculum (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  term text NOT NULL CHECK (term ~ '^[1-4]-[1-2]$'::text),
  course_id uuid NOT NULL,
  syllabus_year text DEFAULT '2024'::text,
  is_elective boolean DEFAULT false,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT curriculum_pkey PRIMARY KEY (id),
  CONSTRAINT curriculum_course_id_fkey FOREIGN KEY (course_id) REFERENCES public.courses(id)
);
CREATE TABLE public.enrollments (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  offering_id uuid NOT NULL,
  student_user_id uuid NOT NULL,
  enrollment_status text DEFAULT 'ENROLLED'::text,
  enrolled_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT enrollments_pkey PRIMARY KEY (id),
  CONSTRAINT enrollments_offering_id_fkey FOREIGN KEY (offering_id) REFERENCES public.course_offerings(id),
  CONSTRAINT enrollments_student_user_id_fkey FOREIGN KEY (student_user_id) REFERENCES public.students(user_id)
);
CREATE TABLE public.exam_scores (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  exam_id uuid NOT NULL,
  enrollment_id uuid NOT NULL,
  obtained_marks numeric NOT NULL CHECK (obtained_marks >= 0::numeric),
  remarks text,
  published_at timestamp with time zone,
  CONSTRAINT exam_scores_pkey PRIMARY KEY (id),
  CONSTRAINT exam_scores_exam_id_fkey FOREIGN KEY (exam_id) REFERENCES public.exams(id),
  CONSTRAINT exam_scores_enrollment_id_fkey FOREIGN KEY (enrollment_id) REFERENCES public.enrollments(id)
);
CREATE TABLE public.exams (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  offering_id uuid NOT NULL,
  name text NOT NULL,
  exam_type USER-DEFINED NOT NULL,
  max_marks numeric NOT NULL CHECK (max_marks > 0::numeric),
  exam_date date,
  exam_time time without time zone,
  duration_minutes integer,
  room_numbers ARRAY,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT exams_pkey PRIMARY KEY (id),
  CONSTRAINT exams_offering_id_fkey FOREIGN KEY (offering_id) REFERENCES public.course_offerings(id)
);
CREATE TABLE public.notices (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  title text NOT NULL,
  body text,
  author_user_id uuid,
  target_term text,
  target_session text,
  target_batch text,
  priority text DEFAULT 'NORMAL'::text,
  is_published boolean NOT NULL DEFAULT true,
  published_at timestamp with time zone,
  expires_at timestamp with time zone,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  updated_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT notices_pkey PRIMARY KEY (id),
  CONSTRAINT notices_author_user_id_fkey FOREIGN KEY (author_user_id) REFERENCES public.profiles(user_id)
);
CREATE TABLE public.profiles (
  user_id uuid NOT NULL DEFAULT gen_random_uuid(),
  role USER-DEFINED NOT NULL,
  email text NOT NULL UNIQUE CHECK (email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'::text),
  password_hash text NOT NULL,
  is_active boolean NOT NULL DEFAULT true,
  last_login timestamp with time zone,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  updated_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT profiles_pkey PRIMARY KEY (user_id)
);
CREATE TABLE public.rooms (
  room_number text NOT NULL,
  building_name text,
  capacity integer CHECK (capacity > 0),
  room_type text,
  facilities ARRAY,
  is_active boolean NOT NULL DEFAULT true,
  CONSTRAINT rooms_pkey PRIMARY KEY (room_number)
);
CREATE TABLE public.routine_slots (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  offering_id uuid NOT NULL,
  room_number text NOT NULL,
  day_of_week integer NOT NULL CHECK (day_of_week >= 0 AND day_of_week <= 6),
  start_time time without time zone NOT NULL,
  end_time time without time zone NOT NULL,
  rrule text,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  section text,
  CONSTRAINT routine_slots_pkey PRIMARY KEY (id),
  CONSTRAINT routine_slots_offering_id_fkey FOREIGN KEY (offering_id) REFERENCES public.course_offerings(id),
  CONSTRAINT routine_slots_room_number_fkey FOREIGN KEY (room_number) REFERENCES public.rooms(room_number)
);
CREATE TABLE public.room_booking_requests (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  teacher_user_id uuid NOT NULL,
  offering_id uuid NOT NULL,
  room_number text NOT NULL,
  day_of_week integer NOT NULL CHECK (day_of_week >= 0 AND day_of_week <= 6),
  start_period text NOT NULL,
  end_period text NOT NULL,
  start_time time without time zone NOT NULL,
  end_time time without time zone NOT NULL,
  section text,
  purpose text,
  status text NOT NULL DEFAULT 'pending'::text CHECK (status = ANY (ARRAY['pending'::text, 'approved'::text, 'rejected'::text])),
  admin_user_id uuid,
  admin_remarks text,
  requested_at timestamp with time zone DEFAULT now(),
  reviewed_at timestamp with time zone,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT room_booking_requests_pkey PRIMARY KEY (id),
  CONSTRAINT rbr_teacher_fkey FOREIGN KEY (teacher_user_id) REFERENCES public.teachers(user_id),
  CONSTRAINT rbr_offering_fkey FOREIGN KEY (offering_id) REFERENCES public.course_offerings(id),
  CONSTRAINT rbr_room_fkey FOREIGN KEY (room_number) REFERENCES public.rooms(room_number),
  CONSTRAINT rbr_admin_fkey FOREIGN KEY (admin_user_id) REFERENCES public.admins(user_id)
);
CREATE TABLE public.students (
  user_id uuid NOT NULL,
  roll_no text NOT NULL UNIQUE,
  full_name text NOT NULL,
  phone text NOT NULL,
  term text NOT NULL CHECK (term ~ '^[1-4]-[1-2]$'::text),
  session text NOT NULL,
  batch text,
  section text,
  cgpa numeric DEFAULT 0.00 CHECK (cgpa >= 0::numeric AND cgpa <= 4.00),
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  updated_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT students_pkey PRIMARY KEY (user_id),
  CONSTRAINT students_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.profiles(user_id)
);
CREATE TABLE public.teachers (
  user_id uuid NOT NULL,
  teacher_uid text NOT NULL DEFAULT ('T-'::text || substr(replace((gen_random_uuid())::text, '-'::text, ''::text), 1, 10)) UNIQUE,
  full_name text NOT NULL,
  phone text NOT NULL,
  designation USER-DEFINED NOT NULL DEFAULT 'LECTURER'::teacher_designation,
  department text DEFAULT 'CSE'::text,
  office_room text,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  updated_at timestamp with time zone NOT NULL DEFAULT now(),
  room_no smallint,
  date_of_join date,
  is_on_leave boolean NOT NULL DEFAULT false,
  leave_reason text,
  CONSTRAINT teachers_pkey PRIMARY KEY (user_id),
  CONSTRAINT teachers_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.profiles(user_id)
);
CREATE TABLE public.term_upgrade_requests (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  student_user_id uuid NOT NULL,
  current_term text NOT NULL CHECK (current_term ~ '^[1-4]-[1-2]$'::text),
  requested_term text NOT NULL CHECK (requested_term ~ '^[1-4]-[1-2]$'::text),
  status text NOT NULL DEFAULT 'pending'::text CHECK (status = ANY (ARRAY['pending'::text, 'approved'::text, 'rejected'::text])),
  reason text,
  admin_user_id uuid,
  admin_remarks text,
  requested_at timestamp with time zone DEFAULT now(),
  reviewed_at timestamp with time zone,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  CONSTRAINT term_upgrade_requests_pkey PRIMARY KEY (id),
  CONSTRAINT term_upgrade_requests_student_user_id_fkey FOREIGN KEY (student_user_id) REFERENCES public.students(user_id),
  CONSTRAINT term_upgrade_requests_admin_user_id_fkey FOREIGN KEY (admin_user_id) REFERENCES public.admins(user_id)
);
-- ============================================================
-- Migration: fix exam_type + disable RLS on notifications
-- (App uses custom bcrypt auth, NOT Supabase Auth, so auth.uid()
--  is always null — RLS WITH CHECK (auth.uid() = created_by) blocks
--  every INSERT. Solution: disable RLS on notifications so the
--  anon-key client can read and write freely.)
-- Run this in Supabase SQL Editor
-- ============================================================

-- 1. Convert exam_type from enum to text (allows CT, TERM_FINAL, QUIZ_VIVA)
ALTER TABLE public.exams ALTER COLUMN exam_type TYPE text;

-- 2. Drop the broken trigger that was causing all exam inserts to fail
DROP TRIGGER IF EXISTS trg_exam_notification ON public.exams;
DROP FUNCTION IF EXISTS public.create_exam_notification();

-- 3. Disable RLS on notifications (custom auth = no auth.uid() available)
ALTER TABLE public.notifications DISABLE ROW LEVEL SECURITY;

-- 4. Also disable RLS on notification_reads (same reason)
ALTER TABLE public.notification_reads DISABLE ROW LEVEL SECURITY;

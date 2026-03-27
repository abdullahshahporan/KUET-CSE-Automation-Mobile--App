-- Migration: convert exam_type from unknown enum to plain text
-- Run this once in your Supabase SQL Editor (Database → SQL Editor)
-- This removes the enum constraint and allows any string value.

ALTER TABLE public.exams ALTER COLUMN exam_type TYPE text;

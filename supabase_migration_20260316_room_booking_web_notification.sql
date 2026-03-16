-- Create notifications automatically when teacher room bookings become approved.
-- This works for inserts from any client (web, mobile, admin tools).

CREATE OR REPLACE FUNCTION public.create_room_booking_notification()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_course_code text;
  v_course_title text;
  v_term text;
  v_target_type text;
  v_target_value text;
  v_target_year_term text;
BEGIN
  IF NEW.status IS DISTINCT FROM 'approved' THEN
    RETURN NEW;
  END IF;

  -- Avoid duplicate notifications for the same booking request.
  IF EXISTS (
    SELECT 1
    FROM public.notifications n
    WHERE n.type = 'room_allocated'
      AND n.metadata->>'room_booking_request_id' = NEW.id::text
  ) THEN
    RETURN NEW;
  END IF;

  SELECT c.code, c.title, co.term
  INTO v_course_code, v_course_title, v_term
  FROM public.course_offerings co
  JOIN public.courses c ON c.id = co.course_id
  WHERE co.id = NEW.offering_id;

  IF v_course_code IS NULL THEN
    RETURN NEW;
  END IF;

  IF NEW.section IS NOT NULL AND btrim(NEW.section) <> '' THEN
    v_target_type := 'SECTION';
    v_target_value := btrim(NEW.section);
    v_target_year_term := v_term;
  ELSE
    v_target_type := 'COURSE';
    v_target_value := v_course_code;
    v_target_year_term := NULL;
  END IF;

  INSERT INTO public.notifications (
    type,
    title,
    body,
    target_type,
    target_value,
    target_year_term,
    created_by,
    created_by_role,
    metadata
  ) VALUES (
    'room_allocated',
    format('Room %s Booked — %s', NEW.room_number, v_course_code),
    format(
      '%s%s on %s, %s-%s.',
      coalesce(v_course_title, ''),
      CASE
        WHEN NEW.section IS NOT NULL AND btrim(NEW.section) <> ''
          THEN format(' (Section %s)', btrim(NEW.section))
        ELSE ''
      END,
      NEW.booking_date::text,
      to_char(NEW.start_time, 'HH24:MI'),
      to_char(NEW.end_time, 'HH24:MI')
    ),
    v_target_type,
    v_target_value,
    v_target_year_term,
    NEW.teacher_user_id,
    'TEACHER',
    jsonb_build_object(
      'room_booking_request_id', NEW.id,
      'offering_id', NEW.offering_id,
      'course_code', v_course_code,
      'room_number', NEW.room_number,
      'booking_date', NEW.booking_date,
      'start_time', to_char(NEW.start_time, 'HH24:MI'),
      'end_time', to_char(NEW.end_time, 'HH24:MI'),
      'section', NEW.section
    )
  );

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_room_booking_notification ON public.room_booking_requests;

CREATE TRIGGER trg_room_booking_notification
AFTER INSERT OR UPDATE OF status ON public.room_booking_requests
FOR EACH ROW
WHEN (NEW.status = 'approved')
EXECUTE FUNCTION public.create_room_booking_notification();

-- Database Migration: Notifications Upgrade for Multi-Role Support

-- 1. Make student_id column nullable in public.notifications
ALTER TABLE public.notifications ALTER COLUMN student_id DROP NOT NULL;

-- 2. Add user_id column referencing public.profiles(id)
ALTER TABLE public.notifications ADD COLUMN user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE;

-- 3. Populate existing notifications: set user_id = student_id
UPDATE public.notifications SET user_id = student_id WHERE user_id IS NULL;

-- 4. Create trigger to automatically sync user_id = student_id on insert if user_id is null (for backward compatibility)
CREATE OR REPLACE FUNCTION public.sync_notification_user_id()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.user_id IS NULL AND NEW.student_id IS NOT NULL THEN
        NEW.user_id := NEW.student_id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER trigger_sync_notification_user_id
BEFORE INSERT ON public.notifications
FOR EACH ROW
EXECUTE FUNCTION public.sync_notification_user_id();

-- 5. Stored Procedure (RPC) to send broadcast notifications to a targeted audience and log audit
CREATE OR REPLACE FUNCTION public.send_broadcast_notifications(
    p_audience TEXT,
    p_title TEXT,
    p_message TEXT,
    p_caller_id UUID
)
RETURNS JSONB AS $$
DECLARE
    v_profile_record RECORD;
    v_count INTEGER := 0;
    v_caller_name TEXT;
BEGIN
    -- Get caller name from profiles
    SELECT full_name INTO v_caller_name FROM public.profiles WHERE id = p_caller_id;
    IF v_caller_name IS NULL THEN
        v_caller_name := 'Super Admin';
    END IF;

    -- Loop through targeted profiles
    FOR v_profile_record IN
        SELECT id, role FROM public.profiles
        WHERE 
            (p_audience = 'all') OR
            (p_audience = 'students' AND role = 'student') OR
            (p_audience = 'merchants' AND role = 'petugas_kantin') OR
            (p_audience = 'staff' AND role = 'keuangan')
    LOOP
        -- Insert notification record
        INSERT INTO public.notifications (user_id, student_id, title, message, type)
        VALUES (
            v_profile_record.id,
            -- Only set student_id if they are a student to satisfy student foreign key constraint
            CASE WHEN v_profile_record.role = 'student' THEN v_profile_record.id ELSE NULL END,
            p_title,
            p_message,
            'system'
        );
        v_count := v_count + 1;
    END LOOP;

    -- Insert audit log for broadcast action
    INSERT INTO public.audit_logs (actor_name, action_type, description, new_value)
    VALUES (
        v_caller_name,
        'PENGIRIMAN_BROADCAST',
        'Mengirim broadcast "' || p_title || '" ke ' || v_count || ' pengguna (' || p_audience || ')',
        jsonb_build_object('audience', p_audience, 'title', p_title, 'message', p_message)
    );

    RETURN jsonb_build_object('success', true, 'sent_count', v_count);
EXCEPTION
    WHEN OTHERS THEN
        RETURN jsonb_build_object('success', false, 'error', SQLERRM);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

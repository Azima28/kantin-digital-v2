-- Database Migration: Fix send_broadcast_notifications audience filtering for staff (petugas_keuangan) role

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
            (p_audience = 'staff' AND (role = 'keuangan' OR role = 'petugas_keuangan'))
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

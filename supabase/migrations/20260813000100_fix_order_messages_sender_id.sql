-- Migration: Fix order_messages sender_id nullable and update RPC
-- Date: 2026-08-13

-- Make sender_id nullable in case user logs in via profile/fallback auth
ALTER TABLE public.order_messages ALTER COLUMN sender_id DROP NOT NULL;

-- Update RPC for marking messages read
CREATE OR REPLACE FUNCTION public.mark_order_messages_read(
    p_order_id UUID,
    p_user_id UUID DEFAULT NULL,
    p_sender_role TEXT DEFAULT NULL
)
RETURNS VOID AS $$
BEGIN
    UPDATE public.order_messages
    SET is_read = TRUE
    WHERE order_id = p_order_id
      AND is_read = FALSE
      AND (
        (p_user_id IS NOT NULL AND sender_id != p_user_id) OR
        (p_sender_role IS NOT NULL AND sender_role != p_sender_role) OR
        (p_user_id IS NULL AND p_sender_role IS NULL)
      );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

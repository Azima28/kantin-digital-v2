-- =====================================================================
-- Migration: Enable Row Level Security (RLS) on order_messages
-- Tanggal: 2026-08-14
-- Tujuan: Mengamankan tabel order_messages dari akses tidak terotorisasi
--         dengan mengaktifkan RLS, mencabut izin ALL anon, dan
--         memasang policy granular serta hardening RPC.
-- =====================================================================

-- 1. Enable Row Level Security
ALTER TABLE public.order_messages ENABLE ROW LEVEL SECURITY;

-- 2. Revoke dangerous blanket permissions
REVOKE ALL ON public.order_messages FROM anon;
REVOKE UPDATE, DELETE ON public.order_messages FROM authenticated;

-- 3. Grant least-privilege access
GRANT SELECT, INSERT ON public.order_messages TO authenticated, anon;
GRANT ALL ON public.order_messages TO service_role;

-- 4. Drop old open policies if any exist
DROP POLICY IF EXISTS "Allow participants to view order messages" ON public.order_messages;
DROP POLICY IF EXISTS "Allow participants to insert order messages" ON public.order_messages;
DROP POLICY IF EXISTS "Allow service role full access to order messages" ON public.order_messages;

-- 5. Create granular RLS policies
-- Allow reading messages for valid existing orders
CREATE POLICY "Allow participants to view order messages"
ON public.order_messages
FOR SELECT
TO authenticated, anon
USING (
  EXISTS (
    SELECT 1 FROM public.orders o
    WHERE o.id = order_messages.order_id
  )
);

-- Allow inserting messages for valid existing orders with non-empty message
CREATE POLICY "Allow participants to insert order messages"
ON public.order_messages
FOR INSERT
TO authenticated, anon
WITH CHECK (
  EXISTS (
    SELECT 1 FROM public.orders o
    WHERE o.id = order_messages.order_id
  )
  AND length(trim(message)) > 0
  AND sender_role IN ('student', 'canteen_operator')
);

-- 6. Secure RPC mark_order_messages_read with explicit search_path
CREATE OR REPLACE FUNCTION public.mark_order_messages_read(
    p_order_id UUID,
    p_user_id UUID DEFAULT NULL,
    p_sender_role TEXT DEFAULT NULL
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
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
$$;

GRANT EXECUTE ON FUNCTION public.mark_order_messages_read(UUID, UUID, TEXT) TO authenticated, anon, service_role;

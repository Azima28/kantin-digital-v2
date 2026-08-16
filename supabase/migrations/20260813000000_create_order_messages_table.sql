-- Migration: Create order_messages table for Student <-> Merchant Chat
-- Date: 2026-08-13

CREATE TABLE IF NOT EXISTS public.order_messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id UUID NOT NULL REFERENCES public.orders(id) ON DELETE CASCADE,
    sender_id UUID NULL REFERENCES public.profiles(id) ON DELETE SET NULL,
    sender_role TEXT NOT NULL CHECK (sender_role IN ('student', 'canteen_operator')),
    sender_name TEXT NOT NULL DEFAULT '',
    message TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    is_read BOOLEAN NOT NULL DEFAULT FALSE
);

-- Drop NOT NULL constraint if table already exists
ALTER TABLE public.order_messages ALTER COLUMN sender_id DROP NOT NULL;

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_order_messages_order_id ON public.order_messages(order_id);
CREATE INDEX IF NOT EXISTS idx_order_messages_created_at ON public.order_messages(created_at);

-- Enable Supabase Realtime for order_messages
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime'
    AND schemaname = 'public'
    AND tablename = 'order_messages'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.order_messages;
  END IF;
END $$;

-- Disable RLS or grant full access to authenticated/anon roles for development
ALTER TABLE public.order_messages DISABLE ROW LEVEL SECURITY;
GRANT ALL ON public.order_messages TO anon, authenticated, service_role;

-- Create RPC for marking messages read
CREATE OR REPLACE FUNCTION public.mark_order_messages_read(p_order_id UUID, p_user_id UUID DEFAULT NULL, p_sender_role TEXT DEFAULT NULL)
RETURNS VOID AS $$
BEGIN
    UPDATE public.order_messages
    SET is_read = TRUE
    WHERE order_id = p_order_id
      AND is_read = FALSE
      AND (p_sender_role IS NULL OR sender_role != p_sender_role);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

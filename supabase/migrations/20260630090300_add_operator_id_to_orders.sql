-- Add operator_id column to orders table for canteen filtering
ALTER TABLE public.orders ADD COLUMN operator_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE;

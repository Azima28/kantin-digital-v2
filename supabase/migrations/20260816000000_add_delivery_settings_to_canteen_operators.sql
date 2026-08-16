-- Migration: Add delivery settings to canteen_operators
-- Allows canteen operators to toggle delivery service and set custom delivery fees

ALTER TABLE public.canteen_operators
ADD COLUMN IF NOT EXISTS is_delivery_enabled BOOLEAN DEFAULT true NOT NULL,
ADD COLUMN IF NOT EXISTS delivery_fee BIGINT DEFAULT 2000 NOT NULL CHECK (delivery_fee >= 0);

-- Update RLS or permissions if needed
COMMENT ON COLUMN public.canteen_operators.is_delivery_enabled IS 'Indicates whether the canteen operator provides delivery service';
COMMENT ON COLUMN public.canteen_operators.delivery_fee IS 'Delivery surcharge fee in IDR set by the canteen operator';

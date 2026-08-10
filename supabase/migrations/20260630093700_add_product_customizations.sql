-- Add support for customizable toppings/options per product
ALTER TABLE public.products ADD COLUMN customizable_options JSONB DEFAULT '[]'::jsonb;

-- Add selected options column to order items to sync choices to canteen staff
ALTER TABLE public.order_items ADD COLUMN selected_options JSONB DEFAULT '[]'::jsonb;

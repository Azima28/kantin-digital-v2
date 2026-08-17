-- Migration: Add rating and total_reviews to products and canteen_operators
-- Generated: 2026-08-17

ALTER TABLE public.products
ADD COLUMN IF NOT EXISTS rating NUMERIC(3,2) DEFAULT 4.80,
ADD COLUMN IF NOT EXISTS total_reviews INTEGER DEFAULT 0;

ALTER TABLE public.canteen_operators
ADD COLUMN IF NOT EXISTS rating NUMERIC(3,2) DEFAULT 4.85,
ADD COLUMN IF NOT EXISTS total_reviews INTEGER DEFAULT 0;

-- Update existing products with realistic rating distribution
UPDATE public.products
SET rating = CASE
    WHEN LOWER(name) LIKE '%dimsum%' OR LOWER(name) LIKE '%ayam%' OR LOWER(name) LIKE '%bakso%' THEN 4.90
    WHEN LOWER(name) LIKE '%es%' OR LOWER(name) LIKE '%jus%' OR LOWER(name) LIKE '%teh%' THEN 4.85
    WHEN LOWER(name) LIKE '%goreng%' OR LOWER(name) LIKE '%nasi%' THEN 4.80
    ELSE 4.75
END,
total_reviews = CASE
    WHEN LOWER(name) LIKE '%dimsum%' OR LOWER(name) LIKE '%ayam%' THEN 150
    WHEN LOWER(name) LIKE '%es%' OR LOWER(name) LIKE '%jus%' THEN 120
    ELSE 85
END
WHERE rating IS NULL OR rating = 0;

-- Update existing canteens with realistic overall ratings
UPDATE public.canteen_operators
SET rating = 4.88, total_reviews = 280
WHERE rating IS NULL OR rating = 0;

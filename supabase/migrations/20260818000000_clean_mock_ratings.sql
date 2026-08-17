-- Migration: Clean mock/fake ratings and enforce real reviews calculation
-- Generated: 2026-08-18

-- 1. Reset all mock/hardcoded ratings
UPDATE public.products
SET rating = 0.0, total_reviews = 0;

UPDATE public.canteen_operators
SET rating = 0.0, total_reviews = 0;

-- 2. Recalculate real ratings from actual order_reviews table if any exists
UPDATE public.canteen_operators c
SET rating = COALESCE(sub.avg_r, 0.0),
    total_reviews = COALESCE(sub.cnt, 0)
FROM (
    SELECT operator_id, ROUND(AVG(rating)::numeric, 2) AS avg_r, COUNT(*) AS cnt
    FROM public.order_reviews
    GROUP BY operator_id
) sub
WHERE c.id = sub.operator_id;

UPDATE public.products p
SET rating = COALESCE(sub.avg_r, 0.0),
    total_reviews = COALESCE(sub.cnt, 0)
FROM (
    SELECT operator_id, ROUND(AVG(rating)::numeric, 2) AS avg_r, COUNT(*) AS cnt
    FROM public.order_reviews
    GROUP BY operator_id
) sub
WHERE p.operator_id = sub.operator_id;

-- 3. Update procedural trigger function without any 4.80/4.88 fallbacks
CREATE OR REPLACE FUNCTION public.recalculate_ratings_on_review()
RETURNS TRIGGER AS $$
DECLARE
    v_operator_id UUID;
    v_avg_rating NUMERIC(3,2);
    v_total_reviews INTEGER;
BEGIN
    v_operator_id := NEW.operator_id;
    IF v_operator_id IS NULL THEN
        SELECT operator_id INTO v_operator_id FROM public.orders WHERE id = NEW.order_id;
    END IF;

    IF v_operator_id IS NOT NULL THEN
        SELECT ROUND(AVG(rating)::numeric, 2), COUNT(*)
        INTO v_avg_rating, v_total_reviews
        FROM public.order_reviews
        WHERE operator_id = v_operator_id;

        UPDATE public.canteen_operators
        SET rating = COALESCE(v_avg_rating, 0.0),
            total_reviews = COALESCE(v_total_reviews, 0)
        WHERE id = v_operator_id;

        UPDATE public.products
        SET rating = COALESCE(v_avg_rating, 0.0),
            total_reviews = COALESCE(v_total_reviews, 0)
        WHERE operator_id = v_operator_id;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

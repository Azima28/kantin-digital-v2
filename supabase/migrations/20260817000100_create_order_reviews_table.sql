-- Migration: Create order_reviews table and rating calculation triggers
-- Generated: 2026-08-17

CREATE TABLE IF NOT EXISTS public.order_reviews (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id UUID NOT NULL REFERENCES public.orders(id) ON DELETE CASCADE,
    student_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    operator_id UUID REFERENCES public.canteen_operators(id) ON DELETE CASCADE,
    rating INTEGER NOT NULL CHECK (rating >= 1 AND rating <= 5),
    review_text TEXT DEFAULT '',
    tags TEXT[] DEFAULT '{}',
    is_anonymous BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    CONSTRAINT uq_order_reviews_order_id UNIQUE (order_id)
);

CREATE INDEX IF NOT EXISTS idx_order_reviews_order_id ON public.order_reviews(order_id);
CREATE INDEX IF NOT EXISTS idx_order_reviews_operator_id ON public.order_reviews(operator_id);
CREATE INDEX IF NOT EXISTS idx_order_reviews_student_id ON public.order_reviews(student_id);

-- Function to recalculate ratings for products and canteens when a review is added
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
        -- Recalculate canteen operator rating
        SELECT ROUND(AVG(rating)::numeric, 2), COUNT(*)
        INTO v_avg_rating, v_total_reviews
        FROM public.order_reviews
        WHERE operator_id = v_operator_id;

        UPDATE public.canteen_operators
        SET rating = COALESCE(v_avg_rating, 4.88),
            total_reviews = COALESCE(v_total_reviews, 0)
        WHERE id = v_operator_id;

        -- Update products belonging to this operator
        UPDATE public.products
        SET rating = COALESCE(v_avg_rating, 4.80),
            total_reviews = COALESCE(v_total_reviews, 0)
        WHERE operator_id = v_operator_id;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trg_recalculate_ratings ON public.order_reviews;
CREATE TRIGGER trg_recalculate_ratings
AFTER INSERT OR UPDATE ON public.order_reviews
FOR EACH ROW
EXECUTE FUNCTION public.recalculate_ratings_on_review();

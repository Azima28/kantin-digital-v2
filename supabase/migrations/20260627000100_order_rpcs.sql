-- ============================================================================
-- Migration: RPCs untuk Order System
-- 20260627000100_order_rpcs.sql
-- ============================================================================

-- ============================================================
-- RPC: place_order
-- Atomic: potong saldo siswa + insert orders + order_items
-- Input: p_student_id, p_orders (array JSON)
-- ============================================================
CREATE OR REPLACE FUNCTION public.place_order(
  p_student_id UUID,
  p_orders     JSONB   -- array of order objects
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_student_balance INTEGER;
  v_total_all       INTEGER := 0;
  v_order           JSONB;
  v_item            JSONB;
  v_order_id        UUID;
  v_tx_id           UUID;
  v_result          JSONB := '[]'::JSONB;
  v_operator_id     UUID;
  v_delivery_type   TEXT;
  v_delivery_loc    TEXT;
  v_delivery_fee    INTEGER;
  v_student_phone   TEXT;
  v_subtotal        INTEGER;
  v_total_amount    INTEGER;
  v_note            TEXT;
BEGIN
  -- 1. Validasi: hitung total semua order
  FOR v_order IN SELECT * FROM jsonb_array_elements(p_orders)
  LOOP
    v_total_all := v_total_all + (v_order->>'total_amount')::INTEGER;
  END LOOP;

  -- 2. Cek saldo siswa
  SELECT balance INTO v_student_balance
  FROM public.students
  WHERE id = p_student_id
  FOR UPDATE;  -- lock row

  IF v_student_balance IS NULL THEN
    RAISE EXCEPTION 'student_not_found';
  END IF;

  IF v_student_balance < v_total_all THEN
    RAISE EXCEPTION 'insufficient_balance:%:%', v_student_balance, v_total_all;
  END IF;

  -- 3. Potong saldo siswa (1x untuk semua order)
  UPDATE public.students
  SET balance = balance - v_total_all
  WHERE id = p_student_id;

  -- 4. Insert transaksi gabungan (type=purchase, status=success)
  INSERT INTO public.transactions (student_id, operator_id, total_amount, type, status, purchase_method)
  VALUES (
    p_student_id,
    (p_orders->0->>'operator_id')::UUID,  -- operator pertama (referensi)
    v_total_all,
    'purchase',
    'success',
    'app'
  )
  RETURNING id INTO v_tx_id;

  -- 5. Insert tiap order + item
  FOR v_order IN SELECT * FROM jsonb_array_elements(p_orders)
  LOOP
    v_operator_id   := (v_order->>'operator_id')::UUID;
    v_delivery_type := COALESCE(v_order->>'delivery_type', 'takeaway');
    v_delivery_loc  := v_order->>'delivery_location';
    v_delivery_fee  := COALESCE((v_order->>'delivery_fee')::INTEGER, 0);
    v_student_phone := v_order->>'student_phone';
    v_subtotal      := (v_order->>'subtotal')::INTEGER;
    v_total_amount  := (v_order->>'total_amount')::INTEGER;
    v_note          := v_order->>'note';

    -- Validasi: delivery harus ada lokasi & nomor telepon
    IF v_delivery_type = 'delivery' THEN
      IF v_delivery_loc IS NULL OR v_delivery_loc = '' THEN
        RAISE EXCEPTION 'delivery_location_required';
      END IF;
      IF v_student_phone IS NULL OR v_student_phone = '' THEN
        RAISE EXCEPTION 'phone_required_for_delivery';
      END IF;
    END IF;

    INSERT INTO public.orders (
      student_id, operator_id, transaction_id, status,
      delivery_type, delivery_location, delivery_fee,
      student_phone, subtotal, total_amount, note
    ) VALUES (
      p_student_id, v_operator_id, v_tx_id, 'pending',
      v_delivery_type, v_delivery_loc, v_delivery_fee,
      v_student_phone, v_subtotal, v_total_amount, v_note
    )
    RETURNING id INTO v_order_id;

    -- Insert order items
    FOR v_item IN SELECT * FROM jsonb_array_elements(v_order->'items')
    LOOP
      INSERT INTO public.order_items (order_id, product_id, quantity, unit_price, note)
      VALUES (
        v_order_id,
        (v_item->>'product_id')::UUID,
        (v_item->>'quantity')::INTEGER,
        (v_item->>'unit_price')::INTEGER,
        v_item->>'note'
      );
    END LOOP;

    v_result := v_result || jsonb_build_array(jsonb_build_object(
      'order_id', v_order_id,
      'operator_id', v_operator_id
    ));
  END LOOP;

  RETURN jsonb_build_object(
    'success', true,
    'orders', v_result,
    'transaction_id', v_tx_id,
    'total_deducted', v_total_all
  );
END;
$$;

-- ============================================================
-- RPC: cancel_order
-- Atomic: set cancelled + refund saldo siswa
-- Hanya bisa jika status = 'pending'
-- ============================================================
CREATE OR REPLACE FUNCTION public.cancel_order(
  p_order_id   UUID,
  p_student_id UUID
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_order        RECORD;
  v_refund_amount INTEGER;
BEGIN
  -- Lock & ambil data order
  SELECT id, student_id, status, total_amount
  INTO v_order
  FROM public.orders
  WHERE id = p_order_id
  FOR UPDATE;

  IF v_order.id IS NULL THEN
    RAISE EXCEPTION 'order_not_found';
  END IF;

  IF v_order.student_id != p_student_id THEN
    RAISE EXCEPTION 'forbidden';
  END IF;

  IF v_order.status != 'pending' THEN
    RAISE EXCEPTION 'cannot_cancel_status:%', v_order.status;
  END IF;

  v_refund_amount := v_order.total_amount;

  -- Set status cancelled
  UPDATE public.orders
  SET status = 'cancelled', updated_at = now()
  WHERE id = p_order_id;

  -- Refund saldo siswa
  UPDATE public.students
  SET balance = balance + v_refund_amount
  WHERE id = p_student_id;

  RETURN jsonb_build_object(
    'success', true,
    'refunded', v_refund_amount
  );
END;
$$;

-- ============================================================
-- RPC: complete_order
-- Atomic: set completed + credit balance_earned operator
-- Hanya bisa jika status = 'ready'
-- ============================================================
CREATE OR REPLACE FUNCTION public.complete_order(
  p_order_id    UUID,
  p_operator_id UUID
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_order RECORD;
BEGIN
  SELECT id, operator_id, status, subtotal, total_amount, delivery_fee
  INTO v_order
  FROM public.orders
  WHERE id = p_order_id
  FOR UPDATE;

  IF v_order.id IS NULL THEN
    RAISE EXCEPTION 'order_not_found';
  END IF;

  IF v_order.operator_id != p_operator_id THEN
    RAISE EXCEPTION 'forbidden';
  END IF;

  IF v_order.status != 'ready' THEN
    RAISE EXCEPTION 'cannot_complete_status:%', v_order.status;
  END IF;

  -- Set status completed
  UPDATE public.orders
  SET status = 'completed', updated_at = now()
  WHERE id = p_order_id;

  -- Credit saldo kantin (subtotal + delivery_fee seluruhnya ke kantin)
  UPDATE public.canteen_operators
  SET balance_earned = balance_earned + v_order.total_amount
  WHERE id = p_operator_id;

  RETURN jsonb_build_object(
    'success', true,
    'credited', v_order.total_amount
  );
END;
$$;

-- ============================================================
-- RPC: update_order_status
-- Digunakan petugas untuk: pending→accepted, accepted→preparing,
-- preparing→ready
-- ============================================================
CREATE OR REPLACE FUNCTION public.update_order_status(
  p_order_id    UUID,
  p_operator_id UUID,
  p_new_status  TEXT
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_order       RECORD;
  v_allowed_next TEXT[];
BEGIN
  SELECT id, operator_id, status INTO v_order
  FROM public.orders WHERE id = p_order_id FOR UPDATE;

  IF v_order.id IS NULL THEN RAISE EXCEPTION 'order_not_found'; END IF;
  IF v_order.operator_id != p_operator_id THEN RAISE EXCEPTION 'forbidden'; END IF;

  -- Validasi transisi status yang sah
  v_allowed_next := CASE v_order.status
    WHEN 'pending'   THEN ARRAY['accepted', 'cancelled']
    WHEN 'accepted'  THEN ARRAY['preparing']
    WHEN 'preparing' THEN ARRAY['ready']
    ELSE ARRAY[]::TEXT[]
  END;

  IF NOT (p_new_status = ANY(v_allowed_next)) THEN
    RAISE EXCEPTION 'invalid_transition:%->%', v_order.status, p_new_status;
  END IF;

  UPDATE public.orders
  SET status = p_new_status, updated_at = now()
  WHERE id = p_order_id;

  RETURN jsonb_build_object('success', true, 'status', p_new_status);
END;
$$;

-- ============================================================
-- RPC: get_canteens_with_delivery
-- Ambil semua kantin aktif + info delivery untuk siswa
-- ============================================================
CREATE OR REPLACE FUNCTION public.get_canteens_with_delivery()
RETURNS TABLE (
  id               UUID,
  canteen_name     TEXT,
  full_name        TEXT,
  avatar_url       TEXT,
  delivery_enabled BOOLEAN,
  delivery_fee     INTEGER,
  product_count    BIGINT
)
LANGUAGE sql
SECURITY DEFINER
AS $$
  SELECT
    co.id,
    co.canteen_name,
    p.full_name,
    p.avatar_url,
    co.delivery_enabled,
    co.delivery_fee,
    COUNT(pr.id) FILTER (WHERE pr.is_available = true) AS product_count
  FROM public.canteen_operators co
  JOIN public.profiles p ON p.id = co.id
  LEFT JOIN public.products pr ON pr.operator_id = co.id
  GROUP BY co.id, co.canteen_name, p.full_name, p.avatar_url,
           co.delivery_enabled, co.delivery_fee
  ORDER BY co.canteen_name;
$$;

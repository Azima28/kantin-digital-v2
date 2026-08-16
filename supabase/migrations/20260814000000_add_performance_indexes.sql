-- =====================================================================
-- PERFORMANCE B-TREE INDEXES FOR KANTIN DIGITAL V2.0
-- High-speed query optimization for Transactions, Orders, Chat, and Users
-- =====================================================================

-- 1. Transactions Table Indexes
CREATE INDEX IF NOT EXISTS idx_transactions_student_id ON public.transactions(student_id);
CREATE INDEX IF NOT EXISTS idx_transactions_operator_id ON public.transactions(operator_id);
CREATE INDEX IF NOT EXISTS idx_transactions_created_at ON public.transactions(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_transactions_status_type ON public.transactions(status, type);

-- 2. Orders Table Indexes
CREATE INDEX IF NOT EXISTS idx_orders_student_id ON public.orders(student_id);
CREATE INDEX IF NOT EXISTS idx_orders_operator_id ON public.orders(operator_id);
CREATE INDEX IF NOT EXISTS idx_orders_status ON public.orders(status);
CREATE INDEX IF NOT EXISTS idx_orders_created_at ON public.orders(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_orders_student_status ON public.orders(student_id, status);
CREATE INDEX IF NOT EXISTS idx_orders_operator_status ON public.orders(operator_id, status);

-- 3. Order Items & Order Messages Indexes
CREATE INDEX IF NOT EXISTS idx_order_items_order_id ON public.order_items(order_id);
CREATE INDEX IF NOT EXISTS idx_order_messages_order_id ON public.order_messages(order_id);
CREATE INDEX IF NOT EXISTS idx_order_messages_sender ON public.order_messages(sender_id, sender_role);

-- 4. Transaction Items Indexes
CREATE INDEX IF NOT EXISTS idx_transaction_items_transaction_id ON public.transaction_items(transaction_id);

-- 5. Notifications Indexes
CREATE INDEX IF NOT EXISTS idx_notifications_user_unread ON public.notifications(user_id, is_read);
CREATE INDEX IF NOT EXISTS idx_notifications_student_unread ON public.notifications(student_id, is_read);

-- 6. Products Catalog Indexes
CREATE INDEX IF NOT EXISTS idx_products_operator_available ON public.products(operator_id, is_available);
CREATE INDEX IF NOT EXISTS idx_products_category ON public.products(category);

-- 7. User Profiles & Students Lookup Indexes
CREATE INDEX IF NOT EXISTS idx_profiles_role ON public.profiles(role);
CREATE INDEX IF NOT EXISTS idx_profiles_nisn ON public.profiles(nisn);
CREATE INDEX IF NOT EXISTS idx_profiles_username ON public.profiles(username);
CREATE INDEX IF NOT EXISTS idx_students_rfid ON public.students(rfid_uid);

-- 8. Audit Logs Index
CREATE INDEX IF NOT EXISTS idx_audit_logs_created_at ON public.audit_logs(created_at DESC);

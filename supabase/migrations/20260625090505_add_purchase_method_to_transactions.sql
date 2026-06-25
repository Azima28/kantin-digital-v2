ALTER TABLE public.transactions ADD COLUMN purchase_method TEXT CHECK (purchase_method IN ('rfid', 'app')) DEFAULT 'rfid';

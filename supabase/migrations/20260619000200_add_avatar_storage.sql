-- =====================================================================
-- Migration: Setup Supabase Storage untuk Avatar Profil
-- Tanggal: 2026-06-19
-- Tujuan: Membuat bucket 'avatars' dan RLS policies agar pengguna
--         bisa upload & mengganti foto profil mereka sendiri.
-- =====================================================================

-- Buat bucket 'avatars' (publik agar URL bisa diakses tanpa auth)
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
    'avatars',
    'avatars',
    true,           -- publik: URL dapat diakses langsung
    2097152,        -- maks 2MB per file
    ARRAY['image/jpeg', 'image/png', 'image/webp', 'image/gif']
)
ON CONFLICT (id) DO NOTHING;

-- ─── RLS Policies untuk Storage ───

-- Policy: Siapa saja bisa MEMBACA avatar (bucket publik)
CREATE POLICY "Avatar images are publicly accessible"
    ON storage.objects FOR SELECT
    USING (bucket_id = 'avatars');

-- Policy: User hanya bisa UPLOAD ke folder miliknya sendiri (user_id/avatar.jpg)
CREATE POLICY "Users can upload their own avatar"
    ON storage.objects FOR INSERT
    TO authenticated
    WITH CHECK (
        bucket_id = 'avatars'
        AND (storage.foldername(name))[1] = auth.uid()::TEXT
    );

-- Policy: User bisa UPDATE (overwrite) avatar miliknya
CREATE POLICY "Users can update their own avatar"
    ON storage.objects FOR UPDATE
    TO authenticated
    USING (
        bucket_id = 'avatars'
        AND (storage.foldername(name))[1] = auth.uid()::TEXT
    );

-- Policy: User bisa DELETE avatar miliknya
CREATE POLICY "Users can delete their own avatar"
    ON storage.objects FOR DELETE
    TO authenticated
    USING (
        bucket_id = 'avatars'
        AND (storage.foldername(name))[1] = auth.uid()::TEXT
    );

-- ─── Tambah kolom avatar_url ke profiles ───
ALTER TABLE public.profiles
    ADD COLUMN IF NOT EXISTS avatar_url TEXT;

COMMENT ON COLUMN public.profiles.avatar_url IS
    'URL foto profil pengguna dari Supabase Storage bucket avatars.';

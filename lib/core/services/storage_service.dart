import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Service untuk upload, update, dan delete foto profil pengguna
/// menggunakan Supabase Storage bucket 'avatars'.
class StorageService {
  final SupabaseClient _client;
  static const String _bucket = 'avatars';

  StorageService(this._client);

  /// Pilih gambar dari kamera atau galeri.
  /// Returns [XFile?] atau null jika user membatalkan.
  Future<XFile?> pickImage({ImageSource source = ImageSource.gallery}) async {
    final picker = ImagePicker();
    try {
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );
      return image;
    } catch (e) {
      debugPrint('StorageService.pickImage error: $e');
      return null;
    }
  }

  /// Upload foto profil ke Supabase Storage.
  /// Path: `avatars/{userId}/avatar.jpg`
  ///
  /// Returns [String] public URL foto jika berhasil, throws Exception jika gagal.
  Future<String> uploadAvatar({
    required String userId,
    required XFile imageFile,
  }) async {
    try {
      final String filePath = '$userId/avatar.jpg';
      final Uint8List bytes = await imageFile.readAsBytes();

      // Upsert: overwrite jika sudah ada
      await _client.storage.from(_bucket).uploadBinary(
        filePath,
        bytes,
        fileOptions: const FileOptions(
          contentType: 'image/jpeg',
          upsert: true,
        ),
      );

      // Ambil URL publik
      final String publicUrl =
          _client.storage.from(_bucket).getPublicUrl(filePath);

      // Tambahkan cache-bust query agar URL selalu fresh
      final String freshUrl =
          '$publicUrl?t=${DateTime.now().millisecondsSinceEpoch}';

      // Update kolom avatar_url di tabel profiles
      await _client
          .from('profiles')
          .update({'avatar_url': freshUrl})
          .eq('id', userId);

      return freshUrl;
    } on StorageException catch (e) {
      throw Exception('Gagal upload foto: ${e.message}');
    } catch (e) {
      throw Exception('Terjadi kesalahan saat upload foto: $e');
    }
  }

  /// Hapus foto profil dari Storage dan reset avatar_url ke null.
  Future<void> deleteAvatar({required String userId}) async {
    try {
      final String filePath = '$userId/avatar.jpg';
      await _client.storage.from(_bucket).remove([filePath]);
      await _client
          .from('profiles')
          .update({'avatar_url': null})
          .eq('id', userId);
    } catch (e) {
      debugPrint('StorageService.deleteAvatar error: $e');
    }
  }

  /// Ambil URL avatar terkini dari database.
  Future<String?> getAvatarUrl({required String userId}) async {
    try {
      final data = await _client
          .from('profiles')
          .select('avatar_url')
          .eq('id', userId)
          .maybeSingle();
      return data?['avatar_url'] as String?;
    } catch (e) {
      return null;
    }
  }
}

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kantin_digital/core/services/api_client.dart';
import 'package:kantin_digital/core/services/web_camera.dart';
import 'package:kantin_digital/core/constants/app_strings.dart';

/// Service untuk upload dan kelola foto profil/produk menggunakan Go Backend REST API.
class StorageService {
  final ApiClient _apiClient;

  StorageService([ApiClient? apiClient]) : _apiClient = apiClient ?? ApiClient();

  /// Pilih gambar dari kamera atau galeri.
  /// On Web + Camera: Membuka Live Webcam capture modal.
  /// On Mobile + Camera/Gallery: Membuka native OS camera / gallery picker.
  Future<XFile?> pickImage({
    BuildContext? context,
    ImageSource source = ImageSource.gallery,
  }) async {
    if (kIsWeb && source == ImageSource.camera && context != null) {
      try {
        final webImage = await showWebCameraDialog(context);
        if (webImage != null) return webImage;
      } catch (e) {
        debugPrint('[StorageService] Web camera dialog fallback: $e');
      }
    }

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
      debugPrint('[StorageService] pickImage error ($source): $e');
      return null;
    }
  }

  /// Upload foto profil ke Go Backend Storage.
  Future<String> uploadAvatar({
    required String userId,
    required XFile imageFile,
  }) async {
    try {
      final Uint8List bytes = await imageFile.readAsBytes();
      final filename = imageFile.name.isNotEmpty ? imageFile.name : 'avatar.jpg';
      final response = await _apiClient.uploadImage('/upload/avatar', bytes, filename);

      if (!response.success) {
        throw Exception(response.message ?? 'Gagal mengunggah foto profil');
      }

      final url = response.data?['url']?.toString() ?? '';
      return ApiClient.resolveImageUrl(url);
    } catch (e) {
      throw Exception('${AppStrings.labelFailed} upload foto: $e');
    }
  }

  /// Hapus foto profil (opsional).
  Future<void> deleteAvatar({required String userId}) async {
    // Handled by backend user profile update
  }

  /// Ambil URL avatar terkini.
  Future<String?> getAvatarUrl({required String userId}) async {
    return null;
  }
}

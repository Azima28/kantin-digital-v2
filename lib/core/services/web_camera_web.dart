// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;
import 'dart:typed_data';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kantin_digital/core/theme/nebula_colors.dart';
import 'package:kantin_digital/core/extensions/theme_extensions.dart';

/// Shows an interactive Web Camera Live Preview Dialog on Desktop & Web browsers
Future<XFile?> showWebCameraDialog(BuildContext context) async {
  return showDialog<XFile?>(
    context: context,
    builder: (ctx) => const _WebCameraModal(),
  );
}

class _WebCameraModal extends StatefulWidget {
  const _WebCameraModal();

  @override
  State<_WebCameraModal> createState() => _WebCameraModalState();
}

class _WebCameraModalState extends State<_WebCameraModal> {
  html.VideoElement? _videoElement;
  html.MediaStream? _mediaStream;
  String? _viewType;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _startCamera();
  }

  Future<void> _startCamera() async {
    try {
      final constraints = {
        'video': {
          'facingMode': 'user',
          'width': {'ideal': 640},
          'height': {'ideal': 480},
        },
        'audio': false,
      };

      _mediaStream = await html.window.navigator.mediaDevices?.getUserMedia(constraints);
      if (_mediaStream == null) {
        throw Exception('Kamera tidak ditemukan atau izin belum diberikan.');
      }

      _viewType = 'webcam-view-${DateTime.now().millisecondsSinceEpoch}';
      _videoElement = html.VideoElement()
        ..srcObject = _mediaStream
        ..autoplay = true
        ..muted = true
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.objectFit = 'cover'
        ..style.transform = 'scaleX(-1)'; // Mirror for selfie camera

      ui_web.platformViewRegistry.registerViewFactory(
        _viewType!,
        (int viewId) => _videoElement!,
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Tidak dapat mengakses kamera: $e\n\nPastikan Anda telah mengizinkan akses kamera pada browser (ikon gembok di sebelah URL).';
        });
      }
    }
  }

  void _capturePhoto() {
    if (_videoElement == null || _videoElement!.videoWidth == 0) return;

    final canvas = html.CanvasElement(
      width: _videoElement!.videoWidth,
      height: _videoElement!.videoHeight,
    );
    final ctx = canvas.context2D;

    // Draw mirrored image
    ctx.translate(canvas.width!, 0);
    ctx.scale(-1, 1);
    ctx.drawImage(_videoElement!, 0, 0);

    final dataUrl = canvas.toDataUrl('image/jpeg', 0.9);
    final base64String = dataUrl.split(',').last;
    final bytes = html.window.atob(base64String);
    final uint8List = Uint8List.fromList(bytes.codeUnits);

    final xfile = XFile.fromData(
      uint8List,
      mimeType: 'image/jpeg',
      name: 'camera_capture_${DateTime.now().millisecondsSinceEpoch}.jpg',
    );

    _stopCamera();
    Navigator.of(context).pop(xfile);
  }

  void _stopCamera() {
    _mediaStream?.getTracks().forEach((track) => track.stop());
    _videoElement?.pause();
    _videoElement?.srcObject = null;
  }

  @override
  void dispose() {
    _stopCamera();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 480),
        decoration: BoxDecoration(
          color: context.cardBg,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: context.dividerCol, width: 0.8),
          boxShadow: [
            BoxShadow(
              color: context.shadowColor,
              blurRadius: 28,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Nebula.teal.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(CupertinoIcons.camera_fill, color: Nebula.teal, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Ambil Foto Kamera',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: context.textPrimary,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(CupertinoIcons.multiply_circle_fill, size: 22),
                  color: context.textSecondary,
                ),
              ],
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Container(
                height: 320,
                width: double.infinity,
                color: Colors.black,
                child: _isLoading
                    ? const Center(child: CupertinoActivityIndicator(color: Colors.white, radius: 14))
                    : _errorMessage != null
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Text(
                                _errorMessage!,
                                textAlign: TextAlign.center,
                                style: GoogleFonts.inter(color: Colors.white, fontSize: 12),
                              ),
                            ),
                          )
                        : HtmlElementView(viewType: _viewType!),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(color: context.dividerCol),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text(
                      'Batal',
                      style: GoogleFonts.inter(color: context.textSecondary, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: (_isLoading || _errorMessage != null) ? null : _capturePhoto,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Nebula.teal,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    icon: const Icon(CupertinoIcons.camera, size: 18, color: Colors.white),
                    label: Text(
                      'Ambil Foto',
                      style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13.5),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

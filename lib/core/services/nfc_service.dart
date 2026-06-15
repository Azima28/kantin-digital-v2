import 'package:flutter/foundation.dart';
import 'package:nfc_manager/nfc_manager.dart';

class NfcService {
  NfcService._();

  // Check if NFC is available on this device
  static Future<bool> isNfcAvailable() async {
    try {
      return await NfcManager.instance.isAvailable();
    } catch (e) {
      debugPrint('NfcService - isNfcAvailable Error: $e');
      return false;
    }
  }

  // Start checking/scanning for NFC tags
  static void startScanning({
    required Function(String uid) onTagDiscovered,
    required Function(String error) onError,
  }) {
    NfcManager.instance.startSession(
      onDiscovered: (NfcTag tag) async {
        try {
          final String? uid = _extractUid(tag);
          if (uid != null) {
            onTagDiscovered(uid);
          } else {
            onError('Gagal membaca UID kartu. Pastikan tipe kartu didukung.');
          }
        } catch (e) {
          onError('Error memproses tag NFC: $e');
        }
      },
      onError: (NfcError error) async {
        onError('NFC Error: ${error.message}');
      },
    );
  }

  // Stop scanning
  static Future<void> stopScanning() async {
    try {
      await NfcManager.instance.stopSession();
    } catch (e) {
      debugPrint('NfcService - stopScanning Error: $e');
    }
  }

  // Helper method to extract UID as standard hex string (e.g. 04:2A:B5:E2)
  static String? _extractUid(NfcTag tag) {
    List<int>? identifier;

    // Direct scan through tag data map
    final tagData = tag.data;
    for (var key in ['nfca', 'mifare', 'isodep', 'nfcb', 'nfcf', 'nfcv', 'mifareultralight', 'mifareclassic']) {
      if (tagData.containsKey(key) && tagData[key] is Map && tagData[key].containsKey('identifier')) {
        try {
          identifier = List<int>.from(tagData[key]['identifier']);
          break;
        } catch (_) {}
      }
    }

    if (identifier == null) return null;

    // Formats tag identifier as a standard hex representation, e.g. "04:A2:3B:CD"
    return identifier.map((e) => e.toRadixString(16).padLeft(2, '0').toUpperCase()).join(':');
  }
}

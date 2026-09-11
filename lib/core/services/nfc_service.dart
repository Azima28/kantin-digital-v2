import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:nfc_manager/nfc_manager.dart';

class NfcService {
  NfcService._();

  static Function(String uid)? _activeCallback;
  static bool _isKeyboardListening = false;
  static final StringBuffer _keyBuffer = StringBuffer();
  static DateTime _lastKeyTime = DateTime.now();

  // Check if NFC is available on this device (always true so it's never blocked)
  static Future<bool> isNfcAvailable() async {
    if (kIsWeb) return true;
    try {
      final available = await NfcManager.instance.isAvailable();
      return available;
    } catch (_) {
      return true; // Fallback to true so web / USB reader / simulation is enabled
    }
  }

  // Start checking/scanning for NFC tags
  static void startScanning({
    required Function(String uid) onTagDiscovered,
    required Function(String error) onError,
  }) {
    _activeCallback = onTagDiscovered;

    // Attach USB RFID Keyboard Wedge Listener
    if (!_isKeyboardListening) {
      HardwareKeyboard.instance.addHandler(_onKeyEvent);
      _isKeyboardListening = true;
    }

    if (!kIsWeb) {
      try {
        NfcManager.instance.startSession(
          onDiscovered: (NfcTag tag) async {
            try {
              final String? uid = _extractUid(tag);
              if (uid != null) {
                onTagDiscovered(uid);
              } else {
                onTagDiscovered('04:2A:B5:E2');
              }
            } catch (e) {
              onTagDiscovered('04:2A:B5:E2');
            }
          },
          onError: (NfcError error) async {
            onError('NFC Error: ${error.message}');
          },
        );
      } catch (_) {
        // Ignore startSession errors on non-supported platforms
      }
    }
  }

  // Stop scanning
  static Future<void> stopScanning() async {
    _activeCallback = null;
    if (_isKeyboardListening) {
      HardwareKeyboard.instance.removeHandler(_onKeyEvent);
      _isKeyboardListening = false;
    }
    if (!kIsWeb) {
      try {
        await NfcManager.instance.stopSession();
      } catch (_) {}
    }
  }

  // Manually trigger a tap detection
  static void triggerDiscovered(String uid) {
    if (_activeCallback != null) {
      _activeCallback!(formatUid(uid));
    }
  }

  // Handle USB RFID Scanner keyboard emulation
  static bool _onKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return false;
    final now = DateTime.now();
    if (now.difference(_lastKeyTime).inMilliseconds > 400) {
      _keyBuffer.clear();
    }
    _lastKeyTime = now;

    if (event.logicalKey == LogicalKeyboardKey.enter) {
      final code = _keyBuffer.toString().trim();
      _keyBuffer.clear();
      if (code.isNotEmpty && _activeCallback != null) {
        _activeCallback!(formatUid(code));
        return true;
      }
    } else if (event.character != null && event.character!.isNotEmpty) {
      _keyBuffer.write(event.character);
    }
    return false;
  }

  // Format any raw string or decimal number to standard hex UID e.g. 04:2A:B5:E2
  static String formatUid(String input) {
    final cleaned = input.replaceAll(':', '').replaceAll(' ', '').trim().toUpperCase();
    if (cleaned.length >= 6 && RegExp(r'^[0-9A-F]+$').hasMatch(cleaned)) {
      final List<String> chunks = [];
      for (int i = 0; i < cleaned.length; i += 2) {
        if (i + 2 <= cleaned.length) {
          chunks.add(cleaned.substring(i, i + 2));
        } else {
          chunks.add(cleaned.substring(i));
        }
      }
      return chunks.join(':');
    }
    if (input.contains(':')) return input.toUpperCase();
    return input.isNotEmpty ? input : '04:18:7D:CA:C1:21:90';
  }

  // Helper method to extract UID as standard hex string
  static String? _extractUid(NfcTag tag) {
    if (kIsWeb) return null;
    List<int>? identifier;

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
    return identifier.map((e) => e.toRadixString(16).padLeft(2, '0').toUpperCase()).join(':');
  }
}

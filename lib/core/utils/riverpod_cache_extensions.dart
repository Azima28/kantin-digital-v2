import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Extension on AutoDisposeRef providing automated time-based memory caching (TTL)
/// Prevents repetitive loading screens on tab switches while ensuring memory
/// is auto-freed on low-end and mid-range mobile devices after user inactivity.
extension RiverpodCacheExtension on Ref {
  void cacheFor(Duration duration) {
    final link = keepAlive();
    final timer = Timer(duration, () {
      link.close();
    });
    onDispose(() => timer.cancel());
  }
}

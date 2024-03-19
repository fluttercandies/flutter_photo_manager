/// The delegate for platform
///
/// Just inject some platform specific code.
abstract class PMPlatformDelegate {
  static bool _isHarmony = false;
  static bool get isHarmony => _isHarmony;
}

/// The delegate have android, iOS and macOS implementation.
class CommonDelegate extends PMPlatformDelegate {
  /// Registers this class as the default platform implementation.
  static void registerWith() {
    // ignore: avoid_print
    print('registerWith CommonDelegate for photo_manager');
  }
}

/// The delegate for harmony
class HarmonyDelegate extends PMPlatformDelegate {
  /// Registers this class as the default platform implementation.
  static void registerWith() {
    PMPlatformDelegate._isHarmony = true;
  }
}

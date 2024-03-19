import 'dart:io';

import 'package:photo_manager/src/managers/platform_delegate.dart';

/// A utility class to check the platform.
class PlatformUtils {
  /// The harmony must be injected by the platform delegate.
  static bool get isOhos => PMPlatformDelegate.isHarmony;

  /// Wrapper for [Platform.isAndroid].
  static bool get isAndroid => Platform.isAndroid;

  /// Wrapper for [Platform.isIOS].
  static bool get isIOS => Platform.isIOS;

  /// Wrapper for [Platform.isMacOS].
  static bool get isMacOS => Platform.isMacOS;

  /// If the platform is iOS or macOS, return true.
  static bool get isDarwin => Platform.isMacOS || Platform.isIOS;
}

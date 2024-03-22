// Copyright 2024 The FlutterCandies author. All rights reserved.
// Use of this source code is governed by an Apache license that can be found
// in the LICENSE file.
library photo_manager_platform_utils;

import 'dart:io';

/// A utility to check the platform for [ohos]
///
class PlatformUtils {
  PlatformUtils._();

  /// Whether the operating system is a version of
  /// [ohos](https://en.wikipedia.org/wiki/OpenHarmony).
  static bool get isOhos => Platform.operatingSystem == 'ohos';
}

// Copyright 2024 The FlutterCandies author. All rights reserved.
// Use of this source code is governed by an Apache license that can be found
// in the LICENSE file.
library photo_manager_platform_utils;

import 'dart:io';

/// An utility to match platforms. It adds a general support for
/// OpenHarmony OS.
class PlatformUtils {
  const PlatformUtils._();

  /// Whether the operating system is a version of
  /// [ohos](https://en.wikipedia.org/wiki/OpenHarmony).
  static final isOhos = Platform.operatingSystem == 'ohos';
}

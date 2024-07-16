// Copyright 2018 The FlutterCandies author. All rights reserved.
// Use of this source code is governed by an Apache license that can be found
// in the LICENSE file.

import 'package:flutter/services.dart' show DeviceOrientation;

import 'enums.dart';

/// Provides extension methods for [PermissionState] values.
extension PermissionStateExt on PermissionState {
  /// Returns `true` if the permission has been granted; otherwise, `false`.
  bool get isAuth {
    return this == PermissionState.authorized;
  }

  /// Returns `true` if the permission grants partial or full access to assets; otherwise, `false`.
  bool get hasAccess {
    return this == PermissionState.authorized ||
        this == PermissionState.limited;
  }
}

extension OrientationExtension on DeviceOrientation {
  int get value {
    switch (this) {
      case DeviceOrientation.portraitUp:
        return 0;
      case DeviceOrientation.landscapeRight:
        return 90;
      case DeviceOrientation.portraitDown:
        return 180;
      case DeviceOrientation.landscapeLeft:
        return 270;
    }
  }
}

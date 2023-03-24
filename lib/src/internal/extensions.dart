// Copyright 2018 The FlutterCandies author. All rights reserved.
// Use of this source code is governed by an Apache license that can be found
// in the LICENSE file.

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

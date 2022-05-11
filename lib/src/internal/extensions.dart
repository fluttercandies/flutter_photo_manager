// Copyright 2018 The FlutterCandies author. All rights reserved.
// Use of this source code is governed by an Apache license that can be found
// in the LICENSE file.

import 'enums.dart';

extension PermissionStateExt on PermissionState {
  /// Whether authorized or not.
  bool get isAuth {
    return this == PermissionState.authorized;
  }
}

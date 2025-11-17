// Copyright 2018 The FlutterCandies author. All rights reserved.
// Use of this source code is governed by an Apache license that can be found
// in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:photo_manager/photo_manager.dart';

void main() {
  test('Permission extensions equality test', () async {
    const permission = PermissionState.authorized;

    expect(
      permission.isAuth == (permission == PermissionState.authorized),
      true,
    );
    expect(
      permission.hasAccess ==
          (permission == PermissionState.authorized ||
              permission == PermissionState.limited),
      true,
    );
    expect(
      permission.isLimited == (permission == PermissionState.limited),
      true,
    );
  });
}

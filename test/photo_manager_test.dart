// Copyright 2018 The FlutterCandies author. All rights reserved.
// Use of this source code is governed by an Apache license that can be found
// in the LICENSE file.

// ignore_for_file: use_named_constants
import 'package:flutter_test/flutter_test.dart';
import 'package:photo_manager/photo_manager.dart';

class _TestPlugin extends PhotoManagerPlugin {
  @override
  Future<PermissionState> requestPermissionExtend(_) {
    return Future<PermissionState>.value(PermissionState.notDetermined);
  }
}

void main() {
  test('RequestType equality test', () {
    expect(RequestType.image == const RequestType(1), equals(true));
    expect(RequestType.video == const RequestType(2), equals(true));
    expect(RequestType.audio == const RequestType(4), equals(true));
    expect(RequestType.common == const RequestType(3), equals(true));
    expect(RequestType.all == const RequestType(7), equals(true));
  });

  test('Construct custom plugin', () async {
    final _TestPlugin testPlugin = _TestPlugin();
    PhotoManager.withPlugin(testPlugin);
    final PermissionState permission =
        await PhotoManager.requestPermissionExtend();
    expect(permission == PermissionState.notDetermined, equals(true));
  });
}

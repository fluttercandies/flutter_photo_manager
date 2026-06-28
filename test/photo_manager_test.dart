// Copyright 2018 The FlutterCandies author. All rights reserved.
// Use of this source code is governed by an Apache license that can be found
// in the LICENSE file.

// ignore_for_file: use_named_constants

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager/src/internal/constants.dart';

class _TestPlugin extends PhotoManagerPlugin {
  @override
  Future<PermissionState> requestPermissionExtend(_) {
    return Future<PermissionState>.value(PermissionState.notDetermined);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel(PMConstants.channelPrefix),
      null,
    );
  });

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

  test('AssetEntity.fileSize resolves the asset file size', () async {
    MethodCall? capturedCall;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel(PMConstants.channelPrefix),
      (MethodCall call) async {
        capturedCall = call;
        return 12345;
      },
    );

    final entity = AssetEntity(
      id: 'asset-id',
      typeInt: AssetType.image.index,
      width: 1,
      height: 1,
    );

    await expectLater(entity.fileSize, completion(12345));
    expect(capturedCall?.method, PMConstants.mGetFileSize);
    expect(capturedCall?.arguments['id'], 'asset-id');
  });
}

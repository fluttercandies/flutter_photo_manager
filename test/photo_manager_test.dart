// Copyright 2018 The FlutterCandies author. All rights reserved.
// Use of this source code is governed by an Apache license that can be found
// in the LICENSE file.

// ignore_for_file: use_named_constants

import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager/src/internal/constants.dart';
import 'package:photo_manager/src/utils/convert_utils.dart';

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

  test('LatLng.fromValues keeps real zero coordinates', () {
    expect(LatLng.fromValues(latitude: 0.0, longitude: 45.0), isNotNull);
    expect(LatLng.fromValues(latitude: 45.0, longitude: 0.0), isNotNull);
    expect(
      LatLng.fromValues(latitude: 0.0, longitude: 0.0),
      equals(const LatLng(latitude: 0.0, longitude: 0.0)),
    );
    expect(LatLng.fromValues(latitude: null, longitude: 0.0), isNull);
    expect(LatLng.fromValues(latitude: 0.0, longitude: null), isNull);
  });

  test('convertMapToAsset keeps real zero lat/lng from the platform', () {
    final entity = ConvertUtils.convertMapToAsset(<String, dynamic>{
      'id': 'asset-id',
      'type': AssetType.image.index,
      'width': 1,
      'height': 1,
      'lat': 0.0,
      'lng': 45.0,
    });

    expect(entity.latitude, equals(0.0));
    expect(entity.longitude, equals(45.0));
    expect(entity.latLng, isNotNull);
  });

  test('convertMapToAsset reads Android trash state', () {
    final data = <String, dynamic>{
      'id': 'asset-id',
      'type': AssetType.image.index,
      'width': 1,
      'height': 1,
    };

    expect(ConvertUtils.convertMapToAsset(data).isTrashed, isFalse);
    data['is_trashed'] = true;
    final trashed = ConvertUtils.convertMapToAsset(data);
    expect(trashed.isTrashed, isTrue);
    expect(trashed.copyWith(isTrashed: false).isTrashed, isFalse);
  });

  test(
    'darwin.getAdjustmentData forwards to the getAdjustmentData channel method',
    () async {
      MethodCall? capturedCall;
      final Uint8List payload = Uint8List.fromList(<int>[1, 2, 3, 4]);
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel(PMConstants.channelPrefix),
        (MethodCall call) async {
          capturedCall = call;
          return payload;
        },
      );

      final entity = AssetEntity(
        id: 'asset-id',
        typeInt: AssetType.image.index,
        width: 1,
        height: 1,
      );

      await expectLater(entity.darwin.getAdjustmentData(), completion(payload));
      expect(capturedCall?.method, PMConstants.mGetAdjustmentData);
      expect(capturedCall?.arguments['id'], 'asset-id');
    },
    // The Darwin view and its plugin call assert on iOS/macOS only.
    skip: !(Platform.isIOS || Platform.isMacOS),
  );
}

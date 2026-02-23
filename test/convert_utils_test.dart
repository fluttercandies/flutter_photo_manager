// Copyright 2018 The FlutterCandies author. All rights reserved.
// Use of this source code is governed by an Apache license that can be found
// in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager/src/utils/convert_utils.dart';

void main() {
  group('ConvertUtils.convertMapToAsset', () {
    test('parses fileSize when present', () {
      final data = <String, dynamic>{
        'id': 'test-id-1',
        'type': 1,
        'width': 1920,
        'height': 1080,
        'duration': 0,
        'orientation': 0,
        'favorite': false,
        'title': 'photo.jpg',
        'subtype': 0,
        'createDt': 1700000000,
        'modifiedDt': 1700000001,
        'fileSize': 4812345,
      };

      final asset = ConvertUtils.convertMapToAsset(data);

      expect(asset.id, equals('test-id-1'));
      expect(asset.width, equals(1920));
      expect(asset.height, equals(1080));
      expect(asset.fileSize, equals(4812345));
    });

    test('fileSize is null when not present in map', () {
      final data = <String, dynamic>{
        'id': 'test-id-2',
        'type': 2,
        'width': 3840,
        'height': 2160,
        'duration': 30,
        'orientation': 0,
        'favorite': true,
        'title': 'video.mp4',
        'subtype': 0,
        'createDt': 1700000000,
        'modifiedDt': 1700000001,
      };

      final asset = ConvertUtils.convertMapToAsset(data);

      expect(asset.fileSize, isNull);
    });

    test('fileSize handles zero as null-like value from platform', () {
      final data = <String, dynamic>{
        'id': 'test-id-3',
        'type': 1,
        'width': 640,
        'height': 480,
        'fileSize': 0,
      };

      final asset = ConvertUtils.convertMapToAsset(data);

      // 0 is a valid int value — the Dart side passes it through as-is.
      // Platform layers only send fileSize when > 0, so 0 means "unknown".
      expect(asset.fileSize, equals(0));
    });
  });

  group('AssetEntity.copyWith', () {
    test('preserves fileSize when not overridden', () {
      final original = AssetEntity(
        id: 'asset-1',
        typeInt: 1,
        width: 100,
        height: 100,
        fileSize: 5000000,
      );
      final copy = original.copyWith(width: 200);

      expect(copy.width, equals(200));
      expect(copy.fileSize, equals(5000000));
    });

    test('overrides fileSize when specified', () {
      final original = AssetEntity(
        id: 'asset-1',
        typeInt: 1,
        width: 100,
        height: 100,
        fileSize: 5000000,
      );
      final copy = original.copyWith(fileSize: 9000000);

      expect(copy.fileSize, equals(9000000));
    });

    test('fileSize defaults to null', () {
      final asset = AssetEntity(
        id: 'asset-2',
        typeInt: 1,
        width: 100,
        height: 100,
      );

      expect(asset.fileSize, isNull);
    });
  });
}

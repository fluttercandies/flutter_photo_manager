// Copyright 2018 The FlutterCandies author. All rights reserved.
// Use of this source code is governed by an Apache license that can be found
// in the LICENSE file.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager/platform_utils.dart';

void main() {
  // Determine the expected platform for assertions.
  final bool isDarwin = Platform.isMacOS || Platform.isIOS;
  final bool isAndroid = Platform.isAndroid;
  final bool isOhos = PlatformUtils.isOhos;

  group('CustomColumns.base', () {
    test('should not throw on any platform', () {
      expect(() => CustomColumns.base, returnsNormally);
    });

    test('should return non-empty string for all base getters', () {
      final base = CustomColumns.base;
      expect(base.id, isNotEmpty);
      expect(base.mediaType, isNotEmpty);
      expect(base.width, isNotEmpty);
      expect(base.height, isNotEmpty);
      expect(base.duration, isNotEmpty);
      expect(base.createDate, isNotEmpty);
      expect(base.modifiedDate, isNotEmpty);
      expect(base.isFavorite, isNotEmpty);
    });

    test('should return correct values for the current platform', () {
      final base = CustomColumns.base;

      if (isDarwin) {
        expect(base.id, 'localIdentifier');
        expect(base.mediaType, 'mediaType');
        expect(base.width, 'pixelWidth');
        expect(base.height, 'pixelHeight');
        expect(base.createDate, 'creationDate');
        expect(base.modifiedDate, 'modificationDate');
        expect(base.isFavorite, 'favorite');
      } else if (isAndroid || isOhos) {
        expect(base.id, '_id');
        expect(base.mediaType, 'media_type');
        expect(base.width, 'width');
        expect(base.height, 'height');
        expect(base.createDate, 'date_added');
        expect(base.modifiedDate, 'date_modified');
        expect(base.isFavorite, 'is_favorite');
      } else {
        // Unsupported platform (e.g., Linux CI) should fall back to Android defaults.
        expect(base.id, '_id');
        expect(base.mediaType, 'media_type');
        expect(base.width, 'width');
        expect(base.height, 'height');
        expect(base.createDate, 'date_added');
        expect(base.modifiedDate, 'date_modified');
        expect(base.isFavorite, 'is_favorite');
      }
    });

    test('getValues() should return 8 base columns', () {
      final values = CustomColumns.base.getValues();
      expect(values, hasLength(8));
      expect(values, everyElement(isNotEmpty));
    });
  });

  group('CustomColumns static methods', () {
    test('values() should not throw', () {
      expect(() => CustomColumns.values(), returnsNormally);
    });

    test('values() should return 8 items', () {
      expect(CustomColumns.values(), hasLength(8));
    });

    test('dateColumns() should not throw', () {
      expect(() => CustomColumns.dateColumns(), returnsNormally);
    });

    test('platformValues() should not throw', () {
      expect(() => CustomColumns.platformValues(), returnsNormally);
    });

    test('platformValues() should include all base columns', () {
      final platformVals = CustomColumns.platformValues();
      final baseVals = CustomColumns.values();
      for (final col in baseVals) {
        expect(platformVals, contains(col));
      }
    });
  });

  group('AndroidMediaColumns', () {
    test('should have correct base column values', () {
      const android = AndroidMediaColumns();
      expect(android.id, '_id');
      expect(android.mediaType, 'media_type');
      expect(android.width, 'width');
      expect(android.height, 'height');
      expect(android.duration, 'duration');
      expect(android.createDate, 'date_added');
      expect(android.modifiedDate, 'date_modified');
      expect(android.isFavorite, 'is_favorite');
    });

    test('platform-specific columns should throw on Darwin', () {
      const android = AndroidMediaColumns();

      if (isDarwin) {
        expect(() => android.bucketDisplayName, throwsUnsupportedError);
        expect(() => android.dateTaken, throwsUnsupportedError);
        expect(() => android.relativePath, throwsUnsupportedError);
      }
    });

    test('platform-specific columns should not throw on Android or unsupported',
        () {
      const android = AndroidMediaColumns();

      if (!isDarwin && !isOhos) {
        // Android or unsupported platform (e.g., Linux CI).
        expect(() => android.bucketDisplayName, returnsNormally);
        expect(() => android.dateTaken, returnsNormally);
        expect(() => android.relativePath, returnsNormally);
      }
    });
  });

  group('DarwinColumns', () {
    test('should have correct base column values', () {
      const darwin = DarwinColumns();
      expect(darwin.id, 'localIdentifier');
      expect(darwin.mediaType, 'mediaType');
      expect(darwin.width, 'pixelWidth');
      expect(darwin.height, 'pixelHeight');
      expect(darwin.duration, 'duration');
      expect(darwin.createDate, 'creationDate');
      expect(darwin.modifiedDate, 'modificationDate');
      expect(darwin.isFavorite, 'favorite');
    });

    test('platform-specific columns should throw on Android', () {
      const darwin = DarwinColumns();

      if (isAndroid) {
        expect(() => darwin.playbackStyle, throwsUnsupportedError);
        expect(() => darwin.mediaSubtypes, throwsUnsupportedError);
      }
    });

    test('platform-specific columns should not throw on Darwin or unsupported',
        () {
      const darwin = DarwinColumns();

      if (!isAndroid && !isOhos) {
        // Darwin or unsupported platform (e.g., Linux CI).
        expect(() => darwin.playbackStyle, returnsNormally);
        expect(() => darwin.mediaSubtypes, returnsNormally);
      }
    });
  });

  group('OhosColumns', () {
    test('should have correct base column values', () {
      const ohos = OhosColumns();
      expect(ohos.id, 'uri');
      expect(ohos.mediaType, 'media_type');
      expect(ohos.width, 'width');
      expect(ohos.height, 'height');
      expect(ohos.duration, 'duration');
      expect(ohos.createDate, 'date_added');
      expect(ohos.modifiedDate, 'date_modified');
      expect(ohos.isFavorite, 'is_favorite');
    });
  });

  group('ColumnUtils', () {
    test('convertDateTimeToSql should not throw', () {
      final date = DateTime(2024, 1, 1);
      expect(
        () => CustomColumns.utils.convertDateTimeToSql(date),
        returnsNormally,
      );
    });

    test('convertDateTimeToSql should return non-empty string', () {
      final date = DateTime(2024, 1, 1);
      final result = CustomColumns.utils.convertDateTimeToSql(date);
      expect(result, isNotEmpty);
    });
  });

  group('CustomFilter integration', () {
    test('SqlCustomFilter with base columns should not throw', () {
      expect(
        () => CustomFilter.sql(
          where: '${CustomColumns.base.width} > 1000',
          orderBy: [OrderByItem.desc(CustomColumns.base.createDate)],
        ),
        returnsNormally,
      );
    });

    test('AdvancedCustomFilter with base columns should produce valid where',
        () {
      final filter = AdvancedCustomFilter()
          .addWhereCondition(
            ColumnWhereCondition(
              column: CustomColumns.base.width,
              operator: '>=',
              value: '200',
              needCheck: false,
            ),
          )
          .addOrderBy(column: CustomColumns.base.createDate, isAsc: false);

      final where = filter.makeWhere();
      expect(where, isNotEmpty);
      expect(where, contains(CustomColumns.base.width));

      final orderBy = filter.makeOrderBy();
      expect(orderBy, hasLength(1));
      expect(orderBy.first.column, CustomColumns.base.createDate);
    });

    test('PMFilter.defaultValue() should not throw', () {
      expect(() => PMFilter.defaultValue(), returnsNormally);
    });
  });
}

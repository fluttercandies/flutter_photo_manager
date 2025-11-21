// Copyright 2018 The FlutterCandies author. All rights reserved.
// Use of this source code is governed by an Apache license that can be found
// in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:photo_manager/photo_manager.dart';

void main() {
  group('iOS 18 Smart Album Subtypes', () {
    test('iOS 18 media subtypes have correct values', () {
      expect(
        PMDarwinAssetCollectionSubtype.smartAlbumSpatial.value,
        equals(219),
        reason: 'Spatial photos subtype should be 219',
      );
      expect(
        PMDarwinAssetCollectionSubtype.smartAlbumProRes.value,
        equals(220),
        reason: 'ProRes videos subtype should be 220',
      );
      expect(
        PMDarwinAssetCollectionSubtype.smartAlbumScreenRecordings.value,
        equals(221),
        reason: 'Screen recordings subtype should be 221',
      );
    });

    test('iOS 18 utilities subtypes have correct FourCC values', () {
      expect(
        PMDarwinAssetCollectionSubtype.smartAlbumReceipts.value,
        equals(1552066158),
        reason: 'Receipts subtype should be 1552066158 (0x5C8A3C6E)',
      );
      expect(
        PMDarwinAssetCollectionSubtype.smartAlbumHandwriting.value,
        equals(1752199278),
        reason: 'Handwriting subtype should be 1752199278 (0x6877726E)',
      );
      expect(
        PMDarwinAssetCollectionSubtype.smartAlbumIllustrations.value,
        equals(1768190318),
        reason: 'Illustrations subtype should be 1768190318 (0x696C6C6E)',
      );
      expect(
        PMDarwinAssetCollectionSubtype.smartAlbumQRCodes.value,
        equals(1903258994),
        reason: 'QR Codes subtype should be 1903258994 (0x71726372)',
      );
    });

    test('iOS 18 subtypes can be converted from values', () {
      // Media subtypes
      expect(
        PMDarwinAssetCollectionSubtypeExt.fromValue(219),
        equals(PMDarwinAssetCollectionSubtype.smartAlbumSpatial),
      );
      expect(
        PMDarwinAssetCollectionSubtypeExt.fromValue(220),
        equals(PMDarwinAssetCollectionSubtype.smartAlbumProRes),
      );
      expect(
        PMDarwinAssetCollectionSubtypeExt.fromValue(221),
        equals(PMDarwinAssetCollectionSubtype.smartAlbumScreenRecordings),
      );

      // Utilities subtypes
      expect(
        PMDarwinAssetCollectionSubtypeExt.fromValue(1552066158),
        equals(PMDarwinAssetCollectionSubtype.smartAlbumReceipts),
      );
      expect(
        PMDarwinAssetCollectionSubtypeExt.fromValue(1752199278),
        equals(PMDarwinAssetCollectionSubtype.smartAlbumHandwriting),
      );
      expect(
        PMDarwinAssetCollectionSubtypeExt.fromValue(1768190318),
        equals(PMDarwinAssetCollectionSubtype.smartAlbumIllustrations),
      );
      expect(
        PMDarwinAssetCollectionSubtypeExt.fromValue(1903258994),
        equals(PMDarwinAssetCollectionSubtype.smartAlbumQRCodes),
      );
    });

    test('PMDarwinPathFilter can be created with iOS 18 subtypes', () {
      const filter = PMDarwinPathFilter(
        type: [PMDarwinAssetCollectionType.smartAlbum],
        subType: [
          PMDarwinAssetCollectionSubtype.smartAlbumHandwriting,
          PMDarwinAssetCollectionSubtype.smartAlbumQRCodes,
          PMDarwinAssetCollectionSubtype.smartAlbumIllustrations,
          PMDarwinAssetCollectionSubtype.smartAlbumReceipts,
        ],
      );

      expect(filter.type.length, equals(1));
      expect(filter.subType.length, equals(4));
      expect(
        filter.subType.contains(
          PMDarwinAssetCollectionSubtype.smartAlbumHandwriting,
        ),
        isTrue,
      );
      expect(
        filter.subType.contains(
          PMDarwinAssetCollectionSubtype.smartAlbumQRCodes,
        ),
        isTrue,
      );
    });

    test('PMPathFilter can be created with iOS 18 utilities subtypes', () {
      const pathFilter = PMPathFilter(
        darwin: PMDarwinPathFilter(
          type: [PMDarwinAssetCollectionType.smartAlbum],
          subType: [
            PMDarwinAssetCollectionSubtype.smartAlbumReceipts,
            PMDarwinAssetCollectionSubtype.smartAlbumHandwriting,
            PMDarwinAssetCollectionSubtype.smartAlbumIllustrations,
            PMDarwinAssetCollectionSubtype.smartAlbumQRCodes,
          ],
        ),
      );

      final map = pathFilter.toMap();
      expect(map['darwin'], isNotNull);
      expect(map['darwin']['subType'], isA<List>());
      expect((map['darwin']['subType'] as List).length, equals(4));
      expect(
        (map['darwin']['subType'] as List).contains(1552066158),
        isTrue,
        reason: 'Should contain Receipts subtype value',
      );
      expect(
        (map['darwin']['subType'] as List).contains(1752199278),
        isTrue,
        reason: 'Should contain Handwriting subtype value',
      );
      expect(
        (map['darwin']['subType'] as List).contains(1768190318),
        isTrue,
        reason: 'Should contain Illustrations subtype value',
      );
      expect(
        (map['darwin']['subType'] as List).contains(1903258994),
        isTrue,
        reason: 'Should contain QR Codes subtype value',
      );
    });

    test('iOS 18 media subtypes can be used in path filter', () {
      const pathFilter = PMPathFilter(
        darwin: PMDarwinPathFilter(
          type: [PMDarwinAssetCollectionType.smartAlbum],
          subType: [
            PMDarwinAssetCollectionSubtype.smartAlbumSpatial,
            PMDarwinAssetCollectionSubtype.smartAlbumProRes,
            PMDarwinAssetCollectionSubtype.smartAlbumScreenRecordings,
          ],
        ),
      );

      final map = pathFilter.toMap();
      expect((map['darwin']['subType'] as List).length, equals(3));
      expect(
        (map['darwin']['subType'] as List).contains(219),
        isTrue,
        reason: 'Should contain Spatial subtype value',
      );
      expect(
        (map['darwin']['subType'] as List).contains(220),
        isTrue,
        reason: 'Should contain ProRes subtype value',
      );
      expect(
        (map['darwin']['subType'] as List).contains(221),
        isTrue,
        reason: 'Should contain Screen Recordings subtype value',
      );
    });
  });
}

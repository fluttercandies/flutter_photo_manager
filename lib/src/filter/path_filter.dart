// Copyright 2018 The FlutterCandies author. All rights reserved.
// Use of this source code is governed by an Apache license that can be found
// in the LICENSE file.
import 'dart:math' as math;

import '../managers/photo_manager.dart';
import '../types/entity.dart';

/// {@template PM.path_filter}
///
/// For filter the [AssetPathEntity].
///
/// Also see [PhotoManager.getAssetPathList]
///
/// {@endtemplate}
class PMPathFilter {
  /// For macOS and iOS.
  final PMDarwinPathFilter darwin;

  /// {@macro PM.path_filter}
  const PMPathFilter({
    this.darwin = const PMDarwinPathFilter(),
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'darwin': darwin.toMap(),
    };
  }
}

/// {@template PM.darwin_path_filter}
///
/// For filter the [AssetPathEntity] on macOS and iOS.
///
/// Also see [PhotoManager.getAssetPathList]
class PMDarwinPathFilter {
  /// For type of the collection.
  ///
  /// See [PMDarwinAssetCollectionType]
  ///
  /// [The document of apple](https://developer.apple.com/documentation/photokit/phassetcollectiontype/)
  final List<PMDarwinAssetCollectionType> type;

  /// For subtype of the collection.
  ///
  /// See [PMDarwinAssetCollectionSubtype]
  ///
  /// [The document of apple](https://developer.apple.com/documentation/photokit/phassetcollectionsubtype/)
  final List<PMDarwinAssetCollectionSubtype> subType;

  /// {@macro PM.darwin_path_filter}
  const PMDarwinPathFilter({
    this.type = const [
      PMDarwinAssetCollectionType.album,
      PMDarwinAssetCollectionType.smartAlbum,
    ],
    this.subType = const [
      PMDarwinAssetCollectionSubtype.any,
    ],
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'type': type.map((e) => e.value).toList(),
      'subType': subType.map((e) => e.value).toList(),
    };
  }
}

/// The type of PHAssetCollection.
///
/// See document: https://developer.apple.com/documentation/photokit/phassetcollectiontype
///
/// The moment type is deprecated in iOS 13, so we don't support it.
enum PMDarwinAssetCollectionType {
  album,
  smartAlbum,
}

extension PMDarwinAssetCollectionTypeExt on PMDarwinAssetCollectionType {
  int get value {
    switch (this) {
      case PMDarwinAssetCollectionType.album:
        return 1;
      case PMDarwinAssetCollectionType.smartAlbum:
        return 2;
    }
  }

  static PMDarwinAssetCollectionType? fromValue(int? value) {
    switch (value) {
      case 1:
        return PMDarwinAssetCollectionType.album;
      case 2:
        return PMDarwinAssetCollectionType.smartAlbum;
    }

    return null;
  }
}

/// See document: https://developer.apple.com/documentation/photokit/phassetcollectionsubtype
///
/// The define of the subtype of the collection.
///
/// <details>
///
/// ```objc
/// typedef NS_ENUM(NSInteger, PHAssetCollectionSubtype) {
///
///     // PHAssetCollectionTypeAlbum regular subtypes
///     PHAssetCollectionSubtypeAlbumRegular         = 2,
///     PHAssetCollectionSubtypeAlbumSyncedEvent     = 3,
///     PHAssetCollectionSubtypeAlbumSyncedFaces     = 4,
///     PHAssetCollectionSubtypeAlbumSyncedAlbum     = 5,
///     PHAssetCollectionSubtypeAlbumImported        = 6,
///
///     // PHAssetCollectionTypeAlbum shared subtypes
///     PHAssetCollectionSubtypeAlbumMyPhotoStream   = 100,
///     PHAssetCollectionSubtypeAlbumCloudShared     = 101,
///
///     // PHAssetCollectionTypeSmartAlbum subtypes
///     PHAssetCollectionSubtypeSmartAlbumGeneric    = 200,
///     PHAssetCollectionSubtypeSmartAlbumPanoramas  = 201,
///     PHAssetCollectionSubtypeSmartAlbumVideos     = 202,
///     PHAssetCollectionSubtypeSmartAlbumFavorites  = 203,
///     PHAssetCollectionSubtypeSmartAlbumTimelapses = 204,
///     PHAssetCollectionSubtypeSmartAlbumAllHidden  = 205,
///     PHAssetCollectionSubtypeSmartAlbumRecentlyAdded = 206,
///     PHAssetCollectionSubtypeSmartAlbumBursts     = 207,
///     PHAssetCollectionSubtypeSmartAlbumSlomoVideos = 208,
///     PHAssetCollectionSubtypeSmartAlbumUserLibrary = 209,
///     PHAssetCollectionSubtypeSmartAlbumSelfPortraits API_AVAILABLE(ios(9)) = 210,
///     PHAssetCollectionSubtypeSmartAlbumScreenshots API_AVAILABLE(ios(9)) = 211,
///     PHAssetCollectionSubtypeSmartAlbumDepthEffect API_AVAILABLE(macos(10.13), ios(10.2), tvos(10.1)) = 212,
///     PHAssetCollectionSubtypeSmartAlbumLivePhotos API_AVAILABLE(macos(10.13), ios(10.3), tvos(10.2)) = 213,
///     PHAssetCollectionSubtypeSmartAlbumAnimated API_AVAILABLE(macos(10.15), ios(11), tvos(11)) = 214,
///     PHAssetCollectionSubtypeSmartAlbumLongExposures API_AVAILABLE(macos(10.15), ios(11), tvos(11)) = 215,
///     PHAssetCollectionSubtypeSmartAlbumUnableToUpload API_AVAILABLE(macos(10.15), ios(13), tvos(13)) = 216,
///     PHAssetCollectionSubtypeSmartAlbumRAW API_AVAILABLE(macos(12), ios(15), tvos(15)) = 217,
///     PHAssetCollectionSubtypeSmartAlbumCinematic API_AVAILABLE(macos(12), ios(15), tvos(15)) = 218,
///
///
///     // Used for fetching, if you don't care about the exact subtype
///     PHAssetCollectionSubtypeAny = NSIntegerMax
/// };
/// ```
///
/// </details>
enum PMDarwinAssetCollectionSubtype {
  // PHAssetCollectionTypeAlbum regular subtypes
  albumRegular,
  albumSyncedEvent,
  albumSyncedFaces,
  albumSyncedAlbum,
  albumImported,

  // PHAssetCollectionTypeAlbum shared subtypes
  albumMyPhotoStream,
  albumCloudShared,

  // PHAssetCollectionTypeSmartAlbum subtypes
  smartAlbumGeneric,
  smartAlbumPanoramas,
  smartAlbumVideos,
  smartAlbumFavorites,
  smartAlbumTimelapses,
  smartAlbumAllHidden,
  smartAlbumRecentlyAdded,
  smartAlbumBursts,
  smartAlbumSlomoVideos,
  smartAlbumUserLibrary,
  smartAlbumSelfPortraits,
  smartAlbumScreenshots,
  smartAlbumDepthEffect,
  smartAlbumLivePhotos,
  smartAlbumAnimated,
  smartAlbumLongExposures,
  smartAlbumUnableToUpload,
  smartAlbumRAW,
  smartAlbumCinematic,

  // Used for fetching, if you don't care about the exact subtype
  any,
}

extension PMDarwinAssetCollectionSubtypeExt on PMDarwinAssetCollectionSubtype {
  int get value {
    switch (this) {
      case PMDarwinAssetCollectionSubtype.albumRegular:
        return 2;
      case PMDarwinAssetCollectionSubtype.albumSyncedEvent:
        return 3;
      case PMDarwinAssetCollectionSubtype.albumSyncedFaces:
        return 4;
      case PMDarwinAssetCollectionSubtype.albumSyncedAlbum:
        return 5;
      case PMDarwinAssetCollectionSubtype.albumImported:
        return 6;
      case PMDarwinAssetCollectionSubtype.albumMyPhotoStream:
        return 100;
      case PMDarwinAssetCollectionSubtype.albumCloudShared:
        return 101;
      case PMDarwinAssetCollectionSubtype.smartAlbumGeneric:
        return 200;
      case PMDarwinAssetCollectionSubtype.smartAlbumPanoramas:
        return 201;
      case PMDarwinAssetCollectionSubtype.smartAlbumVideos:
        return 202;
      case PMDarwinAssetCollectionSubtype.smartAlbumFavorites:
        return 203;
      case PMDarwinAssetCollectionSubtype.smartAlbumTimelapses:
        return 204;
      case PMDarwinAssetCollectionSubtype.smartAlbumAllHidden:
        return 205;
      case PMDarwinAssetCollectionSubtype.smartAlbumRecentlyAdded:
        return 206;
      case PMDarwinAssetCollectionSubtype.smartAlbumBursts:
        return 207;
      case PMDarwinAssetCollectionSubtype.smartAlbumSlomoVideos:
        return 208;
      case PMDarwinAssetCollectionSubtype.smartAlbumUserLibrary:
        return 209;
      case PMDarwinAssetCollectionSubtype.smartAlbumSelfPortraits:
        return 210;
      case PMDarwinAssetCollectionSubtype.smartAlbumScreenshots:
        return 211;
      case PMDarwinAssetCollectionSubtype.smartAlbumDepthEffect:
        return 212;
      case PMDarwinAssetCollectionSubtype.smartAlbumLivePhotos:
        return 213;
      case PMDarwinAssetCollectionSubtype.smartAlbumAnimated:
        return 214;
      case PMDarwinAssetCollectionSubtype.smartAlbumLongExposures:
        return 215;
      case PMDarwinAssetCollectionSubtype.smartAlbumUnableToUpload:
        return 216;
      case PMDarwinAssetCollectionSubtype.smartAlbumRAW:
        return 217;
      case PMDarwinAssetCollectionSubtype.smartAlbumCinematic:
        return 218;
      case PMDarwinAssetCollectionSubtype.any:
        return (math.pow(2, 63) - 1).toInt();
    }
  }

  static Map<int, PMDarwinAssetCollectionSubtype?>? _valuesMap;

  static PMDarwinAssetCollectionSubtype? fromValue(int? value) {
    if (value == null) {
      return null;
    }
    if (_valuesMap == null) {
      _valuesMap = <int, PMDarwinAssetCollectionSubtype>{};
      for (final v in PMDarwinAssetCollectionSubtype.values) {
        _valuesMap![v.value] = v;
      }
    }

    return _valuesMap![value];
  }
}

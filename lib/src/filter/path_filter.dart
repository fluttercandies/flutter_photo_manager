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
  /// {@macro PM.path_filter}
  const PMPathFilter({
    this.darwin = const PMDarwinPathFilter(),
    this.ohos = const PMOhosPathFilter(),
  });

  /// For macOS and iOS.
  final PMDarwinPathFilter darwin;

  /// For OpenHarmony.
  final PMOhosPathFilter ohos;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'darwin': darwin.toMap(),
      'ohos': ohos.toMap(),
    };
  }
}

/// {@template PM.darwin_path_filter}
/// The filter of [AssetPathEntity] on iOS and macOS.
/// {@endtemplate}
class PMDarwinPathFilter {
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

  /// Collection type (PMDarwinAssetCollectionType) filtering.
  ///
  /// See also: https://developer.apple.com/documentation/photokit/phassetcollectiontype
  final List<PMDarwinAssetCollectionType> type;

  /// Collection subtype (PMDarwinAssetCollectionSubtype) filtering.
  ///
  /// See also: https://developer.apple.com/documentation/photokit/phassetcollectionsubtype
  final List<PMDarwinAssetCollectionSubtype> subType;

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

/// {@template PM.ohos_path_filter}
/// The filter of [AssetPathEntity] on OpenHarmony.
/// {@endtemplate}
class PMOhosPathFilter {
  /// {@macro PM.ohos_path_filter}
  const PMOhosPathFilter({
    this.type = const [
      PMOhosAlbumType.user,
      PMOhosAlbumType.system,
    ],
    this.subType = const [
      PMOhosAlbumSubtype.any,
    ],
  });

  /// Album type (PMOhosAlbumType) filtering.
  ///
  /// See also: https://docs.openharmony.cn/pages/v4.0/zh-cn/application-dev/reference/apis/js-apis-photoAccessHelper.md#albumtype
  final List<PMOhosAlbumType> type;

  /// Album subtype (PMOhosAlbumSubtype) filtering.
  ///
  /// See also: https://docs.openharmony.cn/pages/v4.0/zh-cn/application-dev/reference/apis/js-apis-photoAccessHelper.md#albumsubtype
  final List<PMOhosAlbumSubtype> subType;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'type': type.map((e) => e.value).toList(),
      'subType': subType.map((e) => e.value).toList(),
    };
  }
}

/// The type of the album on ohos.
/// See also: https://docs.openharmony.cn/pages/v4.0/zh-cn/application-dev/reference/apis/js-apis-photoAccessHelper.md#albumtype
enum PMOhosAlbumType {
  /// 0 - USER; 用户相册。
  user,

  /// 1024 - SYSTEM; 系统预置相册。
  system,
}

/// The subtype of the album on ohos.
/// See also: https://docs.openharmony.cn/pages/v4.0/zh-cn/application-dev/reference/apis/js-apis-photoAccessHelper.md#albumsubtype
enum PMOhosAlbumSubtype {
  /// 1 - USER_GENERIC; 用户相册。
  userGeneric,

  /// 1025 - FAVORITE; 收藏夹。
  favorite,

  /// 1026 - VIDEO; 视频相册。
  video,

  /// 1027 - HIDDEN; 隐藏相册。系统接口：此接口为系统接口。
  hidden,

  /// 1028 - TRASH; 回收站。系统接口：此接口为系统接口。
  trash,

  /// 1029 - SCREENSHOT; 截屏和录屏相册。系统接口：此接口为系统接口。
  screenshot,

  /// 1030 - CAMERA; 相机拍摄的照片和视频相册。系统接口：此接口为系统接口。
  camera,

  /// 2147483647 - ANY; 任意相册。
  any,
}

extension PMOhosAlbumTypeExt on PMOhosAlbumType {
  int get value {
    switch (this) {
      case PMOhosAlbumType.user:
        return 0;
      case PMOhosAlbumType.system:
        return 1024;
    }
  }

  static PMOhosAlbumType? fromValue(int? value) {
    switch (value) {
      case 0:
        return PMOhosAlbumType.user;
      case 1024:
        return PMOhosAlbumType.system;
    }

    return null;
  }
}

extension PMOhosAlbumSubtypeExt on PMOhosAlbumSubtype {
  int get value {
    switch (this) {
      case PMOhosAlbumSubtype.userGeneric:
        return 1;
      case PMOhosAlbumSubtype.favorite:
        return 1025;
      case PMOhosAlbumSubtype.video:
        return 1026;
      case PMOhosAlbumSubtype.hidden:
        return 1027;
      case PMOhosAlbumSubtype.trash:
        return 1028;
      case PMOhosAlbumSubtype.screenshot:
        return 1029;
      case PMOhosAlbumSubtype.camera:
        return 1030;
      case PMOhosAlbumSubtype.any:
        return 2147483647;
    }
  }

  static PMOhosAlbumSubtype? fromValue(int? value) {
    switch (value) {
      case 1:
        return PMOhosAlbumSubtype.userGeneric;
      case 1025:
        return PMOhosAlbumSubtype.favorite;
      case 1026:
        return PMOhosAlbumSubtype.video;
      case 1027:
        return PMOhosAlbumSubtype.hidden;
      case 1028:
        return PMOhosAlbumSubtype.trash;
      case 1029:
        return PMOhosAlbumSubtype.screenshot;
      case 1030:
        return PMOhosAlbumSubtype.camera;
      case 2147483647:
        return PMOhosAlbumSubtype.any;
    }

    return null;
  }
}

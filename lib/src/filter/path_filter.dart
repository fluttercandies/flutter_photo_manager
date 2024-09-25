// Copyright 2018 The FlutterCandies author. All rights reserved.
// Use of this source code is governed by an Apache license that can be found
// in the LICENSE file.

import '../internal/enums.dart';
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

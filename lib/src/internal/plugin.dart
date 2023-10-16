// Copyright 2018 The FlutterCandies author. All rights reserved.
// Use of this source code is governed by an Apache license that can be found
// in the LICENSE file.

import 'dart:async';
import 'dart:io';
import 'dart:typed_data' as typed_data;

import 'package:flutter/services.dart';
import 'package:photo_manager/src/filter/path_filter.dart';

import '../filter/base_filter.dart';
import '../filter/classical/filter_option_group.dart';
import '../types/entity.dart';
import '../types/thumbnail.dart';
import '../types/types.dart';
import '../utils/convert_utils.dart';
import 'constants.dart';
import 'enums.dart';
import 'progress_handler.dart';

PhotoManagerPlugin plugin = PhotoManagerPlugin();

mixin BasePlugin {
  final MethodChannel _channel = const MethodChannel(PMConstants.channelPrefix);
}

/// The plugin class is the core class that call channel's methods.
class PhotoManagerPlugin with BasePlugin, IosPlugin, AndroidPlugin {
  Future<List<AssetPathEntity>> getAssetPathList({
    bool hasAll = true,
    bool onlyAll = false,
    RequestType type = RequestType.common,
    PMFilter? filterOption,
    required PMPathFilter pathFilterOption,
  }) async {
    if (onlyAll) {
      assert(hasAll, 'If only is true, then the hasAll must be not null.');
    }
    filterOption ??= FilterOptionGroup();
    // Avoid filtering live photos when searching for audios.
    if (type == RequestType.audio) {
      if (filterOption is FilterOptionGroup) {
        filterOption.containsLivePhotos = false;
        filterOption.onlyLivePhotos = false;
      }
    }
    if (filterOption is FilterOptionGroup) {
      assert(
        type == RequestType.image || !filterOption.onlyLivePhotos,
        'Filtering only Live Photos is only supported '
        'when the request type contains image.',
      );
    }

    final Map<dynamic, dynamic>? result = await _channel.invokeMethod(
      PMConstants.mGetAssetPathList,
      <String, dynamic>{
        'type': type.value,
        'hasAll': hasAll,
        'onlyAll': onlyAll,
        'option': filterOption.toMap(),
        "pathOption": pathFilterOption.toMap(),
      },
    );
    if (result == null) {
      return <AssetPathEntity>[];
    }
    return ConvertUtils.convertToPathList(
      result.cast<String, dynamic>(),
      type: type,
      filterOption: filterOption,
    );
  }

  Future<PermissionState> requestPermissionExtend(
    PermissionRequestOption requestOption,
  ) async {
    final int result = await _channel.invokeMethod<int>(
      PMConstants.mRequestPermissionExtend,
      requestOption.toMap(),
    ) as int;
    return PermissionState.values[result];
  }

  Future<int> getAssetCountFromPath(AssetPathEntity path) async {
    // Use `assetCount` for Android until we break the API
    // and migrate to `InternalAssetPathEntity`.
    if (Platform.isAndroid) {
      // ignore: deprecated_member_use_from_same_package
      return path.assetCount;
    }
    final int result = await _channel.invokeMethod<int>(
      PMConstants.mGetAssetCountFromPath,
      <String, dynamic>{
        'id': path.id,
        'type': path.type.value,
        'option': path.filterOption.toMap(),
      },
    ) as int;
    return result;
  }

  /// Use pagination to get album content.
  Future<List<AssetEntity>> getAssetListPaged(
    String id, {
    required PMFilter optionGroup,
    int page = 0,
    int size = 15,
    RequestType type = RequestType.common,
  }) async {
    final Map<dynamic, dynamic> result =
        await _channel.invokeMethod<Map<dynamic, dynamic>>(
      PMConstants.mGetAssetListPaged,
      <String, dynamic>{
        'id': id,
        'type': type.value,
        'page': page,
        'size': size,
        'option': optionGroup.toMap(),
      },
    ) as Map<dynamic, dynamic>;
    return ConvertUtils.convertToAssetList(result.cast<String, dynamic>());
  }

  /// Asset in the specified range.
  Future<List<AssetEntity>> getAssetListRange(
    String id, {
    required RequestType type,
    required int start,
    required int end,
    required PMFilter optionGroup,
  }) async {
    final Map<dynamic, dynamic> map =
        await _channel.invokeMethod<Map<dynamic, dynamic>>(
      PMConstants.mGetAssetListRange,
      <String, dynamic>{
        'id': id,
        'type': type.value,
        'start': start,
        'end': end,
        'option': optionGroup.toMap(),
      },
    ) as Map<dynamic, dynamic>;

    return ConvertUtils.convertToAssetList(map.cast<String, dynamic>());
  }

  void _injectParams(
    Map<String, dynamic> params,
    PMProgressHandler? progressHandler,
  ) {
    if (progressHandler != null) {
      params['progressHandler'] = progressHandler.channelIndex;
    }
  }

  /// Get thumbnail of asset id.
  Future<typed_data.Uint8List?> getThumbnail({
    required String id,
    required ThumbnailOption option,
    PMProgressHandler? progressHandler,
  }) {
    final Map<String, dynamic> params = <String, dynamic>{
      'id': id,
      'option': option.toMap(),
    };
    _injectParams(params, progressHandler);
    return _channel.invokeMethod(PMConstants.mGetThumb, params);
  }

  Future<typed_data.Uint8List?> getOriginBytes(
    String id, {
    PMProgressHandler? progressHandler,
  }) {
    final Map<String, dynamic> params = <String, dynamic>{'id': id};
    _injectParams(params, progressHandler);
    return _channel.invokeMethod(PMConstants.mGetOriginBytes, params);
  }

  Future<void> releaseCache() {
    return _channel.invokeMethod(PMConstants.mReleaseMemoryCache);
  }

  Future<String?> getFullFile(
    String id, {
    required bool isOrigin,
    PMProgressHandler? progressHandler,
    int subtype = 0,
  }) async {
    final Map<String, dynamic> params = <String, dynamic>{
      'id': id,
      'isOrigin': isOrigin,
      'subtype': subtype,
    };
    _injectParams(params, progressHandler);
    return _channel.invokeMethod(PMConstants.mGetFullFile, params);
  }

  Future<void> setLog(bool isLog) {
    return _channel.invokeMethod(PMConstants.mLog, isLog);
  }

  Future<void> openSetting() {
    return _channel.invokeMethod(PMConstants.mOpenSetting);
  }

  Future<Map<dynamic, dynamic>?> fetchEntityProperties(String id) {
    return _channel.invokeMethod(
      PMConstants.mFetchEntityProperties,
      <String, dynamic>{'id': id},
    );
  }

  Future<Map<dynamic, dynamic>?> fetchPathProperties(
    String id,
    RequestType type,
    PMFilter optionGroup,
  ) {
    return _channel.invokeMethod(
      PMConstants.mFetchPathProperties,
      <String, dynamic>{
        'id': id,
        'timestamp': 0,
        'type': type.value,
        'option': optionGroup.toMap(),
      },
    );
  }

  /// Return [true] if the invoke succeed.
  Future<bool> notifyChange({required bool start}) async {
    await _channel.invokeMethod(
      PMConstants.mNotify,
      <String, dynamic>{'notify': start},
    );
    return true;
  }

  Future<void> forceOldApi() async {
    assert(Platform.isAndroid);
    if (Platform.isAndroid) {
      return _channel.invokeMethod(PMConstants.mForceOldApi);
    }
  }

  Future<bool> deleteWithId(String id) async {
    final List<String> ids = await deleteWithIds(<String>[id]);
    return ids.contains(id);
  }

  Future<List<String>> deleteWithIds(List<String> ids) async {
    final List<dynamic> deleted = await _channel.invokeMethod<List<dynamic>>(
      PMConstants.mDeleteWithIds,
      <String, dynamic>{'ids': ids},
    ) as List<dynamic>;
    return deleted.cast<String>();
  }

  Future<List<String>> moveToTrash(List<AssetEntity> list) {
    return _channel.invokeMethod(
      PMConstants.mMoveToTrash,
      <String, dynamic>{'ids': list.map((e) => e.id).toList()},
    ).then((value) => value.cast<String>());
  }

  final Map<String, dynamic> onlyAddPermission = <String, dynamic>{
    'onlyAddPermission': true,
  };

  Future<AssetEntity?> saveImage(
    typed_data.Uint8List data, {
    required String? title,
    String? desc,
    String? relativePath,
  }) async {
    final Map<dynamic, dynamic>? result = await _channel.invokeMethod(
      PMConstants.mSaveImage,
      <String, dynamic>{
        'image': data,
        'title': title,
        'desc': desc ?? '',
        'relativePath': relativePath,
        ...onlyAddPermission,
      },
    );
    if (result == null) {
      return null;
    }
    return ConvertUtils.convertMapToAsset(
      result.cast<String, dynamic>(),
      title: title,
    );
  }

  Future<AssetEntity?> saveImageWithPath(
    String path, {
    required String title,
    String? desc,
    String? relativePath,
  }) async {
    final File file = File(path);
    if (!file.existsSync()) {
      assert(false, 'File must exists.');
      return null;
    }
    final Map<dynamic, dynamic>? result = await _channel.invokeMethod(
      PMConstants.mSaveImageWithPath,
      <String, dynamic>{
        'path': path,
        'title': title,
        'desc': desc ?? '',
        'relativePath': relativePath,
        ...onlyAddPermission,
      },
    );
    if (result == null) {
      return null;
    }
    return ConvertUtils.convertMapToAsset(
      result.cast<String, dynamic>(),
      title: title,
    );
  }

  Future<AssetEntity?> saveVideo(
    File file, {
    required String? title,
    String? desc,
    String? relativePath,
  }) async {
    if (!file.existsSync()) {
      assert(false, 'File must exists.');
      return null;
    }
    final Map<dynamic, dynamic>? result = await _channel.invokeMethod(
      PMConstants.mSaveVideo,
      <String, dynamic>{
        'path': file.absolute.path,
        'title': title,
        'desc': desc ?? '',
        'relativePath': relativePath,
        ...onlyAddPermission,
      },
    );
    if (result == null) {
      return null;
    }
    return ConvertUtils.convertMapToAsset(
      result.cast<String, dynamic>(),
      title: title,
    );
  }

  Future<AssetEntity?> saveLivePhoto({
    required File imageFile,
    required File videoFile,
    required String? title,
    String? desc,
    String? relativePath,
  }) async {
    if (!imageFile.existsSync()) {
      assert(false, 'File of the image must exist.');
      return null;
    }
    if (!videoFile.existsSync()) {
      assert(false, 'videoFile must exists.');
      return null;
    }
    final Map<dynamic, dynamic>? result = await _channel.invokeMethod(
      PMConstants.mSaveLivePhoto,
      <String, dynamic>{
        'imagePath': imageFile.absolute.path,
        'videoPath': videoFile.absolute.path,
        'title': title,
        'desc': desc ?? '',
        'relativePath': relativePath,
        ...onlyAddPermission,
      },
    );
    if (result == null) {
      return null;
    }
    return ConvertUtils.convertMapToAsset(
      result.cast<String, dynamic>(),
      title: title,
    );
  }

  /// Check whether the asset has been deleted.
  Future<bool> assetExistsWithId(String id) async {
    final bool? result = await _channel.invokeMethod(
      PMConstants.mAssetExists,
      <String, dynamic>{'id': id},
    );
    return result ?? false;
  }

  Future<String> getSystemVersion() async {
    return await _channel.invokeMethod<String>(
      PMConstants.mSystemVersion,
    ) as String;
  }

  Future<LatLng> getLatLngAsync(AssetEntity entity) async {
    if (Platform.isAndroid) {
      final int version = int.parse(await getSystemVersion());
      if (version >= 29) {
        final Map<dynamic, dynamic>? map = await _channel.invokeMethod(
          PMConstants.mGetLatLngAndroidQ,
          <String, dynamic>{'id': entity.id},
        );

        // 将返回的数据传入map
        return LatLng(
          latitude: map?['lat'] as double?,
          longitude: map?['lng'] as double?,
        );
      }
    }
    return LatLng(latitude: entity.latitude, longitude: entity.longitude);
  }

  Future<String> getTitleAsync(
    AssetEntity entity, {
    int subtype = 0,
  }) async {
    assert(Platform.isAndroid || Platform.isIOS || Platform.isMacOS);
    if (Platform.isAndroid) {
      return entity.title!;
    }
    if (Platform.isIOS || Platform.isMacOS) {
      return await _channel.invokeMethod<String>(
        PMConstants.mGetTitleAsync,
        <String, dynamic>{
          'id': entity.id,
          'subtype': subtype,
        },
      ) as String;
    }
    return '';
  }

  Future<String?> getMediaUrl(AssetEntity entity) {
    return _channel.invokeMethod(
      PMConstants.mGetMediaUrl,
      <String, dynamic>{'id': entity.id, 'type': entity.typeInt},
    );
  }

  Future<List<AssetPathEntity>> getSubPathEntities(
    AssetPathEntity pathEntity,
  ) async {
    final Map<dynamic, dynamic> result =
        await _channel.invokeMethod<Map<dynamic, dynamic>>(
      PMConstants.mGetSubPath,
      <String, dynamic>{
        'id': pathEntity.id,
        'type': pathEntity.type.value,
        'albumType': pathEntity.albumType,
        'option': pathEntity.filterOption.toMap(),
      },
    ) as Map<dynamic, dynamic>;
    final Map<dynamic, dynamic> items = result['list'] as Map<dynamic, dynamic>;
    return ConvertUtils.convertToPathList(
      items.cast<String, dynamic>(),
      type: pathEntity.type,
      filterOption: pathEntity.filterOption,
    );
  }

  Future<AssetEntity?> copyAssetToGallery(
    AssetEntity asset,
    AssetPathEntity pathEntity,
  ) async {
    if (pathEntity.isAll) {
      assert(
        pathEntity.isAll,
        "You can't copy the asset into the album containing all the pictures.",
      );
      return null;
    }
    final Map<dynamic, dynamic>? result = await _channel.invokeMethod(
      PMConstants.mCopyAsset,
      <String, dynamic>{'assetId': asset.id, 'galleryId': pathEntity.id},
    );
    if (result == null) {
      return null;
    }
    return ConvertUtils.convertMapToAsset(
      result.cast<String, dynamic>(),
      title: asset.title,
    );
  }

  Future<bool> iosDeleteCollection(AssetPathEntity path) async {
    final Map<dynamic, dynamic>? result = await _channel.invokeMethod(
      PMConstants.mDeleteAlbum,
      <String, dynamic>{
        'id': path.id,
        'type': path.albumType,
      },
    );
    return result?['errorMsg'] == null;
  }

  Future<bool> favoriteAsset(String id, bool favorite) async {
    final bool? result = await _channel.invokeMethod(
      PMConstants.mFavoriteAsset,
      <String, dynamic>{'id': id, 'favorite': favorite},
    );
    return result == true;
  }

  Future<bool> androidRemoveNoExistsAssets() async {
    final bool? result = await _channel.invokeMethod(
      PMConstants.mRemoveNoExistsAssets,
    );
    return result == true;
  }

  Future<void> ignorePermissionCheck(bool ignore) {
    return _channel.invokeMethod(
      PMConstants.mIgnorePermissionCheck,
      <String, dynamic>{'ignore': ignore},
    );
  }

  Future<void> clearFileCache() {
    return _channel.invokeMethod(PMConstants.mClearFileCache);
  }

  Future<void> cancelCacheRequests() {
    return _channel.invokeMethod(PMConstants.mCancelCacheRequests);
  }

  Future<void> requestCacheAssetsThumbnail(
    List<String> ids,
    ThumbnailOption option,
  ) {
    assert(ids.isNotEmpty);
    return _channel.invokeMethod(
      PMConstants.mRequestCacheAssetsThumb,
      <String, dynamic>{
        'ids': ids,
        'option': option.toMap(),
      },
    );
  }

  Future<void> presentLimited(RequestType type) async {
    assert(Platform.isIOS || Platform.isAndroid);
    if (Platform.isIOS || Platform.isAndroid) {
      return _channel.invokeMethod(PMConstants.mPresentLimited, {
        'type': type.value,
      });
    }
  }

  Future<String?> getMimeTypeAsync(AssetEntity entity) async {
    assert(Platform.isAndroid || Platform.isIOS || Platform.isMacOS);
    if (Platform.isAndroid) {
      return entity.mimeType;
    }
    if (Platform.isIOS || Platform.isMacOS) {
      return _channel.invokeMethod<String>(
        PMConstants.mGetMimeTypeAsync,
        <String, dynamic>{'id': entity.id},
      );
    }
    return null;
  }

  Future<int> getAssetCount({
    PMFilter? filterOption,
    RequestType type = RequestType.common,
  }) {
    final filter = filterOption ?? PMFilter.defaultValue();

    return _channel.invokeMethod<int>(PMConstants.mGetAssetCount, {
      'type': type.value,
      'option': filter.toMap(),
    }).then((v) => v ?? 0);
  }

  Future<List<AssetEntity>> getAssetListWithRange({
    required int start,
    required int end,
    RequestType type = RequestType.common,
    PMFilter? filterOption,
  }) {
    final filter = filterOption ?? PMFilter.defaultValue();
    return _channel.invokeMethod<Map>(PMConstants.mGetAssetsByRange, {
      'type': type.value,
      'start': start,
      'end': end,
      'option': filter.toMap(),
    }).then((value) {
      if (value == null) return [];
      return ConvertUtils.convertToAssetList(
        value.cast<String, dynamic>(),
      );
    });
  }
}

mixin IosPlugin on BasePlugin {
  Future<bool> isLocallyAvailable(String id, {bool isOrigin = false}) async {
    if (Platform.isAndroid) {
      return true;
    }
    final bool result = await _channel.invokeMethod<bool>(
      PMConstants.mIsLocallyAvailable,
      <String, dynamic>{'id': id, 'isOrigin': isOrigin},
    ) as bool;
    return result;
  }

  Future<AssetPathEntity?> iosCreateAlbum(
    String name,
    bool isRoot,
    AssetPathEntity? parent,
  ) async {
    final Map<String, dynamic> map = <String, dynamic>{
      'name': name,
      'isRoot': isRoot,
    };
    if (!isRoot && parent != null) {
      map['folderId'] = parent.id;
    }
    final Map<dynamic, dynamic>? result = await _channel.invokeMethod(
      PMConstants.mCreateAlbum,
      map,
    );
    if (result == null) {
      return null;
    }
    if (result['errorMsg'] != null) {
      return null;
    }
    return AssetPathEntity.fromId(result['id'] as String);
  }

  Future<AssetPathEntity?> iosCreateFolder(
    String name,
    bool isRoot,
    AssetPathEntity? parent,
  ) async {
    final Map<String, dynamic> map = <String, dynamic>{
      'name': name,
      'isRoot': isRoot,
    };
    if (!isRoot && parent != null) {
      map['folderId'] = parent.id;
    }
    final Map<dynamic, dynamic>? result = await _channel.invokeMethod(
      PMConstants.mCreateFolder,
      map,
    );
    if (result == null) {
      return null;
    }
    if (result['errorMsg'] != null) {
      return null;
    }
    return AssetPathEntity.fromId(result['id'] as String, albumType: 2);
  }

  Future<bool> iosRemoveInAlbum(
    List<AssetEntity> entities,
    AssetPathEntity path,
  ) async {
    final Map<dynamic, dynamic>? result = await _channel.invokeMethod(
      PMConstants.mRemoveInAlbum,
      <dynamic, dynamic>{
        'assetId': entities.map((AssetEntity e) => e.id).toList(),
        'pathId': path.id,
      },
    );
    return result?['msg'] == null;
  }
}

mixin AndroidPlugin on BasePlugin {
  Future<bool> androidMoveAssetToPath(
    AssetEntity entity,
    AssetPathEntity target,
  ) async {
    final Map<dynamic, dynamic>? result = await _channel.invokeMethod(
      PMConstants.mMoveAssetToPath,
      <String, dynamic>{'assetId': entity.id, 'albumId': target.id},
    );
    return result != null;
  }

  Future<List<String>> androidColumns() async {
    final result = await _channel.invokeMethod(
      PMConstants.mColumnNames,
    );
    if (result is List<dynamic>) {
      return result.map((e) => e.toString()).toList();
    }
    return result ?? <String>[];
  }
}

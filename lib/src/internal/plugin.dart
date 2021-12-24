import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart';

import '../filter/filter_option_group.dart';
import '../types/entity.dart';
import '../types/thumb_option.dart';
import '../types/types.dart';
import '../utils/convert_utils.dart';
import 'constants.dart';
import 'progress_handler.dart';

final Plugin plugin = Plugin();

/// The plugin class is shield and should not be use directly.
class Plugin with BasePlugin, IosPlugin, AndroidPlugin {
  factory Plugin() => _instance;

  Plugin._();

  static late final Plugin _instance = Plugin._();

  Future<List<AssetPathEntity>> getAllGalleryList({
    required FilterOptionGroup optionGroup,
    RequestType type = RequestType.all,
    bool hasAll = true,
    bool onlyAll = false,
  }) async {
    final Map<dynamic, dynamic>? result = await _channel.invokeMethod(
      PMConstants.mGetGalleryList,
      <String, dynamic>{
        'type': type.value,
        'hasAll': hasAll,
        'onlyAll': onlyAll,
        'option': optionGroup.toMap(),
      },
    );
    if (result == null) {
      return <AssetPathEntity>[];
    }
    return ConvertUtils.convertPath(
      result.cast<String, dynamic>(),
      type: type,
      optionGroup: optionGroup,
    );
  }

  Future<int> requestPermissionExtend(
    PermisstionRequestOption requestOption,
  ) async {
    final int result = await _channel.invokeMethod<int>(
      PMConstants.mRequestPermissionExtend,
      requestOption.toMap(),
    ) as int;
    return result;
  }

  /// Use pagination to get album content.
  Future<List<AssetEntity>> getAssetWithGalleryIdPaged(
    String id, {
    required FilterOptionGroup optionGroup,
    int page = 0,
    int pageCount = 15,
    RequestType type = RequestType.all,
  }) async {
    final Map<dynamic, dynamic> result =
        await _channel.invokeMethod<Map<dynamic, dynamic>>(
      PMConstants.mGetAssetWithGalleryId,
      <String, dynamic>{
        'id': id,
        'page': page,
        'pageCount': pageCount,
        'type': type.value,
        'option': optionGroup.toMap(),
      },
    ) as Map<dynamic, dynamic>;
    return ConvertUtils.convertToAssetList(result.cast<String, dynamic>());
  }

  /// Asset in the specified range.
  Future<List<AssetEntity>> getAssetWithRange(
    String id, {
    required RequestType type,
    required int start,
    required int end,
    required FilterOptionGroup optionGroup,
  }) async {
    final Map<dynamic, dynamic> map =
        await _channel.invokeMethod<Map<dynamic, dynamic>>(
      PMConstants.mGetAssetListWithRange,
      <String, dynamic>{
        'galleryId': id,
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

  /// Get thumb of asset id.
  Future<Uint8List?> getThumb({
    required String id,
    required ThumbOption option,
    PMProgressHandler? progressHandler,
  }) {
    final Map<String, dynamic> params = <String, dynamic>{
      'id': id,
      'option': option.toMap(),
    };
    _injectParams(params, progressHandler);
    return _channel.invokeMethod(PMConstants.mGetThumb, params);
  }

  Future<Uint8List?> getOriginBytes(
    String id, {
    PMProgressHandler? progressHandler,
  }) {
    final Map<String, dynamic> params = <String, dynamic>{'id': id};
    _injectParams(params, progressHandler);
    return _channel.invokeMethod(PMConstants.mGetOriginBytes, params);
  }

  Future<void> releaseCache() {
    return _channel.invokeMethod(PMConstants.mReleaseMemCache);
  }

  Future<String?> getFullFile(
    String id, {
    required bool isOrigin,
    PMProgressHandler? progressHandler,
  }) async {
    final Map<String, dynamic> params = <String, dynamic>{
      'id': id,
      'isOrigin': isOrigin,
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

  Future<Map<dynamic, dynamic>?> fetchPathProperties(
    String id,
    RequestType type,
    FilterOptionGroup optionGroup,
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

  Future<void> notifyChange({required bool start}) {
    return _channel.invokeMethod(
      PMConstants.mNotify,
      <String, dynamic>{'notify': start},
    );
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

  Future<AssetEntity?> saveImage(
    Uint8List data, {
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
      assert(file.existsSync(), 'file must exists');
      return null;
    }
    final Map<dynamic, dynamic>? result = await _channel.invokeMethod(
      PMConstants.mSaveImageWithPath,
      <String, dynamic>{
        'path': path,
        'title': title,
        'desc': desc ?? '',
        'relativePath': relativePath,
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
      assert(file.existsSync(), 'file must exists');
      return null;
    }
    final Map<dynamic, dynamic>? result = await _channel.invokeMethod(
      PMConstants.mSaveVideo,
      <String, dynamic>{
        'path': file.absolute.path,
        'title': title,
        'desc': desc ?? '',
        'relativePath': relativePath,
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

  Future<bool> assetExistsWithId(String id) {
    return _channel.invokeMethod<bool>(
      PMConstants.mAssetExists,
      <String, dynamic>{'id': id},
    ) as Future<bool>;
  }

  Future<String> getSystemVersion() async {
    return _channel.invokeMethod<String>(
      PMConstants.mSystemVersion,
    ) as Future<String>;
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

  Future<bool> cacheOriginBytes(bool cache) async {
    assert(Platform.isAndroid, 'This method only supports Android.');
    final bool result = await _channel.invokeMethod<bool>(
      PMConstants.mCacheOriginBytes,
      cache,
    ) as bool;
    return result == true;
  }

  Future<String> getTitleAsync(AssetEntity entity) async {
    assert(Platform.isAndroid || Platform.isIOS || Platform.isMacOS);
    if (Platform.isAndroid) {
      return entity.title!;
    }
    if (Platform.isIOS || Platform.isMacOS) {
      return await _channel.invokeMethod<String>(
        PMConstants.mGetTitleAsync,
        <String, dynamic>{'id': entity.id},
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
    return ConvertUtils.convertPath(
      items.cast<String, dynamic>(),
      type: pathEntity.type,
      optionGroup: pathEntity.filterOption,
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

  Future<Map<dynamic, dynamic>?> getPropertiesFromAssetEntity(String id) {
    return _channel.invokeMethod(
      PMConstants.mGetPropertiesFromAssetEntity,
      <String, dynamic>{'id': id},
    );
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

  Future<void> requestCacheAssetsThumb(List<String> ids, ThumbOption option) {
    assert(ids.isNotEmpty);
    return _channel.invokeMethod(
      PMConstants.mRequestCacheAssetsThumb,
      <String, dynamic>{
        'ids': ids,
        'option': option.toMap(),
      },
    );
  }

  Future<void> presentLimited() async {
    assert(Platform.isIOS);
    if (Platform.isIOS) {
      return _channel.invokeMethod(PMConstants.mPresentLimited);
    }
  }
}

mixin BasePlugin {
  final MethodChannel _channel = const MethodChannel(PMConstants.channelPrefix);
}

mixin IosPlugin on BasePlugin {
  Future<bool> isLocallyAvailable(String id) async {
    if (Platform.isAndroid) {
      return true;
    }
    final bool result = await _channel.invokeMethod<bool>(
      PMConstants.mIsLocallyAvailable,
      <String, dynamic>{'id': id},
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
    return AssetPathEntity()
      ..id = result['id'] as String
      ..name = name
      ..isAll = false
      ..assetCount = 0
      ..albumType = 1;
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
    return AssetPathEntity()
      ..id = result['id'] as String
      ..name = name
      ..isAll = false
      ..assetCount = 0
      ..albumType = 2;
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
    // Return an entity.
    final Map<dynamic, dynamic>? result = await _channel.invokeMethod(
      PMConstants.mMoveAssetToPath,
      <String, dynamic>{'assetId': entity.id, 'albumId': target.id},
    );
    return result != null;
  }
}

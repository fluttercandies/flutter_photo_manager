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
  Plugin._();

  factory Plugin() => _instance;

  static late final Plugin _instance = Plugin._();

  Future<List<AssetPathEntity>> getAllGalleryList({
    RequestType type = RequestType.all,
    bool hasAll = true,
    bool onlyAll = false,
    required FilterOptionGroup optionGroup,
  }) async {
    final result = await _channel.invokeMethod('getGalleryList', {
      'type': type.value,
      'hasAll': hasAll,
      'onlyAll': onlyAll,
      'option': optionGroup.toMap(),
    });
    if (result == null) {
      return [];
    }
    return ConvertUtils.convertPath(
      result,
      type: type,
      optionGroup: optionGroup,
    );
  }

  Future<int> requestPermissionExtend(
    PermisstionRequestOption requestOption,
  ) async {
    return await _channel.invokeMethod(
      'requestPermissionExtend',
      requestOption.toMap(),
    );
  }

  /// Use pagination to get album content.
  Future<List<AssetEntity>> getAssetWithGalleryIdPaged(
    String id, {
    int page = 0,
    int pageCount = 15,
    RequestType type = RequestType.all,
    required FilterOptionGroup optionGroup,
  }) async {
    final result = await _channel.invokeMethod('getAssetWithGalleryId', {
      'id': id,
      'page': page,
      'pageCount': pageCount,
      'type': type.value,
      'option': optionGroup.toMap(),
    });

    return ConvertUtils.convertToAssetList(result);
  }

  /// Asset in the specified range.
  Future<List<AssetEntity>> getAssetWithRange(
    String id, {
    required RequestType type,
    required int start,
    required int end,
    required FilterOptionGroup optionGroup,
  }) async {
    final Map map = await _channel.invokeMethod('getAssetListWithRange', {
      'galleryId': id,
      'type': type.value,
      'start': start,
      'end': end,
      'option': optionGroup.toMap(),
    });

    return ConvertUtils.convertToAssetList(map);
  }

  void _injectParams(Map params, PMProgressHandler? progressHandler) {
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
    final params = {
      'id': id,
      'option': option.toMap(),
    };
    _injectParams(params, progressHandler);
    return _channel.invokeMethod('getThumb', params);
  }

  Future<Uint8List?> getOriginBytes(
    String id, {
    PMProgressHandler? progressHandler,
  }) {
    final params = {'id': id};
    _injectParams(params, progressHandler);
    return _channel.invokeMethod('getOriginBytes', params);
  }

  Future<void> releaseCache() {
    return _channel.invokeMethod('releaseMemCache');
  }

  Future<String?> getFullFile(
    String id, {
    required bool isOrigin,
    PMProgressHandler? progressHandler,
  }) async {
    final params = {'id': id, 'isOrigin': isOrigin};
    _injectParams(params, progressHandler);
    return _channel.invokeMethod('getFullFile', params);
  }

  Future<void> setLog(bool isLog) {
    return _channel.invokeMethod('log', isLog);
  }

  Future<void> openSetting() {
    return _channel.invokeMethod('openSetting');
  }

  /// Nullable
  Future<Map?> fetchPathProperties(
    String id,
    RequestType type,
    FilterOptionGroup optionGroup,
  ) {
    return _channel.invokeMethod(
      'fetchPathProperties',
      {
        'id': id,
        'timestamp': 0,
        'type': type.value,
        'option': optionGroup.toMap(),
      },
    );
  }

  void notifyChange({required bool start}) {
    _channel.invokeMethod('notify', {'notify': start});
  }

  Future<void> forceOldApi() async {
    await _channel.invokeMethod('forceOldApi');
  }

  Future<bool> deleteWithId(String id) async {
    final ids = await deleteWithIds([id]);
    return ids.contains(id);
  }

  Future<List<String>> deleteWithIds(List<String> ids) async {
    final List<dynamic> deleted =
        (await _channel.invokeMethod('deleteWithIds', {'ids': ids}));
    return deleted.cast<String>();
  }

  Future<AssetEntity?> saveImage(
    Uint8List data, {
    String? title,
    String? desc,
    String? relativePath,
  }) async {
    title ??= 'image_${DateTime.now().millisecondsSinceEpoch / 1000}.jpg';

    final result = await _channel.invokeMethod(
      'saveImage',
      {
        'image': data,
        'title': title,
        'desc': desc ?? '',
        'relativePath': relativePath,
      },
    );

    return ConvertUtils.convertToAsset(result);
  }

  Future<AssetEntity?> saveImageWithPath(
    String path, {
    String? title,
    String? desc,
    String? relativePath,
  }) async {
    final file = File(path);
    if (!file.existsSync()) {
      assert(file.existsSync(), 'file must exists');
      return null;
    }

    title ??= 'image_${DateTime.now().millisecondsSinceEpoch / 1000}.jpg';

    final result = await _channel.invokeMethod(
      'saveImageWithPath',
      {
        'path': path,
        'title': title,
        'desc': desc ?? '',
        'relativePath': relativePath,
      },
    );

    return ConvertUtils.convertToAsset(result);
  }

  Future<AssetEntity?> saveVideo(
    File file, {
    String? title,
    String? desc,
    String? relativePath,
  }) async {
    if (!file.existsSync()) {
      assert(file.existsSync(), 'file must exists');
      return null;
    }
    final result = await _channel.invokeMethod(
      'saveVideo',
      {
        'path': file.absolute.path,
        'title': title,
        'desc': desc ?? '',
        'relativePath': relativePath,
      },
    );
    return ConvertUtils.convertToAsset(result);
  }

  Future<bool> assetExistsWithId(String id) async {
    return await _channel.invokeMethod('assetExists', {'id': id});
  }

  Future<String> getSystemVersion() async {
    return await _channel.invokeMethod('systemVersion');
  }

  Future<LatLng> getLatLngAsync(AssetEntity assetEntity) async {
    if (Platform.isAndroid) {
      final version = int.parse(await getSystemVersion());
      if (version >= 29) {
        final Map? map = await _channel.invokeMethod(
          'getLatLngAndroidQ',
          {'id': assetEntity.id},
        );

        /// 将返回的数据传入map
        return LatLng(latitude: map?['lat'], longitude: map?['lng']);
      }
    }
    return LatLng(
      latitude: assetEntity.latitude,
      longitude: assetEntity.longitude,
    );
  }

  Future<bool> cacheOriginBytes(bool cache) async {
    return (await _channel.invokeMethod("cacheOriginBytes", cache)) == true;
  }

  Future<String> getTitleAsync(AssetEntity assetEntity) async {
    assert(Platform.isAndroid || Platform.isIOS || Platform.isMacOS);
    if (Platform.isAndroid) {
      return assetEntity.title!;
    }

    if (Platform.isIOS || Platform.isMacOS) {
      return await _channel.invokeMethod(
        'getTitleAsync',
        {'id': assetEntity.id},
      );
    }

    return '';
  }

  Future<String?> getMediaUrl(AssetEntity assetEntity) {
    return _channel.invokeMethod('getMediaUrl', {
      'id': assetEntity.id,
      'type': assetEntity.typeInt,
    });
  }

  Future<List<AssetPathEntity>> getSubPathEntities(
    AssetPathEntity pathEntity,
  ) async {
    final result = await _channel.invokeMethod('getSubPath', {
      'id': pathEntity.id,
      'type': pathEntity.type.value,
      'albumType': pathEntity.albumType,
      'option': pathEntity.filterOption.toMap(),
    });

    final items = result['list'];

    return ConvertUtils.convertPath(
      items,
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
        'You don\'t need to copy the asset into the album containing all the pictures.',
      );
      return null;
    }

    final result = await _channel.invokeMethod('copyAsset', {
      'assetId': asset.id,
      'galleryId': pathEntity.id,
    });

    if (result == null) {
      return null;
    }

    return ConvertUtils.convertToAsset(result);
  }

  Future<bool> iosDeleteCollection(AssetPathEntity path) async {
    final result = await _channel.invokeMethod('deleteAlbum', {
      'id': path.id,
      'type': path.albumType,
    });
    if (result['errorMsg'] != null) {
      return false;
    }
    return true;
  }

  Future<bool> favoriteAsset(String id, bool favorite) async {
    return (await _channel.invokeMethod(
          'favoriteAsset',
          {'id': id, 'favorite': favorite},
        )) ==
        true;
  }

  Future<bool> androidRemoveNoExistsAssets() async {
    return (await _channel.invokeMethod('removeNoExistsAssets')) == true;
  }

  Future<Map<String, dynamic>?> getPropertiesFromAssetEntity(String id) {
    return _channel.invokeMethod('getPropertiesFromAssetEntity', {'id': id});
  }

  Future ignorePermissionCheck(bool ignore) async {
    await _channel.invokeMethod('ignorePermissionCheck', {'ignore': ignore});
  }

  Future clearFileCache() => _channel.invokeMethod('clearFileCache');

  Future<void> cancelCacheRequests() =>
      _channel.invokeMethod('cancelCacheRequests');

  Future<void> requestCacheAssetsThumb(
    List<String> ids,
    ThumbOption option,
  ) {
    assert(ids.isNotEmpty);
    return _channel.invokeMethod('requestCacheAssetsThumb', {
      'ids': ids,
      'option': option.toMap(),
    });
  }

  Future<void> presentLimited() async {
    if (Platform.isIOS) {
      await _channel.invokeMethod('presentLimited');
    }
  }
}

mixin BasePlugin {
  final MethodChannel _channel = MethodChannel(PMConstants.channelPrefix);
}

mixin IosPlugin on BasePlugin {
  Future<bool> isLocallyAvailable(String id) async {
    if (Platform.isAndroid) {
      return true;
    }
    return await _channel.invokeMethod('isLocallyAvailable', {'id': id});
  }

  Future<AssetPathEntity?> iosCreateFolder(
    String name,
    bool isRoot,
    AssetPathEntity? parent,
  ) async {
    final map = {
      'name': name,
      'isRoot': isRoot,
    };
    if (!isRoot && parent != null) {
      map['folderId'] = parent.id;
    }
    final result = await _channel.invokeMethod(
      'createFolder',
      map,
    );
    if (result == null) {
      return null;
    }

    if (result['errorMsg'] != null) {
      return null;
    }

    return AssetPathEntity()
      ..id = result['id']
      ..name = name
      ..isAll = false
      ..assetCount = 0
      ..albumType = 2;
  }

  Future<AssetPathEntity?> iosCreateAlbum(
    String name,
    bool isRoot,
    AssetPathEntity? parent,
  ) async {
    final map = {
      'name': name,
      'isRoot': isRoot,
    };
    if (!isRoot && parent != null) {
      map['folderId'] = parent.id;
    }
    final result = await _channel.invokeMethod(
      'createAlbum',
      map,
    );
    if (result == null) {
      return null;
    }

    if (result['errorMsg'] != null) {
      return null;
    }

    return AssetPathEntity()
      ..id = result['id']
      ..name = name
      ..isAll = false
      ..assetCount = 0
      ..albumType = 1;
  }

  Future<bool> iosRemoveInAlbum(
    List<AssetEntity> entities,
    AssetPathEntity path,
  ) async {
    final result = await _channel.invokeMethod(
      'removeInAlbum',
      {
        'assetId': entities.map((e) => e.id).toList(),
        'pathId': path.id,
      },
    );

    if (result['msg'] != null) {
      return false;
    }

    return true;
  }
}

mixin AndroidPlugin on BasePlugin {
  Future<bool> androidMoveAssetToPath(
    AssetEntity entity,
    AssetPathEntity target,
  ) async {
    final result = await _channel.invokeMethod('moveAssetToPath', {
      'assetId': entity.id,
      'albumId': target.id,
    });
    return result != null;
  }
}

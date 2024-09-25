// Copyright 2018 The FlutterCandies author. All rights reserved.
// Use of this source code is governed by an Apache license that can be found
// in the LICENSE file.

import 'dart:async';
import 'dart:io';
import 'dart:typed_data' as typed_data;

import 'package:flutter/services.dart';
import 'package:photo_manager/platform_utils.dart';

import '../filter/base_filter.dart';
import '../filter/classical/filter_option_group.dart';
import '../filter/path_filter.dart';
import '../types/entity.dart';
import '../types/thumbnail.dart';
import '../types/types.dart';
import '../utils/convert_utils.dart';
import 'constants.dart';
import 'enums.dart';
import 'progress_handler.dart';

PhotoManagerPlugin plugin = PhotoManagerPlugin();

mixin BasePlugin {
  MethodChannel _channel = const MethodChannel(PMConstants.channelPrefix);

  final Map<String, dynamic> onlyAddPermission = <String, dynamic>{
    'onlyAddPermission': true,
  };
}

class VerboseLogMethodChannel extends MethodChannel {
  VerboseLogMethodChannel({
    required String name,
    required this.logFilePath,
  }) : super(name);

  final String logFilePath;

  int index = 0;

  @override
  Future<T?> invokeMethod<T>(String method, [arguments]) async {
    final channelIndex = index;
    index++;
    final sw = Stopwatch()..start();
    logVerboseStart(index: channelIndex, method: method);
    final result = await super.invokeMethod(method, arguments);
    sw.stop();
    logVerbose(
      index: channelIndex,
      method: method,
      args: arguments,
      result: result,
      stopwatch: sw,
    );
    return result;
  }

  void _writeLog(String log) {
    // write log to file
    final file = File(logFilePath);
    const splitter = '===';
    file.writeAsStringSync(
      '$log\n$splitter\n',
      mode: FileMode.append,
    );
  }

  String _formatArgs(args) {
    if (args == null) {
      return 'null';
    }
    if (args is Map) {
      final String res = args.keys.map((key) {
        final value = args[key];
        return '$key: ${_formatArgs(value)}';
      }).join(', ');
      return 'Map{ $res }';
    }
    if (args is Uint8List || args is List<int>) {
      return 'IntList(${args.length})';
    }
    if (args is List) {
      if (args.isEmpty) {
        return 'List(empty)';
      }
      final type = args.first.runtimeType;
      return 'List(${args.length})<$type>';
    }
    return args.toString();
  }

  void logVerboseStart({
    required int index,
    required String method,
  }) {
    final log = '''#$index - invoke - $method
  Method: $method
    ''';

    _writeLog(log);
  }

  void logVerbose({
    required int index,
    required String method,
    required args,
    required result,
    required Stopwatch stopwatch,
  }) {
    final log = '''#$index - result - $method
  Time: ${stopwatch.elapsedMilliseconds}ms
  Args: ${_formatArgs(args)}
  Result: ${_formatArgs(args)}
    ''';

    _writeLog(log);
  }
}

/// The plugin class is the core class that call channel's methods.
class PhotoManagerPlugin with BasePlugin, IosPlugin, AndroidPlugin, OhosPlugin {
  void setVerbose(bool isVerbose, String logPath) {
    if (isVerbose) {
      _channel = VerboseLogMethodChannel(
        name: PMConstants.channelPrefix,
        logFilePath: logPath,
      );
    } else {
      _channel = const MethodChannel(PMConstants.channelPrefix);
    }
  }

  Future<List<AssetPathEntity>> getAssetPathList({
    bool hasAll = true,
    bool onlyAll = false,
    RequestType type = RequestType.common,
    PMFilter? filterOption,
    required PMPathFilter pathFilterOption,
  }) async {
    if (onlyAll) {
      hasAll = true;
    }
    filterOption ??= FilterOptionGroup();
    final Map result = await _channel.invokeMethod(
      PMConstants.mGetAssetPathList,
      <String, dynamic>{
        'type': type.value,
        'hasAll': hasAll,
        'onlyAll': onlyAll,
        'option': filterOption.toMap(),
        'pathOption': pathFilterOption.toMap(),
      },
    );
    return ConvertUtils.convertToPathList(
      result.cast(),
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

  void _injectProgressHandlerParams(
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
    _injectProgressHandlerParams(params, progressHandler);
    return _channel.invokeMethod(PMConstants.mGetThumb, params);
  }

  Future<typed_data.Uint8List?> getOriginBytes(
    String id, {
    PMProgressHandler? progressHandler,
    PMDarwinAVFileType? darwinFileType,
  }) {
    final Map<String, dynamic> params = <String, dynamic>{
      'id': id,
      'darwinFileType': darwinFileType,
    };
    _injectProgressHandlerParams(params, progressHandler);
    return _channel.invokeMethod(PMConstants.mGetOriginBytes, params);
  }

  Future<void> releaseCache() async {
    if (PlatformUtils.isOhos) {
      return;
    }
    return _channel.invokeMethod(PMConstants.mReleaseMemoryCache);
  }

  Future<String?> getFullFile(
    String id, {
    required bool isOrigin,
    PMProgressHandler? progressHandler,
    int subtype = 0,
    PMDarwinAVFileType? darwinFileType,
  }) async {
    final Map<String, dynamic> params = <String, dynamic>{
      'id': id,
      'isOrigin': isOrigin,
      'subtype': subtype,
      'darwinFileType': darwinFileType?.value ?? 0,
    };
    _injectProgressHandlerParams(params, progressHandler);
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

  Future<AssetEntity?> saveImage(
    typed_data.Uint8List data, {
    required String filename,
    String? title,
    String? desc,
    String? relativePath,
    int? orientation,
  }) async {
    _throwIfOrientationInvalid(orientation);
    final Map<dynamic, dynamic>? result = await _channel.invokeMethod(
      PMConstants.mSaveImage,
      <String, dynamic>{
        'image': data,
        'filename': filename,
        'title': title,
        'desc': desc,
        'relativePath': relativePath,
        'orientation': orientation,
        ...onlyAddPermission,
      },
    );
    if (result == null) {
      return null;
    }
    return ConvertUtils.convertMapToAsset(
      result.cast<String, dynamic>(),
      title: filename,
    );
  }

  Future<AssetEntity?> saveImageWithPath(
    String filePath, {
    String? title,
    String? desc,
    String? relativePath,
    int? orientation,
  }) async {
    _throwIfOrientationInvalid(orientation);
    final File file = File(filePath);
    if (!file.existsSync()) {
      throw ArgumentError('$filePath does not exists');
    }
    final Map<dynamic, dynamic>? result = await _channel.invokeMethod(
      PMConstants.mSaveImageWithPath,
      <String, dynamic>{
        'path': file.absolute.path,
        'title': title,
        'desc': desc,
        'relativePath': relativePath,
        'orientation': orientation,
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
    String? title,
    String? desc,
    String? relativePath,
    int? orientation,
  }) async {
    _throwIfOrientationInvalid(orientation);
    if (!file.existsSync()) {
      throw ArgumentError('${file.path} does not exists');
    }
    final Map<dynamic, dynamic>? result = await _channel.invokeMethod(
      PMConstants.mSaveVideo,
      <String, dynamic>{
        'path': file.absolute.path,
        'title': title,
        'desc': desc ?? '',
        'relativePath': relativePath,
        'orientation': orientation,
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
    if (PlatformUtils.isOhos) {
      return '';
    }
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
    bool isOrigin = true,
    int subtype = 0,
    PMDarwinAVFileType? darwinFileType,
  }) async {
    if (Platform.isIOS || Platform.isMacOS) {
      return await _channel.invokeMethod(
        PMConstants.mGetTitleAsync,
        <String, dynamic>{
          'id': entity.id,
          'subtype': subtype,
          'isOrigin': isOrigin,
          'darwinFileType': darwinFileType?.value ?? 0,
        },
      ) as String;
    }
    return entity.title ?? '';
  }

  Future<String?> getMediaUrl(
    AssetEntity entity, {
    PMProgressHandler? progressHandler,
  }) async {
    if (PlatformUtils.isOhos) {
      return entity.id;
    }
    final params = <String, dynamic>{
      'id': entity.id,
      'type': entity.typeInt,
    };
    _injectProgressHandlerParams(params, progressHandler);
    return _channel.invokeMethod(PMConstants.mGetMediaUrl, params);
  }

  Future<List<AssetPathEntity>> getSubPathEntities(
    AssetPathEntity pathEntity,
  ) async {
    if (PlatformUtils.isOhos) {
      return <AssetPathEntity>[];
    }
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
      throw ArgumentError(
        'Cannot copy into the album containing all the assets.',
      );
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

  Future<bool> favoriteAsset(String id, bool favorite) async {
    final bool? result = await _channel.invokeMethod(
      PMConstants.mFavoriteAsset,
      <String, dynamic>{'id': id, 'favorite': favorite},
    );
    return result == true;
  }

  Future<void> ignorePermissionCheck(bool ignore) {
    return _channel.invokeMethod(
      PMConstants.mIgnorePermissionCheck,
      <String, dynamic>{'ignore': ignore},
    );
  }

  Future<void> clearFileCache() async {
    if (PlatformUtils.isOhos) {
      return;
    }
    return _channel.invokeMethod(PMConstants.mClearFileCache);
  }

  Future<void> cancelCacheRequests() {
    return _channel.invokeMethod(PMConstants.mCancelCacheRequests);
  }

  Future<void> requestCacheAssetsThumbnail(
    List<String> ids,
    ThumbnailOption option,
  ) async {
    if (PlatformUtils.isOhos) {
      return;
    }
    if (ids.isEmpty) {
      throw ArgumentError('Empty IDs are not allowed');
    }
    return _channel.invokeMethod(
      PMConstants.mRequestCacheAssetsThumb,
      <String, dynamic>{
        'ids': ids,
        'option': option.toMap(),
      },
    );
  }

  Future<void> presentLimited(RequestType type) async {
    if (Platform.isIOS || Platform.isAndroid) {
      return _channel.invokeMethod(PMConstants.mPresentLimited, {
        'type': type.value,
      });
    }
  }

  Future<String?> getMimeTypeAsync(AssetEntity entity) async {
    if (Platform.isAndroid || PlatformUtils.isOhos) {
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
      if (value == null) {
        return [];
      }
      return ConvertUtils.convertToAssetList(
        value.cast<String, dynamic>(),
      );
    });
  }

  Future<bool> isLocallyAvailable(
    String id, {
    bool isOrigin = false,
    int subtype = 0,
    PMDarwinAVFileType? darwinFileType,
  }) async {
    if (Platform.isIOS || Platform.isMacOS) {
      final bool result = await _channel.invokeMethod<bool>(
        PMConstants.mIsLocallyAvailable,
        <String, dynamic>{
          'id': id,
          'isOrigin': isOrigin,
          'subtype': subtype,
          'darwinFileType': darwinFileType?.value ?? 0,
        },
      ) as bool;
      return result;
    }

    return true;
  }

  String? getVerboseFilePath() {
    if (plugin._channel is VerboseLogMethodChannel) {
      return (plugin._channel as VerboseLogMethodChannel).logFilePath;
    }

    return null;
  }

  Future<PermissionState> getPermissionState(
    PermissionRequestOption requestOption,
  ) async {
    final int result = await _channel.invokeMethod(
      PMConstants.mGetPermissionState,
      requestOption.toMap(),
    );
    return PermissionState.values[result];
  }
}

mixin IosPlugin on BasePlugin {
  Future<AssetEntity?> saveLivePhoto({
    required File imageFile,
    required File videoFile,
    required String? title,
    String? desc,
    String? relativePath,
  }) async {
    assert(Platform.isIOS || Platform.isMacOS);
    if (!imageFile.existsSync()) {
      throw ArgumentError('The image file does not exists');
    }
    if (!videoFile.existsSync()) {
      throw ArgumentError('The video file does not exists');
    }
    final Map result = await _channel.invokeMethod(
      PMConstants.mSaveLivePhoto,
      <String, dynamic>{
        'imagePath': imageFile.absolute.path,
        'videoPath': videoFile.absolute.path,
        'title': title,
        'desc': desc,
        'relativePath': relativePath,
        ...onlyAddPermission,
      },
    );
    return ConvertUtils.convertMapToAsset(result.cast(), title: title);
  }

  Future<AssetPathEntity?> iosCreateAlbum(
    String name,
    bool isRoot,
    AssetPathEntity? parent,
  ) async {
    assert(Platform.isIOS || Platform.isMacOS);
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
    assert(Platform.isIOS || Platform.isMacOS);
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
    assert(Platform.isIOS || Platform.isMacOS);
    final Map<dynamic, dynamic>? result = await _channel.invokeMethod(
      PMConstants.mRemoveInAlbum,
      <dynamic, dynamic>{
        'assetId': entities.map((AssetEntity e) => e.id).toList(),
        'pathId': path.id,
      },
    );
    return result?['msg'] == null;
  }

  Future<bool> iosDeleteCollection(AssetPathEntity path) async {
    assert(Platform.isIOS || Platform.isMacOS);
    final Map<dynamic, dynamic>? result = await _channel.invokeMethod(
      PMConstants.mDeleteAlbum,
      <String, dynamic>{
        'id': path.id,
        'type': path.albumType,
      },
    );
    return result?['errorMsg'] == null;
  }
}

mixin AndroidPlugin on BasePlugin {
  Future<void> forceOldApi() async {
    assert(Platform.isAndroid);
    if (Platform.isAndroid) {
      return _channel.invokeMethod(PMConstants.mForceOldApi);
    }
  }

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

  Future<bool> androidRemoveNoExistsAssets() async {
    final bool? result = await _channel.invokeMethod(
      PMConstants.mRemoveNoExistsAssets,
    );
    return result == true;
  }

  Future<List<String>> androidColumns() async {
    final List result = await _channel.invokeMethod(
      PMConstants.mColumnNames,
    );
    return result.map((e) => e.toString()).toList();
  }
}

mixin OhosPlugin on BasePlugin {
  Future<List<String>> ohosColumns() async {
    final List result = await _channel.invokeMethod(
      PMConstants.mColumnNames,
    );
    return result.map((e) => e.toString()).toList();
  }
}

void _throwIfOrientationInvalid(int? value) {
  if (value == null ||
      value == 0 ||
      value == 90 ||
      value == 180 ||
      value == 270) {
    return;
  }
  throw ArgumentError(
    'The given orientation is invalid, '
    'allowed values are 0, 90, 180, 270, and null.',
  );
}

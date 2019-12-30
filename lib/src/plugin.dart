import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager/src/utils/convert_utils.dart';

class Plugin {
  static const MethodChannel _channel =
      const MethodChannel('top.kikt/photo_manager');

  static DateTime _createDefaultFetchDatetime() {
    return DateTime.now();
  }

  static Plugin _plugin;

  factory Plugin() {
    _plugin ??= Plugin._();
    return _plugin;
  }

  Plugin._();

  /// [type] 0 : all , 1: image ,2 video
  Future<List<AssetPathEntity>> getAllGalleryList({
    int type = 0,
    DateTime dt,
    bool hasAll = true,
  }) async {
    dt ??= _createDefaultFetchDatetime();

    final result = await _channel.invokeMethod("getGalleryList", {
      "type": type,
      "timestamp": dt.millisecondsSinceEpoch,
      "hasAll": hasAll,
    });
    if (result == null) {
      return [];
    }
    return ConvertUtils.convertPath(result, type: type, dt: dt);
  }

  Future<bool> requestPermission() async {
    return (await _channel.invokeMethod("requestPermission")) == 1;
  }

  Future<List<AssetEntity>> getAssetWithGalleryIdPaged(
    String id, {
    int page = 0,
    int pageCount = 15,
    int type = 0,
    DateTime pagedDt,
  }) async {
    pagedDt ??= _createDefaultFetchDatetime();

    final result = await _channel.invokeMethod("getAssetWithGalleryId", {
      "id": id,
      "page": page,
      "pageCount": pageCount,
      "type": type,
      "timestamp": pagedDt.millisecondsSinceEpoch,
    });

    return ConvertUtils.convertToAssetList(result);
  }

  Future<Uint8List> getThumb({
    @required String id,
    int width = 100,
    int height = 100,
  }) {
    return _channel.invokeMethod("getThumb", {
      "width": width,
      "height": height,
      "id": id,
    });
  }

  Future<Uint8List> getOriginBytes(String id) async {
    final path = await getFullFile(id, isOrigin: true);
    if (path == null) {
      return null;
    }
    final file = File(path);
    if (!file.existsSync()) {
      return null;
    } else {
      return Uint8List.fromList(file.readAsBytesSync());
    }
  }

  Future<void> releaseCache() async {
    await _channel.invokeMethod("releaseMemCache");
  }

  Future<String> getFullFile(String id, {bool isOrigin}) async {
    return _channel.invokeMethod("getFullFile", {
      "id": id,
      "isOrigin": isOrigin,
    });
  }

  Future<void> setLog(bool isLog) async {
    return _channel.invokeMethod("log", isLog);
  }

  void openSetting() {
    _channel.invokeMethod("openSetting");
  }

  Future<Map> fetchPathProperties(
      String id, int type, DateTime datetime) async {
    datetime ??= _createDefaultFetchDatetime();
    return _channel.invokeMethod(
      "fetchPathProperties",
      {
        "id": id,
        "timestamp": datetime.millisecondsSinceEpoch,
        "type": type,
      },
    );
  }

  void notifyChange({bool start}) {
    _channel.invokeMethod("notify", {
      "notify": start,
    });
  }

  bool androidQExperimental = false;

  Future<void> setAndroidQExperimental(bool open) async {
    if (Platform.isAndroid) {
      await _channel.invokeMethod("androidQExperimental", {
        "open": open,
      });
      androidQExperimental = open;
    }
  }

  Future<void> forceOldApi() async {
    await _channel.invokeMethod("forceOldApi");
  }

  Future<bool> deleteWithId(String id) async {
    final ids = await deleteWithIds([id]);
    return ids.contains(id);
  }

  Future<List<String>> deleteWithIds(List<String> ids) async {
    final List<dynamic> deleted =
        (await _channel.invokeMethod("deleteWithIds", {"ids": ids}));
    return deleted.cast<String>();
  }

  Future<List<AssetEntity>> getAssetWithRange(
    String id,
    int typeInt,
    int start,
    int end,
    DateTime fetchDt,
  ) async {
    final Map map = await _channel.invokeMethod("getAssetListWithRange", {
      "galleryId": id,
      "type": typeInt,
      "start": start,
      "end": end,
      "timestamp": fetchDt.millisecondsSinceEpoch,
    });

    return ConvertUtils.convertToAssetList(map);
  }

  Future<AssetEntity> saveImage(Uint8List uint8list,
      {String title, String desc = ""}) async {
    title ??= "image_${DateTime.now().millisecondsSinceEpoch / 1000}";

    final result = await _channel.invokeMethod(
      "saveImage",
      {
        "image": uint8list,
        "title": title,
        "desc": desc,
      },
    );

    return ConvertUtils.convertToAsset(result);
  }

  Future<AssetEntity> saveVideo(File file,
      {String title, String desc = ""}) async {
    if (file.existsSync()) {
      return null;
    }
    final result = await _channel.invokeMethod(
      "saveVideo",
      {
        "path": file.absolute.path,
        "title": title,
        "desc": desc,
      },
    );
    return ConvertUtils.convertToAsset(result);
  }

  Future<bool> assetExistsWithId(String id) {
    return _channel.invokeMethod("assetExists", {"id": id});
  }
}

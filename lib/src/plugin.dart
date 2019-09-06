import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager/src/utils/convert_utils.dart';

class Plugin {
  static const MethodChannel _channel =
      const MethodChannel('top.kikt/photo_manager');

  static Plugin _plugin;

  factory Plugin() {
    _plugin ??= Plugin._();
    return _plugin;
  }

  Plugin._();

  /// [type] 0 : all , 1: image ,2 video
  Future<List<AssetPathEntity>> getAllGalleryList({int type = 0}) async {
    final result =
        await _channel.invokeMethod("getGalleryList", {"type": type});
    if (result == null) {
      return [];
    }
    return ConvertUtils.convertPath(result, type: type);
  }

  Future<bool> requestPermission() async {
    return (await _channel.invokeMethod("requestPermission")) == 1;
  }

  Future<List<AssetEntity>> getAssetWithGalleryIdPaged(
    String id, {
    int page = 0,
    int pageCount = 15,
    int type = 0,
  }) async {
    print("type = $type");
    final result = await _channel.invokeMethod("getAssetWithGalleryId", {
      "id": id,
      "page": page,
      "pageCount": pageCount,
      "type": type,
    });

    return ConvertUtils.convertAssetEntity(result);
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

  Future<Uint8List> getOriginBytes(String id) {
    return _channel.invokeMethod("getOrigin", {
      "id": id,
    });
  }

  Future<void> releaseCache() async {
    await _channel.invokeMethod("releaseMemCache");
  }

  Future<String> getFullFile(String id, {bool isOrigin}) async {
    return _channel
        .invokeMethod("getFullFile", {"id": id, "isOrigin": isOrigin});
  }

  Future<void> setLog(bool isLog) async {
    return _channel.invokeMethod("log", isLog);
  }

  void openSetting() {
    _channel.invokeMethod("openSetting");
  }
}

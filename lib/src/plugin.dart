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
    if (Platform.isAndroid) {
      final file = File(id);
      if (file.existsSync()) {
        return id;
      } else {
        return null;
      }
    }

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

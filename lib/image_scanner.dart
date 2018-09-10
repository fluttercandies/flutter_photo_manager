import 'dart:async';

import 'package:flutter/services.dart';

class ImageScanner {
  static const MethodChannel _channel = const MethodChannel('image_scanner');

  static Future<List<ImageParentPath>> getImagePathIdList() async {
    List list = await _channel.invokeMethod('getImageIdList');
    if (list == null) {
      return [];
    }

    return _getPathList(list.map((v) => v.toString()).toList());
  }

  static Future<List<ImageParentPath>> _getPathList(List<String> idList) async {
    var list = await _channel.invokeMethod("getImagePathList", idList);
    List<ImageParentPath> result = [];
    for (var i = 0; i < idList.length; i++) {
      result.add(ImageParentPath(id: idList[i], name: list[i].toString()));
    }

    return result;
  }

  static Future<List<ImageEntity>> getImageList(ImageParentPath path) async {
    List list = await _channel.invokeMethod("getImageListWithPathId", path.id);
    return list.map((v) => ImageEntity(path: v.toString())).toList();
  }

  static Future<List<String>> getThumbList(ImageParentPath path) async {
    List list = await _channel.invokeMethod("getImageThumbListWithPathId", path.id);
    return list.map((v) => v?.toString() ?? null).toList();
  }

  static Future<String> getThumbPath(String path) async {
    var thumb = await _channel.invokeMethod("getThumbPath", path);
    if (thumb == null) {
      return null;
    }
    return thumb;
  }
}

class ImageEntity {
  String path;
  Future<String> get thumb async => ImageScanner.getThumbPath(path);

  ImageEntity({this.path});
}

class ImageParentPath {
  String id;
  String name;

  ImageParentPath({this.id, this.name});
}

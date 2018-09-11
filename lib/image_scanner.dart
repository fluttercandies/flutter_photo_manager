import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';

class ImageScanner {
  static const MethodChannel _channel = const MethodChannel('image_scanner');

  /// get gallery list
  ///
  /// 获取相册"文件夹" 列表
  static Future<List<ImageParentPath>> getImagePathList() async {
    /// 获取id 列表
    List list = await _channel.invokeMethod('getImageIdList');
    if (list == null) {
      return [];
    }

    return _getPathList(list.map((v) => v.toString()).toList());
  }

  static Future<List<ImageParentPath>> _getPathList(List<String> idList) async {
    /// 获取文件夹列表,这里主要是获取相册名称
    var list = await _channel.invokeMethod("getImagePathList", idList);
    List<ImageParentPath> result = [];
    for (var i = 0; i < idList.length; i++) {
      result.add(ImageParentPath(id: idList[i], name: list[i].toString()));
    }

    return result;
  }

  /// get image entity with path
  ///
  /// 获取指定相册下的所有内容
  static Future<List<ImageEntity>> getImageList(ImageParentPath path) async {
    List list = await _channel.invokeMethod("getImageListWithPathId", path.id);
    return list.map((v) => ImageEntity(id: v.toString())).toList();
  }

  /// get thumb path with img id
  ///
  /// 通过文件的完整路径获取缩略图路径
  static Future<File> _getThumbWithId(String id) async {
    var thumb = await _channel.invokeMethod("getThumbPath", id);
    if (thumb == null) {
      return null;
    }
    return File(thumb);
  }

  static Future<File> _getFullFileWithId(String id) async {
    if (Platform.isAndroid) {
      return File(id);
    } else if (Platform.isIOS) {
      var path = await _channel.invokeMethod("getFullFileWithId");
      if (path == null) {
        return null;
      }
      return File(path);
    }
    return null;
  }

  static Future<List<int>> _getDataWithId(String id) async {
    if (Platform.isAndroid) {
      return File(id).readAsBytes();
    } else if (Platform.isIOS) {
      List<dynamic> bytes = await _channel.invokeMethod("getFullFileWithId");
      if (bytes == null) {
        return null;
      }
      return bytes.map((v) {
        if (v is int) {
          return v;
        }
        return 0;
      }).toList();
    }
    return null;
  }
}

/// image entity
class ImageEntity {
  /// in android is full path
  ///
  /// in ios is asset id
  String id;

  /// thumb path
  ///
  /// you can use File(path) to use
  Future<File> get thumb async => ImageScanner._getThumbWithId(id);

  /// if you need update ,then you can use the file
  Future<File> get file async => ImageScanner._getFullFileWithId(id);

  /// the image's bytes
  Future<List<int>> get fullData => ImageScanner._getDataWithId(id);

  ImageEntity({this.id});
}

/// Gallery Id
class ImageParentPath {
  /// id
  ///
  /// in ios is localIdentifier
  ///
  /// in android is content provider database _id column
  String id;

  /// name
  ///
  /// in android is path name
  ///
  /// in ios is photos gallery name
  String name;

  ImageParentPath({this.id, this.name});
}

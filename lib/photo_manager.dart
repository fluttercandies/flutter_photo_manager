import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/services.dart';

/// asset type
///
/// 用于资源类型属性
enum AssetType {
  /// not image or video
  ///
  /// 不是图片 也不是视频
  other,

  /// image
  image,

  /// video
  video,
}

/// use the class method to help user load asset list and asset info.
class PhotoManager {
  static const MethodChannel _channel = const MethodChannel('image_scanner');

  /// in android WRITE_EXTERNAL_STORAGE  READ_EXTERNAL_STORAGE
  ///
  /// in ios request the photo permission
  static Future<bool> requestPermission() async {
    var result = await _channel.invokeMethod("requestPermission");
    return result == 1;
  }

  /// get gallery list
  ///
  /// 获取相册"文件夹" 列表
  ///
  /// [hasAll] contains all path
  /// [hasAll] 包含所有文件
  ///
  /// [hasVideo] contains video
  /// [hasVideo] 包含视频
  ///
  static Future<List<AssetPathEntity>> getAssetPathList({
    bool hasAll = true,
    bool hasVideo = true,
  }) async {
    /// 获取id 列表
    List list = await _channel.invokeMethod('getGalleryIdList');
    if (list == null) {
      return [];
    }

    List<AssetPathEntity> pathList = await _getPathList(
      list.map((v) => v.toString()).toList(),
      hasVideo: hasVideo,
    );

    if (hasAll == true) {
      AssetPathEntity.all.hasVideo = hasVideo;
      pathList.insert(0, AssetPathEntity.all);
    }

    return pathList;
  }

  /// get video asset
  ///
  /// 获取视频列表
  static Future<List<AssetPathEntity>> getVideoAsset({bool hasAll = true}) async {
    List<AssetPathEntity> pathList = [];
    List idsResult = await _channel.invokeMethod("getVideoPathList");
    List<String> ids = idsResult.cast();
    // print(ids);
    List<String> names = (await _channel.invokeMethod("getGalleryNameList", ids) as List).cast();

    for (var i = 0; i < ids.length; i++) {
      var path = AssetPathEntity();
      path.id = ids[i];
      path.name = names[i];
      path.onlyVideo = true;
      path.hasVideo = true;
      pathList.add(path);
    }

    if (hasAll == true) {
      pathList.insert(0, AssetPathEntity._allVideo);
    }

    return pathList;
  }

  /// get image asset
  ///
  /// 获取图片列表
  static Future<List<AssetPathEntity>> getImageAsset({bool hasAll = true}) async {
    List<AssetPathEntity> pathList = [];
    List idsResult = await _channel.invokeMethod("getImagePathList");
    List<String> ids = idsResult.cast();
    // print(ids);
    List<String> names = (await _channel.invokeMethod("getGalleryNameList", ids) as List).cast();

    for (var i = 0; i < ids.length; i++) {
      var path = AssetPathEntity();
      path.id = ids[i];
      path.name = names[i];
      path.onlyImage = true;
      pathList.add(path);
    }
    if (hasAll == true) {
      pathList.insert(0, AssetPathEntity._allImage);
    }

    return pathList;
  }

  /// open setting page
  static void openSetting() {
    _channel.invokeMethod("openSetting");
  }

  static Future<List<AssetPathEntity>> _getPathList(List<String> idList, {bool hasVideo}) async {
    hasVideo ??= true;

    /// 获取文件夹列表,这里主要是获取相册名称
    var list = await _channel.invokeMethod("getGalleryNameList", idList);

    List<AssetPathEntity> result = [];
    for (var i = 0; i < idList.length; i++) {
      var entity = AssetPathEntity(
        id: idList[i],
        name: list[i].toString(),
        hasVideo: hasVideo,
      );
      result.add(entity);
    }

    return result;
  }

  static AssetType _convertTypeFromString(String type) {
    // print("type = $type");
    try {
      var intType = int.tryParse(type) ?? 0;
      return AssetType.values[intType];
    } on Exception {
      return AssetType.other;
    }
  }

  /// get image entity with path
  ///
  /// 获取指定相册下的所有内容
  static Future<List<AssetEntity>> _getAssetList(AssetPathEntity path) async {
    List<dynamic> list;
    if (path.onlyVideo) {
      path.hasVideo = true;
      if (path.isAll) {
        list = await _channel.invokeMethod("getAllVideo");
        return _castAsset(list, AssetType.video);
      } else {
        list = await _channel.invokeMethod("getOnlyVideoWithPathId", path.id);
        return _castAsset(list, AssetType.video);
      }
    } else if (path.onlyImage) {
      if (path.isAll) {
        list = await _channel.invokeMethod("getAllImage");
        return _castAsset(list, AssetType.image);
      } else {
        list = await _channel.invokeMethod("getOnlyImageWithPathId", path.id);
        return _castAsset(list, AssetType.image);
      }
    } else {
      if (path.isAll == true) {
        list = await _channel.invokeMethod("getAllImageList");
      } else {
        list = await _channel.invokeMethod("getImageListWithPathId", path.id);
      }
    }
    var entityList = list.map((v) => AssetEntity(id: v.toString())).toList();
    await _fetchType(entityList);
    return _filterType(entityList, path.hasVideo == true);
  }

  static List<AssetEntity> _castAsset(List<dynamic> ids, AssetType type) {
    return ids.map((v) {
      return AssetEntity(id: v.toString())..type = type;
    }).toList();
  }

  static List<AssetEntity> _filterType(List<AssetEntity> list, bool hasVideo) {
    hasVideo ??= true;

    return list.where((it) {
      if (it.type == AssetType.image) {
        return true;
      } else {
        return it.type == AssetType.video && hasVideo;
      }
    }).toList();
  }

  static Future _fetchType(List<AssetEntity> entityList) async {
    var ids = entityList.map((v) => v.id).toList();
    List typeList = await _channel.invokeMethod("getAssetTypeWithIds", ids);

    for (var i = 0; i < typeList.length; i++) {
      var entity = entityList[i];
      entity.type = _convertTypeFromString(typeList[i]);
    }
  }

  static Future<File> _getFullFileWithId(String id) async {
    if (Platform.isAndroid) {
      return File(id);
    } else if (Platform.isIOS) {
      var path = await _channel.invokeMethod("getFullFileWithId", id);
      if (path == null) {
        return null;
      }
      return File(path);
    }
    return null;
  }

  static Future<Uint8List> _getDataWithId(String id) async {
    if (Platform.isAndroid) {
      return Uint8List.fromList(File(id).readAsBytesSync());
    } else if (Platform.isIOS) {
      List<dynamic> bytes = await _channel.invokeMethod("getBytesWithId", id);
      if (bytes == null) {
        return null;
      }
      List<int> l = bytes.map((v) {
        if (v is int) {
          return v;
        }
        return 0;
      }).toList();

      return Uint8List.fromList(l);
    }
    return null;
  }

  static Future<Uint8List> _getThumbDataWithId(
    String id, {
    int width = 64,
    int height = 64,
  }) async {
    Completer<Uint8List> completer = Completer();
    Future.delayed(Duration.zero, () async {
      var result = await _channel.invokeMethod("getThumbBytesWithId", [id, width.toString(), height.toString()]);
      if (result is Uint8List) {
        completer.complete(result);
      } else if (result is List<dynamic>) {
        List<int> l = result.map((v) {
          if (v is int) {
            return v;
          }
          return 0;
        }).toList();
        completer.complete(Uint8List.fromList(l));
      } else {
        print("loading image error");
        completer.completeError("load image error");
      }
    });

    return completer.future;
  }

  static Future<bool> _isCloudWithAsset(AssetEntity assetEntity) async {
    if (Platform.isAndroid) {
      return false;
    }
    if (Platform.isIOS) {
      var isICloud = await _channel.invokeMethod("isCloudWithImageId", assetEntity.id);
      return isICloud == "1";
    }
    return null;
  }

  static Future<Duration> _getDurationWithId(String id) async {
    int second = await _channel.invokeMethod("getDurationWithId", id);
    return Duration(seconds: second);
  }

  static Future<Size> _getSizeWithId(String id) async {
    Map r = await _channel.invokeMethod("getSizeWithId", id);
    Map<String, int> size = r.cast();
    return Size(size["width"].toDouble(), size["height"].toDouble());
  }

  /// Release all native(ios/android) caches, normally no calls are required.
  ///
  /// The main purpose is to help clean up problems where memory usage may be too large when there are too many pictures.
  ///
  /// Warning:
  ///
  ///   Once this method is invoked, unless you call the [getAssetPathList] method again, all the [AssetEntity] and [AssetPathEntity] methods/fields you have acquired will fail or produce unexpected results.
  ///
  ///   This method should only be invoked when you are sure you really want to do so.
  ///
  ///   This method is asynchronous, and calling [getAssetPathList] before the Future of this method returns causes an error.
  ///
  ///
  /// 释放资源的方法,一般情况下不需要调用
  ///
  /// 主要目的是帮助清理当图片过多时,内存占用可能过大的问题
  ///
  /// 警告:
  ///
  /// 一旦调用这个方法,除非你重新调用  [getAssetPathList] 方法,否则你已经获取的所有[AssetEntity]/[AssetPathEntity]的所有方���/字段都将失效或产生无法预期的效果
  ///
  /// 这个方法应当只在你确信你真的需要这么做的时候再调用
  ///
  /// 这个方法是异步的,在本方法的Future返回前调用getAssetPathList 可能会产生错误
  static Future releaseCache() async {
    await _channel.invokeMethod("releaseMemCache");
  }
}

/// Used to describe a picture or video
class AssetEntity {
  /// in android is full path
  ///
  /// in ios is asset id
  String id;

  /// the asset type
  ///
  /// see [AssetType]
  AssetType type;

  // /// isCloud
  // Future get isCloud async => PhotoManager._isCloudWithAsset(this);

  /// thumb path
  ///
  /// you can use File(path) to use
  // Future<File> get thumb async => PhotoManager._getThumbWithId(id);

  /// if you need upload file ,then you can use the file
  Future<File> get file async => PhotoManager._getFullFileWithId(id);

  /// the image's bytes ,
  Future<Uint8List> get fullData => PhotoManager._getDataWithId(id);

  /// thumb data , for display
  Future<Uint8List> get thumbData => PhotoManager._getThumbDataWithId(id);

  /// get thumb with size
  Future<Uint8List> thumbDataWithSize(int width, int height) {
    return PhotoManager._getThumbDataWithId(id, width: width, height: height);
  }

  /// if not video ,duration is null
  Future<Duration> get videoDuration async {
    if (type != AssetType.video) {
      return null;
    }
    return PhotoManager._getDurationWithId(id);
  }

  /// nullable, if the manager is null.
  Future<Size> get size async {
    try {
      return await PhotoManager._getSizeWithId(id);
    } on Exception {
      return null;
    }
  }

  /// see [id]
  AssetEntity({this.id});

  @override
  int get hashCode {
    return id.hashCode;
  }

  @override
  bool operator ==(other) {
    if (other is! AssetEntity) {
      return false;
    }
    return this.id == other.id;
  }

  @override
  String toString() {
    return "AssetEntity{id:$id}";
  }
}

/// asset entity, for entity info.
class AssetPathEntity {
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

  bool _hasVideo;

  /// hasVideo
  set hasVideo(bool value) => _hasVideo = value;

  /// hasVideo
  bool get hasVideo => onlyVideo == true || _hasVideo == true;

  /// only have video
  bool onlyVideo = false;

  /// only have image
  bool onlyImage = false;

  /// contains all asset
  bool isAll = false;

  AssetPathEntity({this.id, this.name, bool hasVideo}) : _hasVideo = hasVideo;

  /// the image entity list
  Future<List<AssetEntity>> get assetList => PhotoManager._getAssetList(this);

  static var _all = AssetPathEntity()
    ..id = "allall--dfnsfkdfj2454AJJnfdkl"
    ..name = "Recent"
    ..isAll = true
    ..hasVideo = true;

  static var _allVideo = AssetPathEntity()
    ..id = "videovideo--87yuhijn3cvx"
    ..name = "Recent"
    ..isAll = true
    ..onlyVideo = true;

  static var _allImage = AssetPathEntity()
    ..id = "imageimage--89hdsinvosd"
    ..onlyImage = true
    ..isAll = true
    ..name = "Recent";

  /// all asset path
  static AssetPathEntity get all => _all;

  @override
  bool operator ==(other) {
    if (other is! AssetPathEntity) {
      return false;
    }
    return this.id == other.id;
  }

  @override
  int get hashCode {
    return this.id.hashCode;
  }

  @override
  String toString() {
    return "AssetPathEntity{id:$id}";
  }
}

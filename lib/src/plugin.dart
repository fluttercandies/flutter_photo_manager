import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager/src/filter/load_option.dart';
import 'package:photo_manager/src/utils/convert_utils.dart';

class Plugin with BasePlugin, IosPlugin, AndroidPlugin {
  static Plugin _plugin;

  factory Plugin() {
    _plugin ??= Plugin._();
    return _plugin;
  }

  Plugin._();

  /// [type] 0 : all , 1: image ,2 video
  Future<List<AssetPathEntity>> getAllGalleryList({
    int type = 0,
    bool hasAll = true,
    FilterOptionGroup optionGroup,
    bool onlyAll,
  }) async {
    final result = await _channel.invokeMethod("getGalleryList", {
      "type": type,
      "hasAll": hasAll,
      "onlyAll": onlyAll,
      "option": optionGroup.toMap(),
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

  Future<bool> requestPermission() async {
    return (await _channel.invokeMethod("requestPermission")) == 1;
  }

  Future<List<AssetEntity>> getAssetWithGalleryIdPaged(
    String id, {
    int page = 0,
    int pageCount = 15,
    int type = 0,
    FilterOptionGroup optionGroup,
  }) async {
    final result = await _channel.invokeMethod("getAssetWithGalleryId", {
      "id": id,
      "page": page,
      "pageCount": pageCount,
      "type": type,
      "option": optionGroup.toMap(),
    });

    return ConvertUtils.convertToAssetList(result);
  }

  Future<List<AssetEntity>> getAssetWithRange(
    String id, {
    int typeInt,
    int start,
    int end,
    FilterOptionGroup optionGroup,
  }) async {
    final Map map = await _channel.invokeMethod("getAssetListWithRange", {
      "galleryId": id,
      "type": typeInt,
      "start": start,
      "end": end,
      "option": optionGroup.toMap(),
    });

    return ConvertUtils.convertToAssetList(map);
  }

  Future<Uint8List> getThumb(
      {@required String id,
      LoadOption option = const DefaultLoadOption(100, 100)}) {
    final map = option.toMap();
    map["id"] = id;
    return _channel.invokeMethod("getThumb", map);
  }

  Future<Uint8List> getOriginBytes(String id) async {
    return _channel.invokeMethod("getOriginBytes", {"id": id});
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
      String id, int type, FilterOptionGroup optionGroup) async {
    return _channel.invokeMethod(
      "fetchPathProperties",
      {
        "id": id,
        "timestamp": 0,
        "type": type,
        "option": optionGroup.toMap(),
      },
    );
  }

  void notifyChange({bool start}) {
    _channel.invokeMethod("notify", {
      "notify": start,
    });
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

  Future<AssetEntity> saveImageWithPath(String path,
      {String title, String desc = ""}) async {
    final file = File(path);
    if (!file.existsSync()) {
      assert(file.existsSync(), "file must exists");
      return null;
    }

    title ??= "image_${DateTime.now().millisecondsSinceEpoch / 1000}.jpg";

    final result = await _channel.invokeMethod(
      "saveImageWithPath",
      {
        "path": path,
        "title": title,
        "desc": desc,
      },
    );

    return ConvertUtils.convertToAsset(result);
  }

  Future<AssetEntity> saveVideo(
    File file, {
    String title,
    String desc = "",
  }) async {
    if (!file.existsSync()) {
      assert(file.existsSync(), "file must exists");
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

  Future<String> getSystemVersion() async {
    return _channel.invokeMethod("systemVersion");
  }

  Future<LatLng> getLatLngAsync(AssetEntity assetEntity) async {
    if (Platform.isAndroid) {
      final version = int.parse(await getSystemVersion());
      if (version >= 29) {
        final map = await _channel
            .invokeMethod("getLatLngAndroidQ", {"id": assetEntity.id});
        if (map is Map) {
          /// 将返回的数据传入map
          return LatLng()
            ..latitude = map["lat"]
            ..longitude = map["lng"];
        }
      }
    }
    return LatLng()
      ..latitude = assetEntity.latitude
      ..longitude = assetEntity.longitude;
  }

  Future<bool> cacheOriginBytes(bool cache) {
    return _channel.invokeMethod("cacheOriginBytes");
  }

  Future<String> getTitleAsync(AssetEntity assetEntity) async {
    assert(Platform.isAndroid || Platform.isIOS || Platform.isMacOS);
    if (Platform.isAndroid) {
      return assetEntity.title;
    }

    if (Platform.isIOS || Platform.isMacOS) {
      return _channel.invokeMethod("getTitleAsync", {"id": assetEntity.id});
    }

    return "";
  }

  Future<String> getMediaUrl(AssetEntity assetEntity) {
    return _channel.invokeMethod("getMediaUrl", {
      "id": assetEntity.id,
      "type": assetEntity.typeInt,
    });
  }

  Future<List<AssetPathEntity>> getSubPathEntities(
      AssetPathEntity pathEntity) async {
    final result = await _channel.invokeMethod("getSubPath", {
      "id": pathEntity.id,
      "type": pathEntity.type.value,
      "albumType": pathEntity.albumType,
      "option": pathEntity.filterOption.toMap(),
    });

    final items = result["list"];

    return ConvertUtils.convertPath(
      items,
      type: pathEntity.typeInt,
      optionGroup: pathEntity.filterOption,
    );
  }

  Future<AssetEntity> copyAssetToGallery(
      AssetEntity asset, AssetPathEntity pathEntity) async {
    if (pathEntity.isAll) {
      assert(pathEntity.isAll,
          "You don't need to copy the asset into the album containing all the pictures.");
      return null;
    }

    final result = await _channel.invokeMethod("copyAsset", {
      "assetId": asset.id,
      "galleryId": pathEntity.id,
    });

    if (result == null) {
      return null;
    }

    return ConvertUtils.convertToAsset(result);
  }

  Future<bool> iosDeleteCollection(AssetPathEntity path) async {
    final result = await _channel.invokeMethod("deleteAlbum", {
      "id": path.id,
      "type": path.albumType,
    });
    if (result["errorMsg"] != null) {
      print(result["errorMsg"]);
      return false;
    }
    return true;
  }

  Future<bool> favoriteAsset(String id, bool favorite) {
    return _channel.invokeMethod("favoriteAsset", {
      "id": id,
      "favorite": favorite,
    });
  }

  Future<bool> androidRemoveNoExistsAssets() {
    return _channel.invokeMethod("removeNoExistsAssets");
  }

  Future getPropertiesFromAssetEntity(String id) async {
    return _channel.invokeMethod('getPropertiesFromAssetEntity', {"id": id});
  }

  Future<int> getFileSize(AssetEntity assetPathEntity) {
    return _channel.invokeMethod('getFileSize', {'id': assetPathEntity.id});
  }
}

mixin BasePlugin {
  final MethodChannel _channel = MethodChannel('top.kikt/photo_manager');
}

mixin IosPlugin on BasePlugin {
  Future<AssetPathEntity> iosCreateFolder(
      String name, bool isRoot, AssetPathEntity parent) async {
    final map = {
      "name": name,
      "isRoot": isRoot,
    };
    if (!isRoot && parent != null) {
      map["folderId"] = parent.id;
    }
    final result = await _channel.invokeMethod(
      "createFolder",
      map,
    );
    if (result == null) {
      return null;
    }

    if (result["errorMsg"] != null) {
      print("errorMsg");
      return null;
    }

    return AssetPathEntity()
      ..id = result["id"]
      ..name = name
      ..isAll = false
      ..assetCount = 0
      ..albumType = 2;
  }

  Future<AssetPathEntity> iosCreateAlbum(
      String name, bool isRoot, AssetPathEntity parent) async {
    final map = {
      "name": name,
      "isRoot": isRoot,
    };
    if (!isRoot && parent != null) {
      map["folderId"] = parent.id;
    }
    final result = await _channel.invokeMethod(
      "createAlbum",
      map,
    );
    if (result == null) {
      return null;
    }

    if (result["errorMsg"] != null) {
      print("errorMsg");
      return null;
    }

    return AssetPathEntity()
      ..id = result["id"]
      ..name = name
      ..isAll = false
      ..assetCount = 0
      ..albumType = 1;
  }

  Future<bool> iosRemoveInAlbum(
      List<AssetEntity> entities, AssetPathEntity path) async {
    final result = await _channel.invokeMethod(
      "removeInAlbum",
      {
        "assetId": entities.map((e) => e.id).toList(),
        "pathId": path.id,
      },
    );

    if (result["msg"] != null) {
      print("cannot remove, cause by: ${result["msg"]}");
      return false;
    }

    return true;
  }
}

mixin AndroidPlugin on BasePlugin {
  Future<bool> androidMoveAssetToPath(
      AssetEntity entity, AssetPathEntity target) async {
    final result = await _channel.invokeMethod("moveAssetToPath", {
      "assetId": entity.id,
      "albumId": target.id,
    });

    print(result);

    return true;
  }
}

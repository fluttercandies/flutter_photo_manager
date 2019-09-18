import 'package:photo_manager/photo_manager.dart';

class ConvertUtils {
  static List<AssetPathEntity> convertPath(
    Map data, {
    int type = 0,
    DateTime dt,
  }) {
    List<AssetPathEntity> result = [];

    List list = data["data"];

    for (final Map item in list) {
      final entity = AssetPathEntity()
        ..id = item["id"]
        ..name = item["name"]
        ..typeInt = type
        ..isAll = item["isAll"]
        ..fetchDatetime = dt
        ..assetCount = item["length"];

      result.add(entity);
    }

    return result;
  }

  static List<AssetEntity> convertToAssetList(Map data) {
    List<AssetEntity> result = [];

    List list = data["data"];
    for (final Map item in list) {
      final entity = AssetEntity()
        ..id = item["id"]
        ..createDtSecond = item["createDt"]
        ..width = item["width"]
        ..height = item["height"]
        ..duration = item["duration"]
        ..modifiedDateSecond = item["modifiedDt"]
        ..typeInt = item["type"];

      result.add(entity);
    }

    return result;
  }

  static AssetEntity convertToAsset(Map map) {
    if (map == null) {
      return null;
    }

    Map data = map["data"];

    final entity = AssetEntity()
      ..id = data["id"]
      ..createDtSecond = data["createDt"]
      ..width = data["width"]
      ..height = data["height"]
      ..duration = data["duration"]
      ..modifiedDateSecond = data["modifiedDt"]
      ..typeInt = data["type"];

    return entity;
  }
}

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

  static List<AssetEntity> convertAssetEntity(Map data) {
    List<AssetEntity> result = [];

    List list = data["data"];
    for (final Map item in list) {
      final entity = AssetEntity()
        ..id = item["id"]
        ..createTime = item["createDt"]
        ..width = item["width"]
        ..height = item["height"]
        ..duration = item["duration"]
        ..typeInt = item["type"];

      result.add(entity);
    }

    return result;
  }
}

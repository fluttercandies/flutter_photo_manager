import 'package:photo_manager/photo_manager.dart';

class ConvertUtils {
  static List<AssetPathEntity> convertPath(
    Map data, {
    int type = 0,
    DateTime dt,
    FilterOptionGroup optionGroup,
  }) {
    List<AssetPathEntity> result = [];

    List list = data["data"];

    for (final Map item in list) {
      final entity = AssetPathEntity(filterOption: optionGroup)
        ..id = item["id"]
        ..name = item["name"]
        ..typeInt = type
        ..isAll = item["isAll"]
        ..assetCount = item["length"]
        ..albumType = (item["albumType"] ?? 1);

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
        ..orientation = (item["orientation"] ?? 0)
        ..duration = item["duration"]
        ..modifiedDateSecond = item["modifiedDt"]
        ..typeInt = item["type"]
        ..longitude = item["lng"]
        ..latitude = item["lat"]
        ..title = item["title"]
        ..relativePath = item['relativePath'];

      result.add(entity);
    }

    return result;
  }

  static AssetEntity convertToAsset(Map map) {
    if (map == null) {
      return null;
    }

    Map data = map["data"];

    if (data == null) {
      return null;
    }

    final entity = AssetEntity()
      ..id = data["id"]
      ..createDtSecond = data["createDt"]
      ..width = data["width"]
      ..height = data["height"]
      ..duration = data["duration"]
      ..modifiedDateSecond = data["modifiedDt"]
      ..typeInt = data["type"]
      ..longitude = data["lng"]
      ..latitude = data["lat"]
      ..title = data["title"];

    return entity;
  }
}

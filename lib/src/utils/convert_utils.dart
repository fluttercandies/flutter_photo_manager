import 'package:photo_manager/photo_manager.dart';

class ConvertUtils {
  static List<AssetPathEntity> convertPath(
    Map data, {
    int type = 0,
    FilterOptionGroup? optionGroup,
  }) {
    List<AssetPathEntity> result = [];

    List list = data["data"];

    for (final Map item in list) {
      final entity = AssetPathEntity()
        ..id = item["id"]
        ..name = item["name"]
        ..typeInt = type
        ..isAll = item["isAll"]
        ..assetCount = item["length"]
        ..albumType = (item["albumType"] ?? 1)
        ..filterOption = optionGroup ?? FilterOptionGroup();

      result.add(entity);
    }

    return result;
  }

  static List<AssetEntity> convertToAssetList(Map data) {
    List<AssetEntity> result = [];

    List list = data["data"];
    for (final Map item in list) {
      final entity = AssetEntity(
        id: item['id'],
        typeInt: item['type'],
        duration: item['duration'],
        width: item['width'],
        height: item['height'],
        orientation: item['orientation'],
        isFavorite: item['favorite'] ?? false,
        title: item['title'],
        createDtSecond: item['createDt'],
        modifiedDateSecond: item['modifiedDt'],
        relativePath: item['relativePath'],
      )
        ..latitude = item['lat']
        ..longitude = item['lng'];

      result.add(entity);
    }

    return result;
  }

  static AssetEntity? convertToAsset(Map? map) {
    final Map? data = map?['data'];
    if (data == null) {
      return null;
    }

    return AssetEntity(
      id: data['id'],
      typeInt: data['type'],
      duration: data['duration'],
      width: data['width'],
      height: data['height'],
      orientation: data['orientation'],
      isFavorite: data['favorite'] ?? false,
      title: data['title'],
      createDtSecond: data['createDt'],
      modifiedDateSecond: data['modifiedDt'],
      relativePath: data['relativePath'],
    )
      ..latitude = data['lat']
      ..longitude = data['lng'];
  }
}

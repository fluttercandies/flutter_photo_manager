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
      final asset = convertToAsset(item);
      if (asset != null) {
        result.add(asset);
      }
    }

    return result;
  }

  static AssetEntity? convertToAsset(Map? map) {
    final Map? data = map?['data'];
    if (data == null) {
      return null;
    }

    final result = AssetEntity(
      id: data['id'],
      typeInt: data['type'],
      width: data['width'],
      height: data['height'],
      duration: data['duration'] ?? 0,
      orientation: data['orientation'] ?? 0,
      isFavorite: data['favorite'] ?? false,
      title: data['title'],
      createDtSecond: data['createDt'],
      modifiedDateSecond: data['modifiedDt'],
      relativePath: data['relativePath'],
    )
      ..latitude = data['lat']
      ..longitude = data['lng'];

    if (data.containsKey('mimeType')) {
      result.mimeType = data['mimeType'];
    }

    return result;
  }
}

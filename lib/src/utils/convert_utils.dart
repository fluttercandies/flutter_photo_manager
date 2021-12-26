import '../filter/filter_option_group.dart';
import '../types/entity.dart';
import '../types/types.dart';

class ConvertUtils {
  const ConvertUtils._();

  static List<AssetPathEntity> convertPath(
    Map<String, dynamic> data, {
    RequestType type = RequestType.all,
    FilterOptionGroup? optionGroup,
  }) {
    final List<AssetPathEntity> result = <AssetPathEntity>[];
    final List<Map<dynamic, dynamic>> list =
        (data['data'] as List<dynamic>).cast<Map<dynamic, dynamic>>();
    for (final Map<dynamic, dynamic> item in list) {
      final AssetPathEntity entity = AssetPathEntity()
        ..id = item['id'] as String
        ..name = item['name'] as String
        ..type = type
        ..isAll = item['isAll'] as bool
        ..assetCount = item['length'] as int
        ..albumType = item['albumType'] as int? ?? 1
        ..filterOption = optionGroup ?? FilterOptionGroup();
      final int? modifiedDate = item['modified'] as int?;
      if (modifiedDate != null) {
        entity.lastModified = DateTime.fromMillisecondsSinceEpoch(
          modifiedDate * 1000,
        );
      }
      result.add(entity);
    }
    return result;
  }

  static List<AssetEntity> convertToAssetList(Map<String, dynamic> data) {
    final List<AssetEntity> result = <AssetEntity>[];
    final List<Map<dynamic, dynamic>> list =
        (data['data'] as List<dynamic>).cast<Map<dynamic, dynamic>>();
    for (final Map<dynamic, dynamic> item in list) {
      result.add(convertMapToAsset(item.cast<String, dynamic>()));
    }
    return result;
  }

  static AssetEntity convertMapToAsset(
    Map<String, dynamic> data, {
    String? title,
  }) {
    final AssetEntity result = AssetEntity(
      id: data['id'] as String,
      typeInt: data['type'] as int,
      width: data['width'] as int,
      height: data['height'] as int,
      duration: data['duration'] as int? ?? 0,
      orientation: data['orientation'] as int? ?? 0,
      isFavorite: data['favorite'] as bool? ?? false,
      title: data['title'] as String? ?? title,
      subtype: data['subtype'] as int? ?? 0,
      createDtSecond: data['createDt'] as int?,
      modifiedDateSecond: data['modifiedDt'] as int?,
      relativePath: data['relativePath'] as String?,
      latitude: data['lat'] as double?,
      longitude: data['lng'] as double?,
      mimeType: data['mimeType'] as String?,
    );
    return result;
  }
}

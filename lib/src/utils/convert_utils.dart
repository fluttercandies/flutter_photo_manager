// Copyright 2018 The FlutterCandies author. All rights reserved.
// Use of this source code is governed by an Apache license that can be found
// in the LICENSE file.

import '../filter/filter_option_group.dart';
import '../types/entity.dart';
import '../types/types.dart';

class ConvertUtils {
  const ConvertUtils._();

  static List<AssetPathEntity> convertToPathList(
    Map<String, dynamic> data, {
    required RequestType type,
    FilterOptionGroup? optionGroup,
  }) {
    final List<AssetPathEntity> result = <AssetPathEntity>[];
    final List<Map<dynamic, dynamic>> list =
        (data['data'] as List<dynamic>).cast<Map<dynamic, dynamic>>();
    for (final Map<dynamic, dynamic> item in list) {
      result.add(
        convertMapToPath(
          item.cast<String, dynamic>(),
          type: type,
          optionGroup: optionGroup ?? FilterOptionGroup(),
        ),
      );
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

  static AssetPathEntity convertMapToPath(
    Map<String, dynamic> data, {
    required RequestType type,
    FilterOptionGroup? optionGroup,
  }) {
    final int? modified = data['modified'] as int?;
    final DateTime? lastModified = modified != null
        ? DateTime.fromMillisecondsSinceEpoch(modified * 1000)
        : null;
    final AssetPathEntity result = AssetPathEntity(
      id: data['id'] as String,
      name: data['name'] as String,
      assetCount: data['length'] as int,
      albumType: data['albumType'] as int? ?? 1,
      filterOption: optionGroup ?? FilterOptionGroup(),
      lastModified: lastModified,
      type: type,
      isAll: data['isAll'] as bool,
    );
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
      createDateSecond: data['createDt'] as int?,
      modifiedDateSecond: data['modifiedDt'] as int?,
      relativePath: data['relativePath'] as String?,
      latitude: data['lat'] as double?,
      longitude: data['lng'] as double?,
      mimeType: data['mimeType'] as String?,
    );
    return result;
  }
}

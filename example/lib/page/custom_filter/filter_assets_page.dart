import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_example/page/custom_filter/image_list.dart';

class FilterAssetsContent extends StatelessWidget {
  const FilterAssetsContent({
    super.key,
    required this.filter,
  });
  final CustomFilter filter;

  Future<List<AssetEntity>> getAssets() async {
    final count = await PhotoManager.getAssetCount(filterOption: filter);
    if (count == 0) {
      return [];
    }
    final list = await PhotoManager.getAssetListRange(
      start: 0,
      end: count,
      filterOption: filter,
    );
    return list;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<AssetEntity>>(
      future: getAssets(),
      builder:
          (BuildContext context, AsyncSnapshot<List<AssetEntity>> snapshot) {
        if (snapshot.hasData) {
          return ImageList(list: snapshot.data!);
        }
        return const SizedBox();
      },
    );
  }
}

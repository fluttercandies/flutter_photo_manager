import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

import '../../../util/log.dart';
import 'issue_index_page.dart';

class Issue734Page extends StatefulWidget {
  const Issue734Page({super.key});

  @override
  State<Issue734Page> createState() => _Issue734PageState();
}

class _Issue734PageState extends State<Issue734Page>
    with IssueBase<Issue734Page> {
  @override
  int get issueNumber => 734;

  @override
  Widget build(BuildContext context) {
    return buildScaffold(
      [
        buildButton('Reproduct', _reproduct),
      ],
    );
  }

  Future<void> _reproduct() async {
    const FilterOption opt = FilterOption(
      needTitle: true,
      sizeConstraint: SizeConstraint(ignoreSize: true),
    );

    final FilterOptionGroup group = FilterOptionGroup(
      imageOption: opt,
      audioOption: opt,
      videoOption: opt,
    );

    final List<AssetPathEntity> pathList =
        await PhotoManager.getAssetPathList(filterOption: group);

    if (pathList.isEmpty) {
      Log.d('The path list is empty');
      return;
    }

    final AssetPathEntity recent = pathList[0];
    final int assetCount = await recent.assetCountAsync;
    Log.d('recent.assetCount: $assetCount');

    for (int i = 0; i < assetCount; i++) {
      final List<AssetEntity> pageAssetList = await recent.getAssetListPaged(
        page: i,
        size: 1,
      );

      try {
        Log.d(' page($i, 1) list asset count: ${pageAssetList.length}');
        Log.d(' page($i, 1) list asset[0] id: ${pageAssetList[0].id}');
      } catch (e) {
        Log.d(e);
      }

      final List<AssetEntity> rangeList =
          await recent.getAssetListRange(start: i, end: i + 1);
      try {
        Log.d('range($i, ${i + 1}) list asset count: ${rangeList.length}');
        Log.d('range($i, ${i + 1}) list asset[0] id: ${rangeList[0].id}');
      } catch (e) {
        Log.d(e);
      }
    }
  }
}

import 'package:flutter/material.dart';
import 'package:oktoast/oktoast.dart';
import 'package:photo_manager/photo_manager.dart';

import 'issue_index_page.dart';

class Issus1152 extends StatefulWidget {
  const Issus1152({super.key});

  @override
  State<Issus1152> createState() => _Issus1152State();
}

class _Issus1152State extends State<Issus1152> with IssueBase<Issus1152> {
  @override
  List<TargetPlatform>? get supportPlatforms => [
        TargetPlatform.android,
      ];

  List<RequestType> checkStatus = [];

  @override
  void initState() {
    super.initState();
    PhotoManager.setLog(true);
  }

  @override
  Widget build(BuildContext context) {
    return buildScaffold([
      buildButton(
        'Test API 28 get images',
        reproduce,
      ),
      buildLogWidget(),
    ]);
  }

  @override
  int get issueNumber => 1152;

  Future<void> reproduce() async {
    final pathList = await PhotoManager.getAssetPathList();
    final noAllPathList = pathList.where((element) => !element.isAll);
    if (noAllPathList.isEmpty) {
      showToast('No path found');
      return;
    }

    final path = noAllPathList.first;

    // final name = path.name;
    // final count = await path.assetCountAsync;
    // addLog('assetCount of "$name": $count');

    // final list = await path.getAssetListPaged(page: 0, size: 50);
    // addLog('list.length: ${list.length}');

    await fetchNewProperties(path);
  }

  Future<void> fetchNewProperties(AssetPathEntity path) async {
    try {
      await path.obtainForNewProperties();
    } catch (e) {
      addLog('error: $e');
    }
  }
}

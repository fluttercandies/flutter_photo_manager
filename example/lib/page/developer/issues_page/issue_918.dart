import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'issue_index_page.dart';

class Issue918Page extends StatefulWidget {
  const Issue918Page({super.key});

  @override
  State<Issue918Page> createState() => _Issue918PageState();
}

class _Issue918PageState extends State<Issue918Page>
    with IssueBase<Issue918Page> {
  @override
  int get issueNumber => 918;

  @override
  Widget build(BuildContext context) {
    return buildScaffold(
      [
        buildButton('Reproduct', _reproduct),
      ],
    );
  }

  Future<void> _reproduct() async {
    final assetList = await PhotoManager.getAssetListRange(
      start: 0,
      end: 10,
      filterOption: FilterOptionGroup(
        imageOption: const FilterOption(needTitle: true),
        videoOption: const FilterOption(needTitle: true),
        orders: [
          const OrderOption(type: OrderOptionType.createDate),
        ],
      ),
    );

    for (final asset in assetList) {
      print(asset.title);
      print(asset.createDateTime);
    }
  }
}

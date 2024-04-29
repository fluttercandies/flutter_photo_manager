import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

import 'issue_index_page.dart';

class Issue962 extends StatefulWidget {
  const Issue962({super.key});

  @override
  State<Issue962> createState() => _Issue962State();
}

class _Issue962State extends State<Issue962> with IssueBase<Issue962> {
  int start = 0;
  int end = 5;

  ValueNotifier<String> logNotifier = ValueNotifier<String>('');

  Future<void> onChange() async {
    if (start >= end) {
      logNotifier.value = 'start must less than end';
      return;
    }

    final assetList = await PhotoManager.getAssetListRange(
      start: start,
      end: end,
      filterOption: FilterOptionGroup(
        imageOption: const FilterOption(needTitle: true),
        videoOption: const FilterOption(needTitle: true),
        orders: [
          const OrderOption(type: OrderOptionType.createDate),
        ],
      ),
    );

    logNotifier.value = 'The assetList count: ${assetList.length}';
  }

  final node = FocusScopeNode();

  @override
  void dispose() {
    node.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return buildScaffold([
      TextFormField(
        initialValue: start.toString(),
        decoration: const InputDecoration(
          labelText: 'start',
        ),
        onChanged: (value) {
          start = int.tryParse(value) ?? 0;
          onChange();
        },
      ),
      TextFormField(
        initialValue: end.toString(),
        decoration: const InputDecoration(
          labelText: 'end',
        ),
        onChanged: (value) {
          end = int.tryParse(value) ?? 0;
          onChange();
        },
      ),
      buildButton('Reproduct issue 962', onChange),
      AnimatedBuilder(
        animation: logNotifier,
        builder: (context, w) {
          return Text(
            logNotifier.value,
            style: const TextStyle(
              fontSize: 12,
            ),
          );
        },
      ),
    ]);
  }

  @override
  int get issueNumber => 962;
}

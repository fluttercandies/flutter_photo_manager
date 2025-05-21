import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

class IncludeHiddenTestPage extends StatefulWidget {
  const IncludeHiddenTestPage({super.key});

  @override
  State<IncludeHiddenTestPage> createState() => _IncludeHiddenTestPageState();
}

class _IncludeHiddenTestPageState extends State<IncludeHiddenTestPage> {
  final List<String> _logs = [];

  Future<void> _test() async {
    final option = CustomFilter.sql(where: '');
    final count = await PhotoManager.getAssetCount(filterOption: option);

    setState(() {
      _logs.add('Not include hidden count: $count');
    });

    final option2 = CustomFilter.sql(where: '');
    option2.includeHiddenAssets = true;
    final count2 = await PhotoManager.getAssetCount(filterOption: option2);

    setState(() {
      _logs.add('Include hidden count: $count2');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Include Hidden Test'),
      ),
      body: Column(
        children: [
          ElevatedButton(
            onPressed: _test,
            child: const Text('Test the count of hidden and not hidden'),
          ),
          Expanded(
            child: ListView(
              children: [
                ..._logs.reversed.map((e) => ListTile(title: Text(e))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

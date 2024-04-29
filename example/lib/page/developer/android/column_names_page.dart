import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:photo_manager/photo_manager.dart';

class ColumnNamesPage extends StatefulWidget {
  const ColumnNamesPage({super.key});

  @override
  State<ColumnNamesPage> createState() => _ColumnNamesPageState();
}

class _ColumnNamesPageState extends State<ColumnNamesPage> {
  List<String> _columns = [];

  Future<void> _refresh() async {
    final columns = await PhotoManager.plugin.androidColumns();
    print('columns: $columns');
    columns.sort();
    setState(() {
      _columns = columns;
    });
  }

  @override
  void initState() {
    _refresh();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Column Names'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refresh,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    final list = _columns;
    return ListView.builder(
      itemBuilder: (context, index) {
        final column = list[index];
        return ListTile(
          title: Text(column),
          subtitle: const Text('click to copy'),
          onTap: () {
            Clipboard.setData(ClipboardData(text: column));
          },
        );
      },
      itemCount: list.length,
    );
  }
}

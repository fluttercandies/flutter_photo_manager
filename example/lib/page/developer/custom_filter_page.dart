import 'package:flutter/material.dart';

import 'package:photo_manager/photo_manager.dart';

class CustomFilterPage extends StatefulWidget {
  const CustomFilterPage({Key? key}) : super(key: key);

  @override
  _CustomFilterPageState createState() => _CustomFilterPageState();
}

class _CustomFilterPageState extends State<CustomFilterPage> {
  List<AssetPathEntity> _list = [];

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  BaseFilter createCustomFilter() {
    final CustomFilter filter = CustomFilter();
    return filter;
  }

  Future<void> _refresh() async {
    final List<AssetPathEntity> list = await PhotoManager.getAssetPathList(
      filterOption: createCustomFilter(),
    );
    setState(() {
      _list = list;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Custom Filter'),
      ),
      body: ListView.builder(
        itemBuilder: (BuildContext context, int index) {
          final AssetPathEntity entity = _list[index];
          return ListTile(
            title: Text(entity.name),
            subtitle: Text(entity.id),
            onTap: () {},
          );
        },
        itemCount: _list.length,
      ),
    );
  }
}

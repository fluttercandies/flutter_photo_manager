import 'package:flutter/material.dart';

import 'package:photo_manager/photo_manager.dart';

class CustomFilterPage extends StatefulWidget {
  const CustomFilterPage({Key? key}) : super(key: key);

  @override
  State<CustomFilterPage> createState() => _CustomFilterPageState();
}

class _CustomFilterPageState extends State<CustomFilterPage> {
  List<AssetPathEntity> _list = [];

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  BaseFilter createCustomFilter() {
    // final AdvancedCustomFilter filter = AdvancedCustomFilter();
    final filter = CustomFilter.sql('200 < width AND width < 300', 'width');
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
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refresh,
          ),
        ],
      ),
      body: ListView.builder(
        itemBuilder: (BuildContext context, int index) {
          final AssetPathEntity path = _list[index];
          return ListTile(
            title: Text(path.name),
            subtitle: Text(path.id),
            trailing: FutureBuilder<int>(
              future: path.assetCountAsync,
              builder: (BuildContext context, AsyncSnapshot<int> snapshot) {
                if (snapshot.hasData) {
                  return Text(snapshot.data.toString());
                }
                return const SizedBox();
              },
            ),
            onTap: () {},
          );
        },
        itemCount: _list.length,
      ),
    );
  }
}

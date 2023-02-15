import 'package:flutter/material.dart';
import 'package:oktoast/oktoast.dart';

import 'package:photo_manager/photo_manager.dart';

class CustomFilterPage extends StatefulWidget {
  const CustomFilterPage({Key? key}) : super(key: key);

  @override
  State<CustomFilterPage> createState() => _CustomFilterPageState();
}

class _CustomFilterPageState extends State<CustomFilterPage> {
  List<AssetPathEntity> _list = [];

  final TextEditingController _sqlController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _sqlController.text = 'width >= 1000';
    _refresh();
  }

  @override
  void dispose() {
    _sqlController.dispose();
    super.dispose();
  }

  PMFilter createCustomFilter() {
    // final AdvancedCustomFilter filter = AdvancedCustomFilter();
    final filter = CustomFilter.sql(
      where: _sqlController.text,
      // orderBy: [
      //   OrderByItem('width', true),
      // ],
    );
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
      body: Column(
        children: [
          TextField(
            controller: _sqlController,
            decoration: const InputDecoration(
              labelText: 'SQL',
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemBuilder: (BuildContext context, int index) {
                final AssetPathEntity path = _list[index];
                return ListTile(
                  title: Text(path.name),
                  subtitle: Text(path.id),
                  trailing: FutureBuilder<int>(
                    future: path.assetCountAsync,
                    builder:
                        (BuildContext context, AsyncSnapshot<int> snapshot) {
                      if (snapshot.hasData) {
                        return Text(snapshot.data.toString());
                      }
                      return const SizedBox();
                    },
                  ),
                  onTap: () async {
                    final count = await path.assetCountAsync;
                    showToast(
                      'Asset count: $count',
                      position: ToastPosition.bottom,
                    );
                  },
                );
              },
              itemCount: _list.length,
            ),
          ),
        ],
      ),
    );
  }
}

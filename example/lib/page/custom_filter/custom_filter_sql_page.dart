import 'dart:io';

import 'package:flutter/material.dart';
import 'package:oktoast/oktoast.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_example/page/custom_filter/path_list.dart';

import 'order_by_action.dart';

class CustomFilterSqlPage extends StatefulWidget {
  const CustomFilterSqlPage({Key? key}) : super(key: key);

  @override
  State<CustomFilterSqlPage> createState() => _CustomFilterSqlPageState();
}

class _CustomFilterSqlPageState extends State<CustomFilterSqlPage> {
  List<AssetPathEntity> _list = [];

  final TextEditingController _whereController = TextEditingController();
  final List<OrderByItem> _orderBy = [
    OrderByItem.named(
      column: CustomColumns.base.createDate,
      isAsc: false,
    ),
  ];

  @override
  void initState() {
    super.initState();
    if (Platform.isAndroid) {
      const columns = CustomColumns.android;
      _whereController.text =
          '(${columns.width} is not null) OR ${columns.width} >= 250';
    } else if (Platform.isIOS || Platform.isMacOS) {
      const columns = CustomColumns.darwin;
      _whereController.text =
          '${columns.width} <= 1000 AND ${columns.width} >= 250';
    }
    _refresh();
  }

  @override
  void dispose() {
    _whereController.dispose();
    super.dispose();
  }

  BaseFilter createCustomFilter() {
    final filter = CustomFilter.sql(
      where: _whereController.text,
      orderBy: _orderBy,
    );
    return filter;
  }

  Future<void> _refresh() async {
    final List<AssetPathEntity> list = await PhotoManager.getAssetPathList(
      filterOption: createCustomFilter(),
    );
    showToast('Get ${list.length} path(s).');
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
          OrderByAction(
            items: _orderBy,
            onChanged: (List<OrderByItem> value) {
              setState(() {
                _orderBy.clear();
                _orderBy.addAll(value);
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          TextField(
            controller: _whereController,
            decoration: const InputDecoration(
              labelText: 'Where',
            ),
          ),
          ListTile(
            title: Text(
                'Order By: \n${_orderBy.map((e) => e.toString()).join('\n')}'),
            subtitle: const Text('Click to edit'),
            onTap: () {
              changeOrderBy(context, _orderBy, (List<OrderByItem> value) {
                setState(() {
                  _orderBy.clear();
                  _orderBy.addAll(value);
                });
              });
            },
          ),
          Expanded(
            child: PathList(
              list: _list,
            ),
          ),
        ],
      ),
    );
  }
}

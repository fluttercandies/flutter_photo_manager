import 'dart:io';

import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

import 'order_by_action.dart';

class CustomFilterSqlGIFImage extends StatefulWidget {
  const CustomFilterSqlGIFImage({
    super.key,
    required this.builder,
  });

  final Widget Function(BuildContext context, CustomFilter filter) builder;

  @override
  State<CustomFilterSqlGIFImage> createState() =>
      _CustomFilterSqlGIFImageState();
}

class _CustomFilterSqlGIFImageState extends State<CustomFilterSqlGIFImage> {
  final TextEditingController _whereController = TextEditingController();
  final List<OrderByItem> _orderBy = [
    OrderByItem.named(
      column: CustomColumns.base.createDate,
      isAsc: false,
    ),
  ];

  late CustomFilter filter;

  @override
  void initState() {
    super.initState();
    if (Platform.isAndroid) {
      const columns = CustomColumns.android;
      _whereController.text = "${columns.mimeType} == 'image/gif'";
    } else if (Platform.isIOS || Platform.isMacOS) {
      const columns = CustomColumns.darwin;
      _whereController.text = '${columns.playbackStyle} == 2';
    }

    filter = createCustomFilter();
  }

  @override
  void dispose() {
    _whereController.dispose();
    super.dispose();
  }

  void refresh() {
    setState(() {
      filter = createCustomFilter();
    });
  }

  CustomFilter createCustomFilter() {
    final filter = CustomFilter.sql(
      where: _whereController.text,
      orderBy: _orderBy,
    );
    return filter;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Custom Filter'),
        actions: [
          OrderByAction(
            items: _orderBy,
            onChanged: (List<OrderByItem> value) {
              _orderBy.clear();
              _orderBy.addAll(value);
              refresh();
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
            onSubmitted: (value) {
              refresh();
            },
            onEditingComplete: () {
              refresh();
            },
          ),
          ListTile(
            title: Text(
              'Order By: \n${_orderBy.map((e) => e.toString()).join('\n')}',
            ),
            subtitle: const Text('Click to edit'),
            onTap: () {
              changeOrderBy(context, _orderBy, (List<OrderByItem> value) {
                _orderBy.clear();
                _orderBy.addAll(value);
                refresh();
              });
            },
          ),
          Expanded(
            child: widget.builder(context, filter),
          ),
        ],
      ),
    );
  }
}

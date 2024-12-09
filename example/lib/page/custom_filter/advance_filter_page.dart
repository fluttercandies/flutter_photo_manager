import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

import 'order_by_action.dart';
import 'where_action.dart';

class AdvancedCustomFilterPage extends StatefulWidget {
  const AdvancedCustomFilterPage({
    super.key,
    required this.builder,
  });

  final Widget Function(BuildContext context, CustomFilter filter) builder;

  @override
  State<AdvancedCustomFilterPage> createState() =>
      _AdvancedCustomFilterPageState();
}

class _AdvancedCustomFilterPageState extends State<AdvancedCustomFilterPage> {
  List<WhereConditionItem> _where = [];
  List<OrderByItem> _orderBy = [
    OrderByItem.named(
      column: CustomColumns.base.createDate,
      isAsc: false,
    ),
  ];

  late CustomFilter filter;

  @override
  void initState() {
    super.initState();
    filter = _createFilter();
  }

  AdvancedCustomFilter _createFilter() {
    final filter = AdvancedCustomFilter(
      orderBy: _orderBy,
      where: _where,
    );
    return filter;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Advanced Custom Filter Example'),
        actions: [
          WhereAction(
            items: _where,
            onChanged: (value) {
              if (!mounted) {
                return;
              }
              setState(() {
                _where = value;
                filter = _createFilter();
              });
            },
          ),
          OrderByAction(
            items: _orderBy,
            onChanged: (values) {
              if (!mounted) {
                return;
              }
              setState(() {
                _orderBy = values;
                filter = _createFilter();
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: widget.builder(context, filter),
          ),
        ],
      ),
    );
  }
}

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager/platform_utils.dart';

Future<void> changeOrderBy(
  BuildContext context,
  List<OrderByItem> items,
  ValueChanged<List<OrderByItem>> onChanged,
) async {
  OrderByActionPage._saveItems = null;
  final result = await Navigator.push<List<OrderByItem>>(
        context,
        MaterialPageRoute<List<OrderByItem>>(
          builder: (_) => OrderByActionPage(
            items: items.toList(),
          ),
        ),
      ) ??
      OrderByActionPage._saveItems;
  if (result != null) {
    onChanged(result);
  }
}

class OrderByAction extends StatelessWidget {
  const OrderByAction({
    super.key,
    required this.items,
    required this.onChanged,
  });

  final List<OrderByItem> items;
  final ValueChanged<List<OrderByItem>> onChanged;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        IconButton(
          onPressed: () async {
            await changeOrderBy(context, items, onChanged);
          },
          icon: const Icon(Icons.sort),
        ),
        if (items.isNotEmpty)
          Positioned(
            right: 5,
            top: 5,
            child: Container(
              width: 15,
              height: 15,
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  items.length.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 8,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class OrderByActionPage extends StatefulWidget {
  const OrderByActionPage({
    super.key,
    required this.items,
  });

  final List<OrderByItem> items;
  static List<OrderByItem>? _saveItems;

  @override
  State<OrderByActionPage> createState() => _OrderByActionPageState();
}

class _OrderByActionPageState extends State<OrderByActionPage> {
  final List<OrderByItem> _items = [];

  bool isEdit = false;

  @override
  void initState() {
    super.initState();
    _items.addAll(widget.items);
    OrderByActionPage._saveItems = _items;
  }

  @override
  Widget build(BuildContext context) {
    return _buildBody(context);
  }

  Widget _buildBody(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Order By'),
        actions: [
          IconButton(
            onPressed: _addItem,
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: ListView.builder(
        itemBuilder: _buildItem,
        itemCount: _items.length,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pop(context, _items);
        },
        child: const Icon(Icons.check),
      ),
    );
  }

  Widget _buildItem(BuildContext context, int index) {
    final item = _items[index];
    return ListTile(
      title: Text(item.column),
      subtitle: Text(item.isAsc ? 'ASC' : 'DESC'),
      trailing: IconButton(
        onPressed: () {
          setState(() {
            isEdit = true;
            _items.removeAt(index);
          });
        },
        icon: const Icon(Icons.delete),
      ),
    );
  }

  Future<void> _addItem() async {
    final result = await showDialog<OrderByItem>(
      context: context,
      builder: _buildDialog,
    );
    if (result != null) {
      setState(() {
        isEdit = true;
        _items.add(result);
      });
    }
  }

  Widget _buildDialog(BuildContext context) {
    final List<String> columns;
    if (Platform.isAndroid) {
      columns = AndroidMediaColumns.values();
    } else if (Platform.isMacOS || Platform.isIOS) {
      columns = DarwinColumns.values();
    } else if (PlatformUtils.isOhos) {
      columns = OhosColumns.values();
    } else {
      return const SizedBox.shrink();
    }
    String column = columns.first;
    bool isAsc = true;
    return AlertDialog(
      title: const Text('Add Order By'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<String>(
            items: columns
                .map(
                  (e) => DropdownMenuItem(
                    value: e,
                    child: Text(e),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value != null) {
                column = value;
              }
            },
            decoration: const InputDecoration(
              labelText: 'Column',
            ),
            value: columns.first,
          ),
          DropdownButtonFormField<bool>(
            items: const [
              DropdownMenuItem(
                value: true,
                child: Text('ASC'),
              ),
              DropdownMenuItem(
                value: false,
                child: Text('DESC'),
              ),
            ],
            onChanged: (value) {
              if (value != null) {
                isAsc = value;
              }
            },
            decoration: const InputDecoration(
              labelText: 'Order',
            ),
            value: true,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            final item = OrderByItem(column, isAsc);
            Navigator.pop(context, item);
          },
          child: const Text('OK'),
        ),
      ],
    );
  }
}

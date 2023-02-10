import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_example/page/custom_filter/order_by_action.dart';
import 'package:photo_manager_example/page/custom_filter/path_list.dart';

class AdvancedCustomFilterPage extends StatefulWidget {
  const AdvancedCustomFilterPage({Key? key}) : super(key: key);

  @override
  State<AdvancedCustomFilterPage> createState() =>
      _AdvancedCustomFilterPageState();
}

class _AdvancedCustomFilterPageState extends State<AdvancedCustomFilterPage> {
  final List<AssetPathEntity> _pathList = [];
  final List<OrderByItem> _orderBy = [
    OrderByItem.named(
      column: CustomColumns.base.createDate,
      isAsc: false,
    ),
  ];

  final List<WhereConditionItem> _where = [];

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    final filter = AdvancedCustomFilter(
      orderBy: _orderBy,
      where: _where,
    );
    PhotoManager.getAssetPathList(filterOption: filter).then((value) {
      setState(() {
        _pathList.clear();
        _pathList.addAll(value);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Advanced Custom Filter Example'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refresh,
          ),
          WhereAction(
            where: _where,
            onChanged: (value) {
              setState(() {
                _where.clear();
                _where.addAll(value);
              });
            },
          ),
          OrderByAction(
            items: _orderBy,
            onChanged: (values) {
              if (!mounted) return;
              setState(() {
                _orderBy.clear();
                _orderBy.addAll(values);
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: PathList(list: _pathList),
          ),
        ],
      ),
    );
  }
}

class WhereAction extends StatelessWidget {
  const WhereAction({
    Key? key,
    required this.where,
    required this.onChanged,
    // required this
  }) : super(key: key);

  final List<WhereConditionItem> where;
  final ValueChanged<List<WhereConditionItem>> onChanged;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.filter_alt),
      onPressed: () {
        Navigator.of(context)
            .push<List<WhereConditionItem>>(MaterialPageRoute(
          builder: (context) => _WhereConditionPage(where: where),
        ))
            .then((value) {
          if (value != null) {
            onChanged(value);
          }
        });
      },
    );
  }
}

class _WhereConditionPage extends StatefulWidget {
  const _WhereConditionPage({
    Key? key,
    required this.where,
  }) : super(key: key);

  final List<WhereConditionItem> where;

  @override
  State<_WhereConditionPage> createState() => _WhereConditionPageState();
}

class _WhereConditionPageState extends State<_WhereConditionPage> {
  final List<WhereConditionItem> _where = [];

  @override
  void initState() {
    super.initState();
    _where.addAll(widget.where);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Where Condition'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _createNew,
          ),
        ],
      ),
      body: buildList(context),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.done),
        onPressed: () {
          Navigator.of(context).pop(_where);
        },
      ),
    );
  }

  void _createNew() async {
    final result = await showDialog<WhereConditionItem>(
      context: context,
      builder: (context) {
        return const _CreateWhereDialog();
      },
    );
    if (result != null) {
      setState(() {
        _where.add(result);
      });
    }
  }

  Widget buildList(BuildContext context) {
    return ListView.builder(
      itemCount: _where.length,
      itemBuilder: (context, index) {
        final item = _where[index];
        return ListTile(
          title: Text(item.text),
          trailing: IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () {
              setState(() {
                _where.removeAt(index);
              });
            },
          ),
        );
      },
    );
  }
}

class _CreateWhereDialog extends StatefulWidget {
  const _CreateWhereDialog({Key? key}) : super(key: key);

  @override
  State<_CreateWhereDialog> createState() => _CreateWhereDialogState();
}

class _CreateWhereDialogState extends State<_CreateWhereDialog> {
  List<String> keys() {
    return CustomColumns.platformValues();
  }

  late String column = keys().first;
  late String condition = WhereConditionItem.platformValues.first;
  TextEditingController inputController = TextEditingController();

  WhereConditionItem createItem() {
    final value = '$column $condition ${inputController.text}';
    final item = WhereConditionItem.text(value);
    return item;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      content: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButton<String>(
              items: keys().map((e) {
                return DropdownMenuItem(
                  value: e,
                  child: Text(e),
                );
              }).toList(),
              onChanged: (value) {
                if (value == null) return;
                setState(() {
                  column = value;
                });
              },
              value: column,
            ),
            DropdownButton<String>(
              items: WhereConditionItem.platformValues.map((e) {
                return DropdownMenuItem(
                  value: e,
                  child: Text(e),
                );
              }).toList(),
              onChanged: (value) {
                if (value == null) return;
                setState(() {
                  condition = value;
                });
              },
              value: condition,
            ),
            TextField(
              controller: inputController,
              decoration: const InputDecoration(
                hintText: 'Input condition',
              ),
              onChanged: (value) {
                setState(() {});
              },
            ),
            Text(
              createItem().text,
              style: Theme.of(context).textTheme.caption,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(createItem());
          },
          child: const Text('OK'),
        ),
      ],
    );
  }
}

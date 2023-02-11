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

  final _columns = CustomColumns.base;

  late AdvancedCustomFilter filter;

  @override
  void initState() {
    super.initState();
    resetToDefault();
    _refresh();
  }

  void _refresh() {
    PhotoManager.getAssetPathList(filterOption: filter).then((value) {
      setState(() {
        _pathList.clear();
        _pathList.addAll(value);
      });
    });
  }

  AdvancedCustomFilter _createFilter() {
    final filter = AdvancedCustomFilter(
      orderBy: _orderBy,
      where: _where,
    );
    return filter;
  }

  void resetToDefault() {
    filter = AdvancedCustomFilter()
        .addWhereCondition(
          ColumnWhereCondition(
            column: _columns.width,
            operator: '>=',
            value: '200',
          ),
        )
        .addOrderBy(column: _columns.createDate, isAsc: false);
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
          title: Text(item.display()),
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
  String? condition;
  TextEditingController textValueController = TextEditingController();

  var _date = DateTime.now();

  WhereConditionItem createItem() {
    final cond = condition ?? '';

    if (isDateColumn()) {
      return DateColumnWhereCondition(
        column: column,
        operator: condition,
        value: _date,
      );
    }

    final value = '$column $cond ${textValueController.text}';
    final item = WhereConditionItem.text(value);
    return item;
  }

  bool isDateColumn() {
    final dateColumns = CustomColumns.dateColumns();
    return dateColumns.contains(column);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create Where Condition'),
      content: Container(
        width: double.maxFinite,
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButton<String>(
              items: keys().map((e) {
                return DropdownMenuItem(
                  value: e,
                  child: Text(e.padRight(40)),
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
              hint: const Text('Condition'),
              items: WhereConditionItem.platformConditions.map((e) {
                return DropdownMenuItem(
                  value: e,
                  child: Text(e.padRight(40)),
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
            if (!isDateColumn())
              TextField(
                controller: textValueController,
                decoration: const InputDecoration(
                  hintText: 'Input condition',
                ),
                onChanged: (value) {
                  setState(() {});
                },
              )
            else
              _datePicker(),
            const SizedBox(
              height: 16,
            ),
            Text(
              createItem().text,
              style: TextStyle(
                color: Theme.of(context).primaryColor,
                fontSize: 20,
              ),
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

  Widget _datePicker() {
    return Column(
      children: [
        TextButton(
          onPressed: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: _date,
              firstDate: DateTime(1970),
              lastDate: DateTime(2100),
            );
            if (date == null) return;
            setState(() {
              _date = date;
            });
          },
          child: Text(_date.toIso8601String()),
        ),
      ],
    );
  }
}

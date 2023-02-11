import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_example/page/custom_filter/order_by_action.dart';

class AdvancedCustomFilterPage extends StatefulWidget {
  const AdvancedCustomFilterPage({
    Key? key,
    required this.builder,
  }) : super(key: key);

  final Widget Function(BuildContext context, CustomFilter filter) builder;

  @override
  State<AdvancedCustomFilterPage> createState() =>
      _AdvancedCustomFilterPageState();
}

class _AdvancedCustomFilterPageState extends State<AdvancedCustomFilterPage> {
  final List<OrderByItem> _orderBy = [
    OrderByItem.named(
      column: CustomColumns.base.createDate,
      isAsc: false,
    ),
  ];

  final List<WhereConditionItem> _where = [];

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
            where: _where,
            onChanged: (value) {
              if (!mounted) return;
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
            child: widget.builder(context, filter),
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
        Navigator.push<List<WhereConditionItem>>(
          context,
          MaterialPageRoute(
            builder: (context) => _WhereConditionPage(where: where),
          ),
        ).then((value) {
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

  bool isChanged = false;

  @override
  void initState() {
    super.initState();
    _where.addAll(widget.where);
  }

  Future<bool> _onWillPop() {
    if (!isChanged) {
      return Future.value(true);
    }
    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Are you sure?'),
          content: const Text('Do you want to leave without saving?'),
          actions: <Widget>[
            TextButton(
              child: const Text('No'),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
            TextButton(
              child: const Text('Yes'),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
            ),
          ],
        );
      },
    ).then((value) => value == true);
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
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
        isChanged = true;
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
                isChanged = true;
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
  String condition = '==';
  TextEditingController textValueController = TextEditingController();

  var _date = DateTime.now();

  WhereConditionItem createItem() {
    final cond = condition;

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
              hint: const Text('Condition'),
              items: WhereConditionItem.platformConditions.map((e) {
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

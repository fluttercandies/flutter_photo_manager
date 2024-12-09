import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

Future<void> changeWhere(
  BuildContext context,
  List<WhereConditionItem> items,
  ValueChanged<List<WhereConditionItem>> onChanged,
) async {
  _WhereConditionPage._saveItems = null;
  Navigator.push<List<WhereConditionItem>>(
    context,
    MaterialPageRoute(
      builder: (context) => _WhereConditionPage(where: items),
    ),
  ).then((value) {
    value ??= _WhereConditionPage._saveItems;
    if (value != null) {
      onChanged(value);
    }
  });
}

class WhereAction extends StatelessWidget {
  const WhereAction({
    super.key,
    required this.items,
    required this.onChanged,
  });

  final List<WhereConditionItem> items;
  final ValueChanged<List<WhereConditionItem>> onChanged;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        IconButton(
          onPressed: () {
            _WhereConditionPage._saveItems = null;
            Navigator.push<List<WhereConditionItem>>(
              context,
              MaterialPageRoute(
                builder: (context) => _WhereConditionPage(where: items),
              ),
            ).then((value) {
              value ??= _WhereConditionPage._saveItems;
              if (value != null) {
                onChanged(value);
              }
            });
          },
          icon: const Icon(Icons.filter_alt),
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

class _WhereConditionPage extends StatefulWidget {
  const _WhereConditionPage({
    required this.where,
  });

  final List<WhereConditionItem> where;

  static List<WhereConditionItem>? _saveItems;

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
    _WhereConditionPage._saveItems = _where;
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

  Future<void> _createNew() async {
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
  const _CreateWhereDialog();

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

  DateTime _date = DateTime.now();

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
                if (value == null) {
                  return;
                }
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
                if (value == null) {
                  return;
                }
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
            if (date == null) {
              return;
            }
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

import 'dart:io';

import 'package:photo_manager/photo_manager.dart';

/// The logical operator used in the [CustomFilter].
enum LogicalType {
  and,
  or,
}

///
class AdvancedCustomFilter extends CustomFilter {
  final List<WhereConditionItem> _whereItemList;
  final List<OrderByItem> _orderByItemList;

  AdvancedCustomFilter({
    List<WhereConditionItem> where = const [],
    List<OrderByItem> orderBy = const [],
  })  : _whereItemList = where,
        _orderByItemList = orderBy;

  AdvancedCustomFilter addWhereCondition(
    WhereConditionItem condition, {
    LogicalType type = LogicalType.and,
  }) {
    condition.logicalType = type;
    _whereItemList.add(condition);
    return this;
  }

  AdvancedCustomFilter addOrderBy({
    required String column,
    bool isAsc = true,
  }) {
    _orderByItemList.add(OrderByItem(column, isAsc));
    return this;
  }

  @override
  String makeWhere() {
    final sb = StringBuffer();
    for (final item in _whereItemList) {
      if (sb.isNotEmpty) {
        sb.write(' ${item.logicalType == LogicalType.and ? 'AND' : 'OR'} ');
      }
      sb.write(item.text);
    }
    return sb.toString();
  }

  @override
  List<OrderByItem> makeOrderBy() {
    return _orderByItemList;
  }
}

abstract class WhereConditionItem {
  String get text;

  LogicalType logicalType = LogicalType.and;

  WhereConditionItem({this.logicalType = LogicalType.and});

  factory WhereConditionItem.text(String text) {
    return TextWhereCondition(text);
  }

  static final platformValues = _platformValues();

  static List<String> _platformValues() {
    if (Platform.isAndroid) {
      return [
        'is not null',
        'is null',
        '=',
        '!=',
        '>',
        '>=',
        '<',
        '<=',
        'like',
        'not like',
        'in',
        'not in',
        'between',
        'not between',
      ];
    } else if (Platform.isIOS || Platform.isMacOS) {
      // The NSPredicate syntax is used on iOS and macOS.
      return [
        '!= nil',
        '== nil',
        '==',
        '!=',
        '>',
        '>=',
        '<',
        '<=',
        'like',
        'not like',
        'in',
        'not in',
        'between',
        'not between',
      ];
    }
    throw UnsupportedError('Unsupported platform');
  }

  String display() {
    return text;
  }
}

class WhereConditionGroup extends WhereConditionItem {
  final List<WhereConditionItem> items = [];

  WhereConditionGroup();

  WhereConditionGroup and(String text) {
    final item = WhereConditionItem.text(text);
    item.logicalType = LogicalType.and;
    items.add(item);
    return this;
  }

  WhereConditionGroup or(String text) {
    final item = WhereConditionItem.text(text);
    item.logicalType = LogicalType.or;
    items.add(item);
    return this;
  }

  WhereConditionGroup andGroup(WhereConditionGroup group) {
    group.logicalType = LogicalType.and;
    items.add(group);
    return this;
  }

  WhereConditionGroup orGroup(WhereConditionGroup group) {
    group.logicalType = LogicalType.or;
    items.add(group);
    return this;
  }

  @override
  String get text {
    final sb = StringBuffer();
    for (final item in items) {
      if (sb.isNotEmpty) {
        sb.write(' ${item.logicalType == LogicalType.and ? 'AND' : 'OR'} ');
      }
      sb.write(item.text);
    }

    return '( $sb )';
  }

  @override
  String display() {
    final sb = StringBuffer();
    for (final item in items) {
      if (sb.isNotEmpty) {
        sb.write(' ${item.logicalType == LogicalType.and ? 'AND' : 'OR'} ');
      }
      sb.write(item.display());
    }

    return '( $sb )';
  }
}

bool _checkDateColumn(String column) {
  return CustomColumns.dateColumns().contains(column);
}

bool _checkOtherColumn(String column) {
  if (Platform.isAndroid) {
    const android = CustomColumns.android;
    return android.getValues().contains(column);
  } else if (Platform.isIOS || Platform.isMacOS) {
    const darwin = CustomColumns.darwin;
    return darwin.getValues().contains(column);
  }
  return false;
}

class ColumnWhereCondition extends WhereConditionItem {
  final String column;
  final String? operator;
  final String? value;

  final bool needCheck;

  ColumnWhereCondition({
    required this.column,
    required this.operator,
    required this.value,
    this.needCheck = true,
  }) : super();

  @override
  String get text {
    if (needCheck && _checkDateColumn(column)) {
      assert(needCheck && _checkDateColumn(column),
          'The column: $column is date type, please use DateColumnWhereCondition');

      return '';
    }

    if (needCheck && _checkOtherColumn(column)) {
      assert(needCheck && _checkOtherColumn(column),
          'The $column is not support the platform, please check.');
      return '';
    }

    final sb = StringBuffer();
    sb.write(column);
    if (operator != null) {
      sb.write(' ${operator!} ');
    }
    if (value != null) {
      sb.write(value!);
    }
    return sb.toString();
  }
}

class DateColumnWhereCondition extends WhereConditionItem {
  final String column;
  final String? operator;
  final DateTime? value;
  final bool checkColumn;

  DateColumnWhereCondition({
    required this.column,
    this.operator,
    this.value,
    this.checkColumn = true,
  }) : super();

  @override
  String get text {
    if (checkColumn && !_checkDateColumn(column)) {
      assert(checkColumn && !_checkDateColumn(column),
          'The date column just support createDate, modifiedDate, dateTaken, dateExpires');
      return '';
    }
    final sb = StringBuffer();
    sb.write(column);
    if (operator != null) {
      sb.write(' ${operator!} ');
    }
    if (value != null) {
      // special for date taken
      var isSecond = true;
      if (Platform.isAndroid) {
        isSecond = column != CustomColumns.android.dateTaken;
      }
      final sql =
          CustomColumns.utils.convertDateTimeToSql(value!, isSeconds: isSecond);
      sb.write(' $sql');
    }
    return sb.toString();
  }

  @override
  String display() {
    final sb = StringBuffer();
    sb.write(column);
    if (operator != null) {
      sb.write(' ${operator!} ');
    }
    if (value != null) {
      sb.write(' ${value!.toIso8601String()}');
    }
    return sb.toString();
  }
}

class TextWhereCondition extends WhereConditionItem {
  @override
  final String text;

  TextWhereCondition(this.text);
}

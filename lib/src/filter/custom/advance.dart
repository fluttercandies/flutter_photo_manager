// Copyright 2018 The FlutterCandies author. All rights reserved.
// Use of this source code is governed by an Apache license that can be found
// in the LICENSE file.

import 'dart:io';

import 'custom_columns.dart';
import 'custom_filter.dart';
import 'order_by_item.dart';

/// {@template PM.AdvancedCustomFilter}
///
/// The advanced custom filter.
///
/// The [AdvancedCustomFilter] is a more powerful helper.
///
/// Examples:
/// ```dart
/// final filter = AdvancedCustomFilter()
///     .addWhereCondition(
///       ColumnWhereCondition(
///         column: _columns.width,
///         operator: '>=',
///         value: '200',
///       ),
///     )
///     .addOrderBy(column: _columns.createDate, isAsc: false);
/// ```
///
/// {@endtemplate}
class AdvancedCustomFilter extends CustomFilter {
  /// {@macro PM.AdvancedCustomFilter}
  AdvancedCustomFilter({
    List<WhereConditionItem> where = const [],
    List<OrderByItem> orderBy = const [],
  }) {
    _whereItemList.addAll(where);
    _orderByItemList.addAll(orderBy);
  }

  final List<WhereConditionItem> _whereItemList = [];
  final List<OrderByItem> _orderByItemList = [];

  /// Add a [WhereConditionItem] to the filter.
  AdvancedCustomFilter addWhereCondition(
    WhereConditionItem condition, {
    LogicalType type = LogicalType.and,
  }) {
    condition.logicalType = type;
    _whereItemList.add(condition);
    return this;
  }

  /// Add a [OrderByItem] to the filter.
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

/// The logical operator used in the [CustomFilter].
enum LogicalType {
  and,
  or,
}

extension LogicalTypeExtension on LogicalType {
  int get value {
    switch (this) {
      case LogicalType.and:
        return 0;
      case LogicalType.or:
        return 1;
    }
  }
}

/// {@template PM.where_condition_item}
///
/// The where condition item for custom filter.
///
/// {@endtemplate}
abstract class WhereConditionItem {
  /// The default constructor.
  WhereConditionItem({this.logicalType = LogicalType.and});

  /// Create a [WhereConditionItem] from a text.
  factory WhereConditionItem.text(
    String text, {
    LogicalType type = LogicalType.and,
  }) {
    return TextWhereCondition(text, type: type);
  }

  /// The text of the condition.
  String get text;

  /// The logical operator used in the [CustomFilter].
  ///
  /// See also:
  /// - [LogicalType]
  LogicalType logicalType = LogicalType.and;

  /// The platform values.
  ///
  /// The darwin is different from the android.
  ///
  ///
  static final platformConditions = _platformValues();

  static List<String> _platformValues() {
    if (Platform.isAndroid) {
      return [
        'is not null',
        'is null',
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

  /// Same [text] is converted, no readable.
  ///
  /// So, the method result is used for UI to display.
  String display() {
    return text;
  }
}

/// {@template PM.column_where_condition_group}
///
/// The group of [WhereConditionItem] and [WhereConditionGroup].
///
/// If you need like `( width > 1000 AND height > 1000) OR ( width < 500 AND height < 500)`,
/// you can use this class to do it.
///
/// The first item logical type will be ignored.
///
/// ```dart
/// final filter = AdvancedCustomFilter().addWhereCondition(
///   WhereConditionGroup()
///       .andGroup(
///         WhereConditionGroup().andText('width > 1000').andText('height > 1000'),
///       )
///       .orGroup(
///         WhereConditionGroup().andText('width < 500').andText('height < 500'),
///       ),
/// );
/// ```
///
///
/// {@endtemplate}
class WhereConditionGroup extends WhereConditionItem {
  /// {@macro PM.column_where_condition_group}
  WhereConditionGroup();

  final List<WhereConditionItem> items = [];

  /// Add a [WhereConditionItem] to the group.
  ///
  /// The logical type is [LogicalType.or].
  WhereConditionGroup and(WhereConditionItem item) {
    item.logicalType = LogicalType.and;
    items.add(item);
    return this;
  }

  /// Add a [WhereConditionItem] to the group.
  ///
  /// The logical type is [LogicalType.or].
  WhereConditionGroup or(WhereConditionItem item) {
    item.logicalType = LogicalType.or;
    items.add(item);
    return this;
  }

  /// Add a [text] condition to the group.
  ///
  /// The logical type is [LogicalType.and].
  WhereConditionGroup andText(String text) {
    final item = WhereConditionItem.text(text);
    item.logicalType = LogicalType.and;
    items.add(item);
    return this;
  }

  /// Add a [text] condition to the group.
  ///
  /// The logical type is [LogicalType.or].
  WhereConditionGroup orText(String text) {
    final item = WhereConditionItem.text(text);
    item.logicalType = LogicalType.or;
    items.add(item);
    return this;
  }

  /// Add a [WhereConditionItem] to the group.
  ///
  /// The logical type is [LogicalType.and].
  ///
  /// See also:
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
    if (items.isEmpty) {
      return '';
    }

    final sb = StringBuffer();
    for (final item in items) {
      final text = item.text;
      if (text.isEmpty) {
        continue;
      }
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

/// {@template PM.column_where_condition}
///
/// The where condition item.
///
/// The [operator] is the operator of the condition.
///
/// The [value] is the value of the condition.
///
/// {@endtemplate}
class ColumnWhereCondition extends WhereConditionItem {
  /// {@macro PM.column_where_condition}
  ColumnWhereCondition({
    required this.column,
    required this.operator,
    required this.value,
    this.needCheck = true,
  });

  ///  - Android: the column name in the MediaStore database.
  ///  - iOS/macOS: the field with the PHAsset.
  final String column;

  /// `=`, `>`, `>=`, `!=`, `like`, `in`, `between`, `is null`, `is not null`
  final String? operator;

  /// The value of the condition.
  final String? value;

  /// Check the column when the [text] is called. Default is true.
  ///
  /// If false, don't check the column.
  final bool needCheck;

  @override
  String get text {
    if (needCheck && _checkDateColumn(column)) {
      assert(
        needCheck && _checkDateColumn(column),
        'The column: $column is date type, please use DateColumnWhereCondition',
      );
      return '';
    }

    if (needCheck && !_checkOtherColumn(column)) {
      assert(
        needCheck && !_checkOtherColumn(column),
        'The $column is not support the platform, please check.',
      );
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

/// {@template PM.date_column_where_condition}
///
/// The where condition item for date type.
///
/// Because the date type is different between Android and iOS/macOS.
///
/// {@endtemplate}
class DateColumnWhereCondition extends WhereConditionItem {
  DateColumnWhereCondition({
    required this.column,
    required this.operator,
    required this.value,
    this.checkColumn = true,
  }) : super();

  /// The column name of the date type.
  final String column;

  /// such as: `=`, `>`, `>=`, `!=`, `like`, `in`, `between`, `is null`, `is not null`.
  final String operator;

  /// The value of the condition.
  final DateTime value;
  final bool checkColumn;

  @override
  String get text {
    if (checkColumn && !_checkDateColumn(column)) {
      assert(
        checkColumn && !_checkDateColumn(column),
        'Only `createDate`, `modifiedDate`, `dateTaken`,'
        'and `dateExpires` are support.',
      );
      return '';
    }
    final sb = StringBuffer();
    sb.write(column);
    sb.write(' $operator ');
    bool isSecond = true;
    if (Platform.isAndroid) {
      isSecond = column != CustomColumns.android.dateTaken;
    }
    final sql = CustomColumns.utils.convertDateTimeToSql(
      value,
      isSeconds: isSecond,
    );
    sb.write(' $sql');
    return sb.toString();
  }

  @override
  String display() {
    final sb = StringBuffer();
    sb.write(column);
    sb.write(' $operator ');
    sb.write(' ${value.toIso8601String()}');
    return sb.toString();
  }
}

/// {@template PM.text_where_condition}
///
/// The where condition item for text.
///
/// It is recommended to use
/// [DateColumnWhereCondition] or [ColumnWhereCondition] instead of this one,
/// because different platforms may have different syntax.
///
/// If you are an advanced user and insist on using it,
/// please understand the following:
/// - Android: How to write where with `ContentResolver`.
/// - iOS/macOS: How to format `NSPredicate`.
///
/// {@endtemplate}
class TextWhereCondition extends WhereConditionItem {
  /// {@macro PM.text_where_condition}
  TextWhereCondition(
    this.text, {
    LogicalType type = LogicalType.and,
  }) : super(logicalType: type);
  @override
  final String text;
}

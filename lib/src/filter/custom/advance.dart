import 'package:photo_manager/photo_manager.dart';

enum LogicalType {
  and,
  or,
}

class AdvancedCustomFilter extends CustomFilter {
  final List<WhereConditionItem> _whereItemList = [];
  final List<OrderByItem> _orderByItemList = [];

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
}

class TextWhereCondition extends WhereConditionItem {
  @override
  final String text;

  TextWhereCondition(this.text);
}

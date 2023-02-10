import 'package:photo_manager/src/filter/base_filter.dart';

/// Full custom filter.
abstract class CustomFilter extends BaseFilter {
  CustomFilter();

  factory CustomFilter.sql({
    required String where,
    List<OrderByItem> orderBy = const [],
  }) {
    return SqlCustomFilter(where, orderBy);
  }

  @override
  BaseFilterType get type => BaseFilterType.custom;

  @override
  Map<String, dynamic> childMap() {
    return <String, dynamic>{
      'where': makeWhere(),
      'orderBy': makeOrderBy().map((e) => e.toMap()).toList(),
    };
  }

  @override
  BaseFilter updateDateToNow() {
    return this;
  }

  String makeWhere();

  List<OrderByItem> makeOrderBy();
}

class SqlCustomFilter extends CustomFilter {
  final String where;
  final List<OrderByItem> orderBy;

  SqlCustomFilter(this.where, this.orderBy);

  @override
  String makeWhere() {
    return where;
  }

  @override
  List<OrderByItem> makeOrderBy() {
    return orderBy;
  }
}

class OrderByItem {
  final String column;
  final bool isAsc;

  const OrderByItem(this.column, this.isAsc);

  const OrderByItem.desc(this.column) : isAsc = false;

  const OrderByItem.asc(this.column) : isAsc = true;

  const OrderByItem.named({
    required this.column,
    this.isAsc = true,
  });

  Map toMap() {
    return {
      'column': column,
      'isAsc': isAsc,
    };
  }
}

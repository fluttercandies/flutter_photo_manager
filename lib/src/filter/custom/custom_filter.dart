import 'package:photo_manager/src/filter/base_filter.dart';

/// Full custom filter.
abstract class CustomFilter extends BaseFilter {
  CustomFilter();

  factory CustomFilter.sql(String where, String orderBy) {
    return SqlCustomFilter(where, orderBy);
  }

  @override
  BaseFilterType get type => BaseFilterType.custom;

  @override
  Map<String, dynamic> childMap() {
    return <String, dynamic>{
      'where': makeWhere(),
      'orderBy': makeOrderBy(),
    };
  }

  @override
  BaseFilter updateDateToNow() {
    return this;
  }

  String makeWhere();

  String makeOrderBy();
}

class SqlCustomFilter extends CustomFilter {
  String where;
  String orderBy;

  SqlCustomFilter(this.where, this.orderBy);

  @override
  String makeWhere() {
    return where;
  }

  @override
  String makeOrderBy() {
    return orderBy;
  }
}

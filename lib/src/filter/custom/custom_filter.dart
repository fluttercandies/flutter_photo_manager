import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager/src/filter/base_filter.dart';

/// Full custom filter.
///
/// Use the filter to filter all the assets.
///
/// Actually, it is a sql filter.
/// In android: convert where and orderBy to the params of ContentResolver.query
/// In iOS/macOS: convert where and orderBy to the PHFetchOptions to filter the assets.
///
/// Now, the [CustomFilter] is have two sub class:
/// [CustomFilter.sql] to create [SqlCustomFilter].
///
/// The [AdvancedCustomFilter] is a more powerful helper.
///
/// Examples:
/// {@macro PM.sql_custom_filter}
///
/// See also:
/// - [CustomFilter.sql]
/// - [AdvancedCustomFilter]
/// - [OrderByItem]
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

  /// Make the where condition.
  String makeWhere();

  /// Make the order by condition.
  List<OrderByItem> makeOrderBy();
}

/// {@template PM.sql_custom_filter}
///
/// The sql custom filter.
///
/// create example:
///
/// ```dart
/// final filter = CustomFilter.sql(
///  where: '${CustomColumns.base.width} > 1000',
///  orderBy: [
///      OrderByItem(CustomColumns.base.width, desc),
///   ],
/// );
/// ```
///
/// {@endtemplate}
class SqlCustomFilter extends CustomFilter {
  /// The where condition.
  final String where;

  /// The order by condition.
  final List<OrderByItem> orderBy;

  /// {@macro PM.sql_custom_filter}
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

/// {@template PM.order_by_item}
///
/// The order by item.
///
/// Example:
/// ```dart
///   OrderByItem(CustomColumns.base.width, true);
/// ```
///
/// See also:
/// - [CustomFilter]
/// - [CustomColumns.base]
/// - [CustomColumns.android]
/// - [CustomColumns.darwin]
/// - [CustomColumns.platformValues]
///
/// {@endtemplate}
class OrderByItem {

  /// The column name.
  final String column;

  /// The order type.
  final bool isAsc;

  /// {@macro PM.order_by_item}
  const OrderByItem(this.column, this.isAsc);

  /// {@macro PM.order_by_item}
  const OrderByItem.desc(this.column) : isAsc = false;

  /// {@macro PM.order_by_item}
  const OrderByItem.asc(this.column) : isAsc = true;

  /// {@macro PM.order_by_item}
  const OrderByItem.named({
    required this.column,
    this.isAsc = true,
  });

  /// Convert to the map.
  Map toMap() {
    return {
      'column': column,
      'isAsc': isAsc,
    };
  }
}

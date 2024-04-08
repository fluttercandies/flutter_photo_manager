// Copyright 2018 The FlutterCandies author. All rights reserved.
// Use of this source code is governed by an Apache license that can be found
// in the LICENSE file.

import '../base_filter.dart';
import 'order_by_item.dart';

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
abstract class CustomFilter extends PMFilter {
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
      'needTitle': needTitle,
    };
  }

  @override
  PMFilter updateDateToNow() {
    return this;
  }

  /// Whether the [AssetEntity]s will return with title.
  bool needTitle = false;

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
  /// {@macro PM.sql_custom_filter}
  SqlCustomFilter(this.where, this.orderBy);

  /// The where condition.
  final String where;

  /// The order by condition.
  final List<OrderByItem> orderBy;

  @override
  String makeWhere() {
    return where;
  }

  @override
  List<OrderByItem> makeOrderBy() {
    return orderBy;
  }
}

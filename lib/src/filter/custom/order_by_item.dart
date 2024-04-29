// Copyright 2018 The FlutterCandies author. All rights reserved.
// Use of this source code is governed by an Apache license that can be found
// in the LICENSE file.

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

  /// The column name.
  final String column;

  /// The order type.
  final bool isAsc;

  /// Convert to the map.
  Map toMap() {
    return {
      'column': column,
      'isAsc': isAsc,
    };
  }

  @override
  String toString() {
    return 'OrderByItem{column: $column, isAsc: $isAsc}';
  }
}

// Copyright 2018 The FlutterCandies author. All rights reserved.
// Use of this source code is governed by an Apache license that can be found
// in the LICENSE file.

import 'dart:convert';

import 'package:flutter/widgets.dart';

import '../internal/enums.dart';

/// A series of filter options for [AssetType] when querying assets.
@immutable
class FilterOption {
  const FilterOption({
    this.needTitle = false,
    this.sizeConstraint = const SizeConstraint(),
    this.durationConstraint = const DurationConstraint(),
  });

  /// This property affects performance on iOS.
  ///
  /// If not needed, please pass false, default is false.
  final bool needTitle;

  /// See [SizeConstraint]
  final SizeConstraint sizeConstraint;

  /// See [DurationConstraint], ignore in [AssetType.image].
  final DurationConstraint durationConstraint;

  /// Create a new [FilterOption] with specific properties merging.
  FilterOption copyWith({
    bool? needTitle,
    SizeConstraint? sizeConstraint,
    DurationConstraint? durationConstraint,
  }) {
    return FilterOption(
      needTitle: needTitle ?? this.needTitle,
      sizeConstraint: sizeConstraint ?? this.sizeConstraint,
      durationConstraint: durationConstraint ?? this.durationConstraint,
    );
  }

  /// Merge a [FilterOption] into another.
  FilterOption merge(FilterOption other) {
    return FilterOption(
      needTitle: other.needTitle,
      sizeConstraint: other.sizeConstraint,
      durationConstraint: other.durationConstraint,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'title': needTitle,
      'size': sizeConstraint.toMap(),
      'duration': durationConstraint.toMap(),
    };
  }

  @override
  String toString() {
    return const JsonEncoder.withIndent('  ').convert(toMap());
  }

  @override
  bool operator ==(Object other) {
    return other is FilterOption &&
        needTitle == other.needTitle &&
        sizeConstraint == other.sizeConstraint &&
        durationConstraint == other.durationConstraint;
  }

  @override
  int get hashCode => hashValues(needTitle, sizeConstraint, durationConstraint);
}

/// Constraints of asset pixel width and height.
@immutable
class SizeConstraint {
  const SizeConstraint({
    this.minWidth = 0,
    this.maxWidth = 100000,
    this.minHeight = 0,
    this.maxHeight = 100000,
    this.ignoreSize = false,
  });

  final int minWidth;
  final int maxWidth;
  final int minHeight;
  final int maxHeight;

  /// When set to true, all constraints are ignored
  /// and all sizes of images are displayed.
  final bool ignoreSize;

  SizeConstraint copyWith({
    int? minWidth,
    int? maxWidth,
    int? minHeight,
    int? maxHeight,
    bool? ignoreSize,
  }) {
    minWidth ??= this.minWidth;
    maxWidth ??= this.maxHeight;
    minHeight ??= this.minHeight;
    maxHeight ??= this.maxHeight;
    ignoreSize ??= this.ignoreSize;

    return SizeConstraint(
      minWidth: minWidth,
      maxWidth: maxWidth,
      minHeight: minHeight,
      maxHeight: maxHeight,
      ignoreSize: ignoreSize,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'minWidth': minWidth,
      'maxWidth': maxWidth,
      'minHeight': minHeight,
      'maxHeight': maxHeight,
      'ignoreSize': ignoreSize,
    };
  }

  @override
  bool operator ==(Object other) {
    return other is SizeConstraint &&
        minWidth == other.minWidth &&
        maxWidth == other.maxWidth &&
        minHeight == other.minHeight &&
        maxHeight == other.maxHeight &&
        ignoreSize == other.ignoreSize;
  }

  @override
  int get hashCode =>
      hashValues(minWidth, maxWidth, minHeight, maxHeight, ignoreSize);
}

/// Constraints of duration.
///
/// The Image type ignores this constraints.
@immutable
class DurationConstraint {
  const DurationConstraint({
    this.min = Duration.zero,
    this.max = const Duration(days: 1),
    this.allowNullable = false,
  });

  final Duration min;
  final Duration max;

  /// Whether `null` or `nil` duration is allowed when obtaining.
  ///
  /// Be aware, when it's true, the constraint with [min] and [max]
  /// become optional conditions.
  final bool allowNullable;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'min': min.inMilliseconds,
      'max': max.inMilliseconds,
      'allowNullable': allowNullable,
    };
  }

  @override
  bool operator ==(Object other) {
    return other is DurationConstraint &&
        min == other.min &&
        max == other.max &&
        allowNullable == other.allowNullable;
  }

  @override
  int get hashCode => hashValues(min, max, allowNullable);
}

@immutable
class DateTimeCond {
  const DateTimeCond({
    required this.min,
    required this.max,
    this.ignore = false,
  });

  factory DateTimeCond.def() {
    return DateTimeCond(min: zero, max: DateTime.now());
  }

  final DateTime min;
  final DateTime max;
  final bool ignore;

  static final DateTime zero = DateTime.fromMillisecondsSinceEpoch(0);

  DateTimeCond copyWith({
    DateTime? min,
    DateTime? max,
    bool? ignore,
  }) {
    return DateTimeCond(
      min: min ?? this.min,
      max: max ?? this.max,
      ignore: ignore ?? this.ignore,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'min': min.millisecondsSinceEpoch,
      'max': max.millisecondsSinceEpoch,
      'ignore': ignore,
    };
  }

  @override
  bool operator ==(Object other) {
    return other is DateTimeCond &&
        min == other.min &&
        max == other.max &&
        ignore == other.ignore;
  }

  @override
  int get hashCode => hashValues(min, max, ignore);
}

@immutable
class OrderOption {
  const OrderOption({
    this.type = OrderOptionType.createDate,
    this.asc = false,
  });

  final OrderOptionType type;
  final bool asc;

  OrderOption copyWith({OrderOptionType? type, bool? asc}) {
    return OrderOption(
      asc: asc ?? this.asc,
      type: type ?? this.type,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{'type': type.index, 'asc': asc};
  }

  @override
  bool operator ==(Object other) {
    return other is OrderOption && type == other.type && asc == other.asc;
  }

  @override
  int get hashCode => hashValues(type, asc);
}

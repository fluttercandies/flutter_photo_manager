// Copyright 2018 The FlutterCandies author. All rights reserved.
// Use of this source code is governed by an Apache license that can be found
// in the LICENSE file.

import 'dart:convert';

import 'package:flutter/widgets.dart';

import '../../internal/enums.dart';

/// A series of filter options for [AssetType] when querying assets.
@immutable
class FilterOption {
  /// Creates a new instance of the [FilterOption] class.
  ///
  /// * [needTitle]: An optional parameter, defaults to `false`. Specifies whether titles are needed for queried assets.
  /// * [sizeConstraint]: An optional parameter, defaults to `SizeConstraint()`. Specifies the size constraints for queried images.
  /// * [durationConstraint]: An optional parameter, defaults to `DurationConstraint()`. Specifies the duration constraints for queried assets.
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

  /// Returns a new [FilterOption] object with the same properties as this one, but with any specified properties replaced.
  ///
  /// If any parameter is not provided, its value will be taken from this object.
  ///
  /// * [needTitle]: An optional parameter. Specifies whether titles are needed for queried assets.
  /// * [sizeConstraint]: An optional parameter. Specifies the size constraints for queried images.
  /// * [durationConstraint]: An optional parameter. Specifies the duration constraints for queried assets.
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

  /// Returns a new [FilterOption] object with the properties of this object merged with those of another [FilterOption].
  ///
  /// Any non-null property in the provided [other] object will replace the corresponding property in this object.
  ///
  /// * [other]: An optional parameter. The [FilterOption] to merge with this one.
  FilterOption merge(FilterOption? other) {
    return copyWith(
      needTitle: other?.needTitle,
      sizeConstraint: other?.sizeConstraint,
      durationConstraint: other?.durationConstraint,
    );
  }

  /// Returns a [Map] representation of this [FilterOption] object, with keys corresponding to the property names.
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
  int get hashCode =>
      needTitle.hashCode ^
      sizeConstraint.hashCode ^
      durationConstraint.hashCode;
}

/// A class that specifies the size constraints for queried images.
@immutable
class SizeConstraint {
  /// Creates a new instance of the [SizeConstraint] class.
  ///
  /// * [minWidth]: An optional parameter, defaults to `0`. Specifies the minimum width for queried images.
  /// * [maxWidth]: An optional parameter, defaults to `100000`. Specifies the maximum width for queried images.
  /// * [minHeight]: An optional parameter, defaults to `0`. Specifies the minimum height for queried images.
  /// * [maxHeight]: An optional parameter, defaults to `100000`. Specifies the maximum height for queried images.
  /// * [ignoreSize]: An optional parameter, defaults to `false`. If set to `true`, all image sizes will be returned.
  const SizeConstraint({
    this.minWidth = 0,
    this.maxWidth = 100000,
    this.minHeight = 0,
    this.maxHeight = 100000,
    this.ignoreSize = false,
  });

  /// The minimum width for queried images.
  final int minWidth;

  /// The maximum width for queried images.
  final int maxWidth;

  /// The minimum height for queried images.
  final int minHeight;

  /// The maximum height for queried images.
  final int maxHeight;

  /// Specifies whether to ignore the size constraints and return all image sizes.
  ///
  /// If set to `true`, all image sizes will be returned, regardless of size constraints. Otherwise, images must meet the specified size requirements.
  final bool ignoreSize;

  /// Returns a new [SizeConstraint] object with the same properties as this one, but with any specified properties replaced.
  ///
  /// If any parameter is not provided, its value will be taken from this object.
  ///
  /// * [minWidth]: An optional parameter. Specifies the minimum width for queried images.
  /// * [maxWidth]: An optional parameter. Specifies the maximum width for queried images.
  /// * [minHeight]: An optional parameter. Specifies the minimum height for queried images.
  /// * [maxHeight]: An optional parameter. Specifies the maximum height for queried images.
  /// * [ignoreSize]: An optional parameter. If set to `true`, all image sizes will be returned.
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

  /// Returns a [Map] representation of this [SizeConstraint] object, with keys corresponding to the property names.
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
      minWidth.hashCode ^
      maxWidth.hashCode ^
      minHeight.hashCode ^
      maxHeight.hashCode ^
      ignoreSize.hashCode;
}

/// A class that specifies the duration constraints for queried assets.
@immutable
class DurationConstraint {
  /// Creates a new instance of the [DurationConstraint] class.
  ///
  /// * [min]: An optional parameter, defaults to `Duration.zero`. Specifies the minimum duration for queried assets.
  /// * [max]: An optional parameter, defaults to `Duration(days: 1)`. Specifies the maximum duration for queried assets.
  /// * [allowNullable]: An optional parameter, defaults to `false`. If set to `true`, assets with null or undefined durations will be returned.
  const DurationConstraint({
    this.min = Duration.zero,
    this.max = const Duration(days: 1),
    this.allowNullable = false,
  });

  /// The minimum duration for queried assets.
  final Duration min;

  /// The maximum duration for queried assets.
  final Duration max;

  /// Whether `null` or `nil` duration is allowed when obtaining.
  ///
  /// Be aware, when it's true, the constraint with [min] and [max]
  /// become optional conditions.
  final bool allowNullable;

  /// Returns a [Map] representation of this [DurationConstraint] object, with keys corresponding to the property names.
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
  int get hashCode => min.hashCode ^ max.hashCode ^ allowNullable.hashCode;
}

/// A class that specifies the date and time constraints for queried assets.
@immutable
class DateTimeCond {
  /// Creates a new instance of the [DateTimeCond] class.
  ///
  /// * [min]: A required parameter. Specifies the earliest date and time for queried assets.
  /// * [max]: A required parameter. Specifies the latest date and time for queried assets.
  /// * [ignore]: An optional parameter, defaults to `false`. If set to `true`, all assets will be returned, regardless of date and time constraints.
  const DateTimeCond({
    required this.min,
    required this.max,
    this.ignore = false,
  });

  /// Creates a new instance of the [DateTimeCond] class with default values.
  ///
  /// The default values are: `min` set to `DateTime.fromMillisecondsSinceEpoch(0)`, `max` set to the current date and time, and `ignore` set to `false`.
  factory DateTimeCond.def() {
    return DateTimeCond(min: zero, max: DateTime.now());
  }

  /// The earliest date and time for queried assets.
  final DateTime min;

  /// The latest date and time for queried assets.
  final DateTime max;

  /// Specifies whether to ignore the date and time constraints and return all assets.
  ///
  /// If set to `true`, all assets will be returned, regardless of date and time constraints. Otherwise, assets must meet the specified date and time requirements.
  final bool ignore;

  /// The minimum possible date and time value, which is used as a default value for `min`.
  static final DateTime zero = DateTime.fromMillisecondsSinceEpoch(0);

  /// Returns a new [DateTimeCond] object with the same properties as this one, but with any specified properties replaced.
  ///
  /// If any parameter is not provided, its value will be taken from this object.
  ///
  /// * [min]: An optional parameter. Specifies the earliest date and time for queried assets.
  /// * [max]: An optional parameter. Specifies the latest date and time for queried assets.
  /// * [ignore]: An optional parameter. If set to `true`, all assets will be returned, regardless of date and time constraints.
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

  /// Returns a [Map] representation of this [DateTimeCond] object, with keys corresponding to the property names.
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
  int get hashCode => min.hashCode ^ max.hashCode ^ ignore.hashCode;
}

/// A class that specifies the ordering criteria for queried assets.
@immutable
class OrderOption {
  /// Creates a new instance of the [OrderOption] class.
  ///
  /// * [type]: An optional parameter, defaults to [OrderOptionType.createDate]. Specifies the type of order to apply.
  /// * [asc]: An optional parameter, defaults to `false`. If set to `true`, the result will be sorted in ascending order. Otherwise, it will be sorted in descending order.
  const OrderOption({
    this.type = OrderOptionType.createDate,
    this.asc = false,
  });

  /// The type of order to apply.
  final OrderOptionType type;

  /// Specifies whether to sort the result in ascending order.
  ///
  /// If set to `true`, the result will be sorted in ascending order. Otherwise, it will be sorted in descending order.
  final bool asc;

  /// Returns a new [OrderOption] object with the same properties as this one, but with any specified properties replaced.
  ///
  /// If any parameter is not provided, its value will be taken from this object.
  ///
  /// * [type]: An optional parameter. Specifies the type of order to apply.
  /// * [asc]: An optional parameter. If set to `true`, the result will be sorted in ascending order. Otherwise, it will be sorted in descending order.
  OrderOption copyWith({OrderOptionType? type, bool? asc}) {
    return OrderOption(
      asc: asc ?? this.asc,
      type: type ?? this.type,
    );
  }

  /// Returns a [Map] representation of this [OrderOption] object, with keys corresponding to the property names.
  Map<String, dynamic> toMap() {
    return <String, dynamic>{'type': type.index, 'asc': asc};
  }

  @override
  bool operator ==(Object other) {
    return other is OrderOption && type == other.type && asc == other.asc;
  }

  @override
  int get hashCode => type.hashCode ^ asc.hashCode;
}

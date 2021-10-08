import 'dart:convert';

import '../internal/enums.dart';

/// A series of filter options for [AssetType] when querying assets.
class FilterOption {
  const FilterOption({
    this.needTitle = false,
    this.sizeConstraint = const SizeConstraint(),
    this.durationConstraint = const DurationConstraint(),
  });

  /// This property affects performance on iOS. If not needed, please pass false, default is false.
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
    return {
      'title': needTitle,
      'size': sizeConstraint.toMap(),
      'duration': durationConstraint.toMap(),
    };
  }

  @override
  String toString() {
    return const JsonEncoder.withIndent('  ').convert(toMap());
  }
}

/// Constraints of asset pixel width and height.
class SizeConstraint {
  final int minWidth;
  final int maxWidth;
  final int minHeight;
  final int maxHeight;

  /// When set to true, all constraints are ignored and all sizes of images are displayed.
  final bool ignoreSize;

  const SizeConstraint({
    this.minWidth = 0,
    this.maxWidth = 100000,
    this.minHeight = 0,
    this.maxHeight = 100000,
    this.ignoreSize = false,
  });

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
    return {
      'minWidth': minWidth,
      'maxWidth': maxWidth,
      'minHeight': minHeight,
      'maxHeight': maxHeight,
      'ignoreSize': ignoreSize,
    };
  }
}

/// Constraints of duration.
///
/// The Image type ignores this constraints.
class DurationConstraint {
  final Duration min;
  final Duration max;

  const DurationConstraint({
    this.min = Duration.zero,
    this.max = const Duration(days: 1),
  });

  Map<String, dynamic> toMap() {
    return {
      'min': min.inMilliseconds,
      'max': max.inMilliseconds,
    };
  }
}

/// CreateDate
class DateTimeCond {
  static final DateTime zero = DateTime.fromMillisecondsSinceEpoch(0);

  final DateTime min;
  final DateTime max;
  final bool ignore;

  const DateTimeCond({
    required this.min,
    required this.max,
    this.ignore = false,
  });

  factory DateTimeCond.def() {
    return DateTimeCond(
      min: zero,
      max: DateTime.now(),
    );
  }

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
    return {
      'min': min.millisecondsSinceEpoch,
      'max': max.millisecondsSinceEpoch,
      'ignore': ignore,
    };
  }
}

class OrderOption {
  final OrderOptionType type;
  final bool asc;

  const OrderOption({
    this.type = OrderOptionType.createDate,
    this.asc = false,
  });

  OrderOption copyWith({
    OrderOptionType? type,
    bool? asc,
  }) {
    return OrderOption(
      asc: asc ?? this.asc,
      type: type ?? this.type,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type.index,
      'asc': asc,
    };
  }
}

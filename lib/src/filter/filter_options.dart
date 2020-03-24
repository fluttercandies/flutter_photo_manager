import '../type.dart';

/// Filter option for get asset.
///
/// 筛选选项, 可以分别设置图片类型和视频类型对应的[FilterOption]
///
/// See [FilterOption]
class FilterOptionGroup {
  /// A empty option
  FilterOptionGroup.empty();

  FilterOptionGroup() {
    setOption(AssetType.image, FilterOption());
    setOption(AssetType.video, FilterOption());
    setOption(AssetType.audio, FilterOption());
  }

  final Map<AssetType, FilterOption> _map = {};

  DateTimeCond dateTimeCond = DateTimeCond.def();

  void setOption(AssetType type, FilterOption option) {
    _map[type] = option;
  }

  Map<String, dynamic> toMap() {
    Map<String, dynamic> result = {};
    if (_map.containsKey(AssetType.image)) {
      result["image"] = _map[AssetType.image].toMap();
    }
    if (_map.containsKey(AssetType.video)) {
      result["video"] = _map[AssetType.video].toMap();
    }
    if (_map.containsKey(AssetType.video)) {
      result["audio"] = _map[AssetType.audio].toMap();
    }

    result["date"] = dateTimeCond.toMap();

    return result;
  }
}

/// Filter option
///
/// 筛选选项的详细情况
class FilterOption {
  /// This property affects performance on iOS. If not needed, please pass false, default is false.
  final bool needTitle;

  /// See [SizeConstraint]
  final SizeConstraint sizeConstraint;

  /// See [DurationConstraint], ignore in [AssetType.image].
  final DurationConstraint durationConstraint;

  /// See [needTitle], [sizeConstraint] and [durationConstraint]
  const FilterOption({
    this.needTitle = false,
    this.sizeConstraint = const SizeConstraint(),
    this.durationConstraint = const DurationConstraint(),
  });

  Map<String, dynamic> toMap() {
    return {
      "title": needTitle,
      "size": sizeConstraint.toMap(),
      "duration": durationConstraint.toMap(),
    };
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

  Map<String, dynamic> toMap() {
    return {
      "minWidth": minWidth,
      "maxWidth": maxWidth,
      "minHeight": minHeight,
      "maxHeight": maxHeight,
      "ignoreSize": ignoreSize,
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
      "min": min.inMilliseconds,
      "max": max.inMilliseconds,
    };
  }
}

class DateTimeCond {
  static final DateTime zero = DateTime.utc(0);

  final DateTime min;
  final DateTime max;
  final bool asc;

  const DateTimeCond({
    this.min,
    this.max,
    this.asc = false, // default desc
  })  : assert(min != null),
        assert(max != null),
        assert(asc != null);

  factory DateTimeCond.def() {
    return DateTimeCond(
      min: zero,
      max: DateTime.now(),
      asc: false,
    );
  }

  DateTimeCond copyWith({
    final DateTime min,
    final DateTime max,
    final bool asc,
  }) {
    return DateTimeCond(
      min: min ?? this.min,
      max: max ?? this.max,
      asc: asc ?? this.asc,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      "min": min.millisecondsSinceEpoch,
      "max": max.millisecondsSinceEpoch,
      "asc": asc,
    };
  }
}

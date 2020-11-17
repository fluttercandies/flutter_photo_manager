import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../type.dart';

/// Filter option for get asset.
///
/// 筛选选项, 可以分别设置图片类型和视频类型对应的[FilterOption]
///
/// See [FilterOption]
class FilterOptionGroup {
  /// An empty option
  FilterOptionGroup.empty();

  FilterOptionGroup() {
    setOption(AssetType.image, FilterOption());
    setOption(AssetType.video, FilterOption());
    setOption(AssetType.audio, FilterOption());
    addOrderOption(OrderOption(
      type: OrderOptionType.createDate,
      asc: false,
    ));
  }

  final Map<AssetType, FilterOption> _map = {};

  /// 是否包含空相册
  ///
  /// Whether to include an empty album
  var containsEmptyAlbum = false;

  @Deprecated('Please use createTimeCond.')
  DateTimeCond get dateTimeCond => createTimeCond;

  @Deprecated('Please use createTimeCond.')
  set dateTimeCond(DateTimeCond dateTimeCond) {
    createTimeCond = dateTimeCond;
  }

  DateTimeCond createTimeCond = DateTimeCond.def();
  DateTimeCond updateTimeCond = DateTimeCond.def().copyWith(
    ignore: true,
  );

  FilterOption getOption(AssetType type) {
    return _map[type];
  }

  void setOption(AssetType type, FilterOption option) {
    _map[type] = option;
  }

  final orders = <OrderOption>[];

  void addOrderOption(OrderOption option) {
    orders.add(option);
  }

  void merge(FilterOptionGroup other) {
    assert(other != null, 'Cannot merge null.');
    for (final AssetType type in _map.keys) {
      _map[type] = _map[type]?.merge(other.getOption(type));
    }
    this.containsEmptyAlbum = other.containsEmptyAlbum;
  }

  Map<String, dynamic> toMap() {
    Map<String, dynamic> result = {};
    if (_map.containsKey(AssetType.image)) {
      result["image"] = _map[AssetType.image].toMap();
    }
    if (_map.containsKey(AssetType.video)) {
      result["video"] = _map[AssetType.video].toMap();
    }
    if (_map.containsKey(AssetType.audio)) {
      result["audio"] = _map[AssetType.audio].toMap();
    }

    result["createDate"] = createTimeCond.toMap();
    result["updateDate"] = updateTimeCond.toMap();
    result['containsEmptyAlbum'] = containsEmptyAlbum;
    result['orders'] = orders.map((e) => e.toMap()).toList();

    return result;
  }

  FilterOptionGroup copyWith({
    FilterOption imageOption,
    FilterOption videoOption,
    FilterOption audioOption,
    DateTimeCond createTimeCond,
    DateTimeCond updateTimeCond,
    bool containsEmptyAlbum,
    List<OrderOption> orders,
  }) {
    imageOption ??= _map[AssetType.image];
    videoOption ??= _map[AssetType.video];
    audioOption ??= _map[AssetType.audio];

    createTimeCond ??= this.createTimeCond;
    updateTimeCond ??= this.updateTimeCond;

    containsEmptyAlbum ??= this.containsEmptyAlbum;

    orders ??= this.orders;

    final result = FilterOptionGroup();

    result.setOption(AssetType.image, imageOption);
    result.setOption(AssetType.video, videoOption);
    result.setOption(AssetType.audio, audioOption);

    result.createTimeCond = createTimeCond;
    result.updateTimeCond = updateTimeCond;

    result.containsEmptyAlbum = containsEmptyAlbum;

    result.orders.addAll(orders);

    return result;
  }

  @override
  String toString() {
    return const JsonEncoder.withIndent('  ').convert(toMap());
  }
}

/// Filter option
///
/// 筛选选项的详细情况
class FilterOption {
  /// See [needTitle], [sizeConstraint] and [durationConstraint]
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
    bool needTitle,
    SizeConstraint sizeConstraint,
    DurationConstraint durationConstraint,
  }) {
    return FilterOption(
      needTitle: needTitle ?? this.needTitle,
      sizeConstraint: sizeConstraint ?? this.sizeConstraint,
      durationConstraint: durationConstraint ?? this.durationConstraint,
    );
  }

  /// Merge a [FilterOption] into another.
  FilterOption merge(FilterOption other) {
    assert(other != null, 'Cannot merge null.');
    return FilterOption(
      needTitle: other.needTitle ?? this.needTitle,
      sizeConstraint: other.sizeConstraint ?? this.sizeConstraint,
      durationConstraint: other.durationConstraint ?? this.durationConstraint,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      "title": needTitle,
      "size": sizeConstraint.toMap(),
      "duration": durationConstraint.toMap(),
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
    int minWidth,
    int maxWidth,
    int minHeight,
    int maxHeight,
    bool ignoreSize,
  }) {
    minWidth ??= this.minWidth;
    maxWidth ??= this.maxHeight;

    maxWidth ??= this.maxHeight;
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

/// CreateDate
class DateTimeCond {
  static final DateTime zero = DateTime.fromMillisecondsSinceEpoch(0);

  final DateTime min;
  final DateTime max;
  final bool ignore;

  const DateTimeCond({
    @required this.min,
    @required this.max,
    this.ignore = false,
  })  : assert(min != null),
        assert(max != null);

  factory DateTimeCond.def() {
    return DateTimeCond(
      min: zero,
      max: DateTime.now(),
    );
  }

  DateTimeCond copyWith({
    final DateTime min,
    final DateTime max,
    final bool ignore,
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
    OrderOptionType type,
    bool asc,
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

enum OrderOptionType {
  createDate,
  updateDate,
}

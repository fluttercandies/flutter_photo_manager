// Copyright 2018 The FlutterCandies author. All rights reserved.
// Use of this source code is governed by an Apache license that can be found
// in the LICENSE file.

import 'dart:convert';

import '../../internal/enums.dart';
import '../base_filter.dart';
import 'filter_options.dart';

/// A collection of filtering and sorting options for querying assets.
///
/// Use this class to specify how to filter and sort a set of assets returned by [PhotoManager].
///
/// The [FilterOptionGroup] object contains several [FilterOption] objects, one for each type of asset (image, video, audio).
/// You can set specific filtering and sorting options for each type of asset using the corresponding [FilterOption] object.
///
/// Additionally, you can specify whether to include modified path results, whether to include live photos,
/// or whether to only include live photos, using the appropriate properties of this object.
///
/// Finally, you can use the [orders] property to specify sorting options for the results.
class FilterOptionGroup extends PMFilter {
  /// Construct a default options group.
  ///
  /// Parameters:
  ///
  /// * `imageOption`: The option for filtering image assets. Defaults to [FilterOption].
  /// * `videoOption`: The option for filtering video assets. Defaults to [FilterOption].
  /// * `audioOption`: The option for filtering audio assets. Defaults to [FilterOption].
  /// * `containsPathModified`: Whether the result should contain assets whose file path has been modified. Defaults to `false`.
  /// * `containsLivePhotos`: Whether the result should contain live photos. This option only takes effects on iOS. Defaults to `true`.
  /// * `onlyLivePhotos`: Whether the result should only contain live photos. This option only takes effects on iOS and when the request type is image. Defaults to `false`.
  /// * `createTimeCond`: The condition for filtering asset creation time. See [DateTimeCond] for more information. Defaults to `DateTimeCond.def()`.
  /// * `updateTimeCond`: The condition for filtering asset update time. See [DateTimeCond] for more information. By default, this option is ignored.
  /// * `orders`: A list of options for sorting the results. Defaults to an empty list.
  FilterOptionGroup({
    FilterOption imageOption = const FilterOption(),
    FilterOption videoOption = const FilterOption(),
    FilterOption audioOption = const FilterOption(),
    bool containsPathModified = false,
    @Deprecated(
      'The option will be always enabled by default. '
      'This will be removed in v4.0.0',
    )
    this.containsLivePhotos = true,
    this.onlyLivePhotos = false,
    DateTimeCond? createTimeCond,
    DateTimeCond? updateTimeCond,
    List<OrderOption> orders = const <OrderOption>[],
    bool includeHiddenAssets = false,
  }) {
    super.containsPathModified = containsPathModified;
    super.includeHiddenAssets = includeHiddenAssets;
    _map[AssetType.image] = imageOption;
    _map[AssetType.video] = videoOption;
    _map[AssetType.audio] = audioOption;
    this.createTimeCond = createTimeCond ?? this.createTimeCond;
    this.updateTimeCond = updateTimeCond ?? this.updateTimeCond;
    this.orders.addAll(orders);
  }

  /// Construct an empty options group.
  ///
  /// Returns a new [FilterOptionGroup] instance with default options for all asset types and no other filters applied.
  FilterOptionGroup.empty();

  /// Whether to obtain only live photos.
  ///
  /// This option only takes effects on iOS and when the request type is image.
  bool onlyLivePhotos = false;

  /// Whether the result should contain live photos.
  ///
  /// Defaults to `true`.
  ///
  /// This option only takes effects on iOS.
  @Deprecated(
    'The option will be always enabled by default. '
    'This will be removed in v4.0.0',
  )
  bool containsLivePhotos = true;

  final Map<AssetType, FilterOption> _map = <AssetType, FilterOption>{};

  /// Get the [FilterOption] object for the specified [AssetType].
  ///
  /// Parameters:
  ///
  /// * `type`: The type of asset.
  ///
  /// Returns the [FilterOption] object associated with the specified [AssetType].
  FilterOption getOption(AssetType type) => _map[type]!;

  /// Set the [FilterOption] object for the specified [AssetType].
  ///
  /// Parameters:
  ///
  /// * `type`: The type of asset to set the [FilterOption] for.
  /// * `option`: The new [FilterOption] to set.
  void setOption(AssetType type, FilterOption option) {
    _map[type] = option;
  }

  /// The condition for filtering asset creation time.
  ///
  /// Defaults to `DateTimeCond.def()`.
  ///
  /// See [DateTimeCond] for more information on how to specify date and time conditions.
  DateTimeCond createTimeCond = DateTimeCond.def();

  /// The condition for filtering asset update time.
  ///
  /// By default, this option is ignored.
  ///
  /// See [DateTimeCond] for more information on how to specify date and time conditions.
  DateTimeCond updateTimeCond = DateTimeCond.def().copyWith(ignore: true);

  /// A list of options for sorting the results.
  ///
  /// By default, the order is not specified.
  ///
  /// See [OrderOption] for more information on how to specify sorting options.
  final List<OrderOption> orders = <OrderOption>[];

  /// Adds an [OrderOption] to the list of sorting options.
  ///
  /// Parameters:
  ///
  /// * `option`: The [OrderOption] to add to the list.
  void addOrderOption(OrderOption option) {
    orders.add(option);
  }

  /// Merges another [FilterOptionGroup] into this one.
  ///
  /// Parameters:
  ///
  /// * `other`: The [FilterOptionGroup] to merge into this one.
  void merge(FilterOptionGroup other) {
    for (final AssetType type in _map.keys) {
      _map[type] = _map[type]!.merge(other.getOption(type));
    }
    containsPathModified = other.containsPathModified;
    containsLivePhotos = other.containsLivePhotos;
    includeHiddenAssets = other.includeHiddenAssets;
    onlyLivePhotos = other.onlyLivePhotos;
    createTimeCond = other.createTimeCond;
    updateTimeCond = other.updateTimeCond;
    orders
      ..clear()
      ..addAll(other.orders);
  }

  @override
  FilterOptionGroup updateDateToNow() {
    return copyWith(
      createTimeCond: createTimeCond.copyWith(
        max: DateTime.now(),
      ),
      updateTimeCond: updateTimeCond.copyWith(
        max: DateTime.now(),
      ),
    );
  }

  @override
  Map<String, dynamic> childMap() {
    return <String, dynamic>{
      if (_map.containsKey(AssetType.image))
        'image': getOption(AssetType.image).toMap(),
      if (_map.containsKey(AssetType.video))
        'video': getOption(AssetType.video).toMap(),
      if (_map.containsKey(AssetType.audio))
        'audio': getOption(AssetType.audio).toMap(),
      'createDate': createTimeCond.toMap(),
      'updateDate': updateTimeCond.toMap(),
      'orders': orders.map((OrderOption e) => e.toMap()).toList(),
      'containsLivePhotos': containsLivePhotos,
      'onlyLivePhotos': onlyLivePhotos,
    };
  }

  /// Returns a new [FilterOptionGroup] with the same options as this one, but with some options replaced.
  ///
  /// Parameters:
  ///
  /// * `imageOption`: New image filter option. Defaults to the current object's option.
  /// * `videoOption`: New video filter option. Defaults to the current object's option.
  /// * `audioOption`: New audio filter option. Defaults to the current object's option.
  /// * `containsPathModified`: Whether to include results with modified paths. Defaults to the same as the current object.
  /// * `containsLivePhotos`: Whether to include live photos. Defaults to the same as the current object.
  /// * `onlyLivePhotos`: Whether to include only live photos. Defaults to the same as the current object.
  /// * `createTimeCond`: Date and time conditions for filtering creation time. Defaults to the same as the current object.
  /// * `updateTimeCond`: Date and time conditions for filtering update time. Defaults to the same as the current object.
  /// * `orders`: Sorting options for the results. Defaults to the same as the current object.
  ///
  /// Returns a new [FilterOptionGroup] object with the specified options.
  FilterOptionGroup copyWith({
    FilterOption? imageOption,
    FilterOption? videoOption,
    FilterOption? audioOption,
    bool? containsPathModified,
    bool? includeHiddenAssets,
    @Deprecated(
      'The option will be enabled by default. '
      'This will be removed in v4.0.0',
    )
    bool? containsLivePhotos,
    bool? onlyLivePhotos,
    DateTimeCond? createTimeCond,
    DateTimeCond? updateTimeCond,
    List<OrderOption>? orders,
  }) {
    imageOption ??= _map[AssetType.image];
    videoOption ??= _map[AssetType.video];
    audioOption ??= _map[AssetType.audio];
    containsPathModified ??= this.containsPathModified;
    containsLivePhotos ??= this.containsLivePhotos;
    onlyLivePhotos ??= this.onlyLivePhotos;
    createTimeCond ??= this.createTimeCond;
    updateTimeCond ??= this.updateTimeCond;
    orders ??= this.orders;
    includeHiddenAssets ??= this.includeHiddenAssets;

    final FilterOptionGroup result = FilterOptionGroup()
      ..setOption(AssetType.image, imageOption!)
      ..setOption(AssetType.video, videoOption!)
      ..setOption(AssetType.audio, audioOption!)
      ..containsPathModified = containsPathModified
      ..includeHiddenAssets = includeHiddenAssets
      ..containsLivePhotos = containsLivePhotos
      ..onlyLivePhotos = onlyLivePhotos
      ..createTimeCond = createTimeCond
      ..updateTimeCond = updateTimeCond
      ..orders.addAll(orders);

    return result;
  }

  @override
  String toString() {
    return const JsonEncoder.withIndent('  ').convert(toMap());
  }

  @override
  BaseFilterType get type => BaseFilterType.classical;
}

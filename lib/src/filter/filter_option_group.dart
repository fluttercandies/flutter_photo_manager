// Copyright 2018 The FlutterCandies author. All rights reserved.
// Use of this source code is governed by an Apache license that can be found
// in the LICENSE file.

import 'dart:convert';

import '../internal/enums.dart';
import 'filter_options.dart';

/// The group class to obtain [FilterOption]s.
class FilterOptionGroup {
  /// Construct a default options group.
  FilterOptionGroup({
    FilterOption imageOption = const FilterOption(),
    FilterOption videoOption = const FilterOption(),
    FilterOption audioOption = const FilterOption(),
    this.containsEmptyAlbum = false,
    this.containsPathModified = false,
    this.containsLivePhotos = true,
    this.onlyLivePhotos = false,
    DateTimeCond? createTimeCond,
    DateTimeCond? updateTimeCond,
    List<OrderOption> orders = const <OrderOption>[],
  }) {
    _map[AssetType.image] = imageOption;
    _map[AssetType.video] = videoOption;
    _map[AssetType.audio] = audioOption;
    this.createTimeCond = createTimeCond ?? this.createTimeCond;
    this.updateTimeCond = updateTimeCond ?? this.updateTimeCond;
    this.orders.addAll(orders);
  }

  /// Construct an empty options group.
  FilterOptionGroup.empty();

  final Map<AssetType, FilterOption> _map = <AssetType, FilterOption>{};

  /// Get the [FilterOption] according the specfic [AssetType].
  FilterOption getOption(AssetType type) => _map[type]!;

  /// Set the [FilterOption] according the specfic [AssetType].
  void setOption(AssetType type, FilterOption option) {
    _map[type] = option;
  }

  /// Whether to obtain empty albums.
  bool containsEmptyAlbum = false;

  /// Whether the [AssetPathEntity]s will return with modified time.
  ///
  /// This option is performance-consuming. Use with cautius.
  ///
  /// See also:
  ///  * [AssetPathEntity.lastModified].
  bool containsPathModified = false;

  /// Whether to obtain live photos.
  ///
  /// This option only takes effects on iOS.
  bool containsLivePhotos = true;

  /// Whether to obtain only live photos.
  ///
  /// This option only takes effects on iOS and when the request type is image.
  bool onlyLivePhotos = false;

  DateTimeCond createTimeCond = DateTimeCond.def();
  DateTimeCond updateTimeCond = DateTimeCond.def().copyWith(ignore: true);

  final List<OrderOption> orders = <OrderOption>[];

  void addOrderOption(OrderOption option) {
    orders.add(option);
  }

  void merge(FilterOptionGroup other) {
    for (final AssetType type in _map.keys) {
      _map[type] = _map[type]!.merge(other.getOption(type));
    }
    containsEmptyAlbum = other.containsEmptyAlbum;
    containsPathModified = other.containsPathModified;
    containsLivePhotos = other.containsLivePhotos;
    onlyLivePhotos = other.onlyLivePhotos;
    createTimeCond = other.createTimeCond;
    updateTimeCond = other.updateTimeCond;
    orders
      ..clear()
      ..addAll(other.orders);
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      if (_map.containsKey(AssetType.image))
        'image': getOption(AssetType.image).toMap(),
      if (_map.containsKey(AssetType.video))
        'video': getOption(AssetType.video).toMap(),
      if (_map.containsKey(AssetType.audio))
        'audio': getOption(AssetType.audio).toMap(),
      'containsEmptyAlbum': containsEmptyAlbum,
      'containsPathModified': containsPathModified,
      'containsLivePhotos': containsLivePhotos,
      'onlyLivePhotos': onlyLivePhotos,
      'createDate': createTimeCond.toMap(),
      'updateDate': updateTimeCond.toMap(),
      'orders': orders.map((OrderOption e) => e.toMap()).toList(),
    };
  }

  FilterOptionGroup copyWith({
    FilterOption? imageOption,
    FilterOption? videoOption,
    FilterOption? audioOption,
    bool? containsEmptyAlbum,
    bool? containsPathModified,
    bool? containsLivePhotos,
    bool? onlyLivePhotos,
    DateTimeCond? createTimeCond,
    DateTimeCond? updateTimeCond,
    List<OrderOption>? orders,
  }) {
    imageOption ??= _map[AssetType.image];
    videoOption ??= _map[AssetType.video];
    audioOption ??= _map[AssetType.audio];
    containsEmptyAlbum ??= this.containsEmptyAlbum;
    containsPathModified ??= this.containsPathModified;
    containsLivePhotos ??= this.containsLivePhotos;
    onlyLivePhotos ??= this.onlyLivePhotos;
    createTimeCond ??= this.createTimeCond;
    updateTimeCond ??= this.updateTimeCond;
    orders ??= this.orders;

    final FilterOptionGroup result = FilterOptionGroup()
      ..setOption(AssetType.image, imageOption!)
      ..setOption(AssetType.video, videoOption!)
      ..setOption(AssetType.audio, audioOption!)
      ..containsEmptyAlbum = containsEmptyAlbum
      ..containsPathModified = containsPathModified
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
}

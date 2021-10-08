import 'dart:convert';

import '../internal/enums.dart';
import 'filter_options.dart';

/// The group class to obtain [FilterOption]s.
class FilterOptionGroup {
  static final _defaultOrderOption = OrderOption(
    type: OrderOptionType.updateDate,
    asc: false,
  );

  /// Construct a default options group.
  FilterOptionGroup({
    FilterOption imageOption = const FilterOption(),
    FilterOption videoOption = const FilterOption(),
    FilterOption audioOption = const FilterOption(),
    bool containsEmptyAlbum = false,
    bool containsPathModified = false,
    DateTimeCond? createTimeCond,
    DateTimeCond? updateTimeCond,
    List<OrderOption> orders = const [],
  }) {
    _map[AssetType.image] = imageOption;
    _map[AssetType.video] = videoOption;
    _map[AssetType.audio] = audioOption;
    this.containsEmptyAlbum = containsEmptyAlbum;
    this.containsPathModified = containsPathModified;
    this.createTimeCond = createTimeCond ?? this.createTimeCond;
    this.updateTimeCond = updateTimeCond ?? this.updateTimeCond;
    this.orders.addAll(orders);
  }

  /// Construct an empty options group.
  FilterOptionGroup.empty();

  final Map<AssetType, FilterOption> _map = {};

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

  DateTimeCond createTimeCond = DateTimeCond.def();
  DateTimeCond updateTimeCond = DateTimeCond.def().copyWith(ignore: true);

  final orders = <OrderOption>[];

  void addOrderOption(OrderOption option) {
    orders.add(option);
  }

  void merge(FilterOptionGroup other) {
    for (final AssetType type in _map.keys) {
      _map[type] = _map[type]!.merge(other.getOption(type));
    }
    this.containsEmptyAlbum = other.containsEmptyAlbum;
    this.containsPathModified = other.containsPathModified;
    this.createTimeCond = other.createTimeCond;
    this.updateTimeCond = other.updateTimeCond;
    this.orders
      ..clear()
      ..addAll(other.orders);
  }

  Map<String, dynamic> toMap() {
    Map<String, dynamic> result = {
      if (_map.containsKey(AssetType.image))
        'image': getOption(AssetType.image).toMap(),
      if (_map.containsKey(AssetType.video))
        'video': getOption(AssetType.video).toMap(),
      if (_map.containsKey(AssetType.audio))
        'audio': getOption(AssetType.audio).toMap(),
      'containsEmptyAlbum': containsEmptyAlbum,
      'containsPathModified': containsPathModified,
      'createDate': createTimeCond.toMap(),
      'updateDate': updateTimeCond.toMap(),
    };

    final ordersList = List<OrderOption>.of(orders);
    if (ordersList.isEmpty) {
      ordersList.add(_defaultOrderOption);
    }
    result['orders'] = ordersList.map((e) => e.toMap()).toList();

    return result;
  }

  FilterOptionGroup copyWith({
    FilterOption? imageOption,
    FilterOption? videoOption,
    FilterOption? audioOption,
    DateTimeCond? createTimeCond,
    DateTimeCond? updateTimeCond,
    bool? containsEmptyAlbum,
    bool? containsPathModified,
    List<OrderOption>? orders,
  }) {
    imageOption ??= _map[AssetType.image];
    videoOption ??= _map[AssetType.video];
    audioOption ??= _map[AssetType.audio];
    containsEmptyAlbum ??= this.containsEmptyAlbum;
    containsPathModified ??= this.containsPathModified;
    createTimeCond ??= this.createTimeCond;
    updateTimeCond ??= this.updateTimeCond;
    orders ??= this.orders;

    final result = FilterOptionGroup()
      ..setOption(AssetType.image, imageOption!)
      ..setOption(AssetType.video, videoOption!)
      ..setOption(AssetType.audio, audioOption!)
      ..createTimeCond = createTimeCond
      ..updateTimeCond = updateTimeCond
      ..containsEmptyAlbum = containsEmptyAlbum
      ..containsPathModified = containsPathModified
      ..orders.addAll(orders);

    return result;
  }

  @override
  String toString() {
    return const JsonEncoder.withIndent('  ').convert(toMap());
  }
}

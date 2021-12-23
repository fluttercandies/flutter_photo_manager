import 'dart:collection';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:photo_manager/photo_manager.dart';

typedef EvictionHandler<K, V> = Function(K key, V value);

class LRUMap<K, V> {
  LRUMap(this._maxSize, [this._handler]);

  final LinkedHashMap<K, V?> _map = LinkedHashMap<K, V?>();
  final int _maxSize;
  final EvictionHandler<K, V?>? _handler;

  V? get(K key) {
    final V? value = _map.remove(key);
    if (value != null) {
      _map[key] = value;
    }
    return value;
  }

  void put(K key, V value) {
    _map.remove(key);
    _map[key] = value;
    if (_map.length > _maxSize) {
      final K evictedKey = _map.keys.first;
      final V? evictedValue = _map.remove(evictedKey);
      if (_handler != null) {
        _handler!(evictedKey, evictedValue);
      }
    }
  }

  void remove(K key) {
    _map.remove(key);
  }
}

class ImageLruCache {
  const ImageLruCache._();

  static final LRUMap<_ImageCacheEntity, Uint8List> _map =
      LRUMap<_ImageCacheEntity, Uint8List>(500);

  static Uint8List? getData(
    AssetEntity entity, [
    int size = 64,
    ThumbFormat format = ThumbFormat.jpeg,
  ]) {
    return _map.get(_ImageCacheEntity(entity, size, format));
  }

  static void setData(
    AssetEntity entity,
    int size,
    ThumbFormat format,
    Uint8List list,
  ) {
    _map.put(_ImageCacheEntity(entity, size, format), list);
  }
}

@immutable
class _ImageCacheEntity {
  const _ImageCacheEntity(this.entity, this.size, this.format);

  final AssetEntity entity;
  final int size;
  final ThumbFormat format;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _ImageCacheEntity &&
          runtimeType == other.runtimeType &&
          entity == other.entity &&
          size == other.size &&
          format == other.format;

  @override
  int get hashCode => entity.hashCode * size.hashCode * format.hashCode;
}

import '../types/entity.dart';
import '../internal/enums.dart';
import '../internal/plugin.dart';
import '../types/thumb_option.dart';

/// Cached thumbnails for album management.
class PhotoCachingManager {
  PhotoCachingManager._();

  factory PhotoCachingManager() => instance;

  static late final PhotoCachingManager instance = PhotoCachingManager._();

  static const ThumbOption defaultOption = const ThumbOption(
    width: 150,
    height: 150,
    format: ThumbFormat.jpeg,
    quality: 100,
  );

  // /// Request to cache the photo album's thumbnails.
  // ///
  // ///
  // Future<String> requestCachePath({
  //   @required AssetPathEntity entity,
  //   ThumbOption option = defaultOption,
  // }) {
  //   assert(entity != null);
  //   assert(option != null);
  // }

  Future<void> requestCacheAssets({
    required List<AssetEntity> assets,
    ThumbOption option = defaultOption,
  }) {
    assert(assets.isNotEmpty);

    return plugin.requestCacheAssetsThumb(
      assets.map((e) => e.id).toList(),
      option,
    );
  }

  Future<void> requestCacheAssetsWithIds({
    required List<String> assetIds,
    ThumbOption option = defaultOption,
  }) {
    assert(assetIds.isNotEmpty);

    return plugin.requestCacheAssetsThumb(
      assetIds,
      option,
    );
  }

  /// Cancel all cache request.
  Future<void> cancelCacheRequest() => plugin.cancelCacheRequests();
}

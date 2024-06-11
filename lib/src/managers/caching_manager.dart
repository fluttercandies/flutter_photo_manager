// Copyright 2018 The FlutterCandies author. All rights reserved.
// Use of this source code is governed by an Apache license that can be found
// in the LICENSE file.

import '../internal/constants.dart';
import '../internal/plugin.dart';
import '../types/entity.dart';
import '../types/thumbnail.dart';

/// The cache manager that helps to create/remove caches with specified assets.
class PhotoCachingManager {
  factory PhotoCachingManager() => instance;

  PhotoCachingManager._();

  static final PhotoCachingManager instance = PhotoCachingManager._();

  static const ThumbnailOption _defaultOption = ThumbnailOption(
    size: ThumbnailSize.square(PMConstants.vDefaultThumbnailSize),
  );

  /// Request caching for assets.
  /// The method does not supported on OpenHarmony.
  Future<void> requestCacheAssets({
    required List<AssetEntity> assets,
    ThumbnailOption option = _defaultOption,
  }) {
    assert(assets.isNotEmpty);
    return plugin.requestCacheAssetsThumbnail(
      assets.map((AssetEntity e) => e.id).toList(),
      option,
    );
  }

  /// Request caching for assets' ID.
  /// The method does not supported on OpenHarmony.
  Future<void> requestCacheAssetsWithIds({
    required List<String> assetIds,
    ThumbnailOption option = _defaultOption,
  }) {
    assert(assetIds.isNotEmpty);
    return plugin.requestCacheAssetsThumbnail(assetIds, option);
  }

  /// Cancel all cache request.
  /// The method does not supported on OpenHarmony.
  Future<void> cancelCacheRequest() => plugin.cancelCacheRequests();
}

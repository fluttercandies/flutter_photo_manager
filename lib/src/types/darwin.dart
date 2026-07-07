// Copyright 2018 The FlutterCandies author. All rights reserved.
// Use of this source code is governed by an Apache license that can be found
// in the LICENSE file.

import 'dart:io';
import 'dart:typed_data' as typed_data;

import '../internal/enums.dart';
import '../internal/plugin.dart';
import '../internal/progress_handler.dart';
import 'cancel_token.dart';
import 'entity.dart';

/// A Darwin (iOS/macOS) only view over an [AssetEntity].
///
/// Obtain it through [AssetEntity.darwin]. It groups PhotoKit-specific reads
/// that only make sense on Apple platforms, so that [AssetEntity] itself stays
/// lean instead of accumulating platform-specific members.
///
/// {@template photo_manager.DarwinView.migration}
/// Migration note: this wrapper deliberately keeps no state beyond the wrapped
/// entity and every member simply forwards to the platform channel. Once the
/// package's Dart SDK floor reaches 3.3, it can be replaced by a zero-cost
/// `extension type` over the same representation type without touching any call
/// site — `asset.darwin.xxx` stays byte-for-byte identical:
///
/// ```dart
/// extension type DarwinAsset(AssetEntity _asset) { ... }
/// ```
/// {@endtemplate}
class DarwinAsset {
  /// Creates a Darwin view over the given [_asset].
  ///
  /// Prefer [AssetEntity.darwin] which performs the platform check for you.
  const DarwinAsset(this._asset);

  final AssetEntity _asset;

  /// The stable cloud identifier of the asset, shared across devices that use
  /// the same iCloud Photo Library.
  ///
  /// Unlike [AssetEntity.id] (the `localIdentifier`), which differs on every
  /// device, the cloud identifier lets you match the same photo across devices.
  ///
  /// Returns `null` when the asset has no cloud identifier, when iCloud Photos
  /// is disabled, or when the platform is below iOS 15 / macOS 12.
  ///
  /// See also:
  ///  * `PhotoManager.plugin.getCloudIdentifiers` to resolve many assets in one
  ///    call, which is far more efficient than calling this getter in a loop.
  Future<String?> get cloudIdentifier async {
    final Map<String, String?> mapping = await plugin.getCloudIdentifiers(
      <String>[_asset.id],
    );
    return mapping[_asset.id];
  }

  /// Whether the asset contains adjustment (edit) data, e.g. filters or crops
  /// applied in the Photos app.
  ///
  /// Backed by `PHAsset.hasAdjustments`. On iOS/macOS below 15.0 a slower
  /// fallback based on asset resources is used, so avoid calling it in tight
  /// loops on older systems.
  ///
  /// See also:
  ///  * [baseFile] to obtain the unedited version when this returns `true`.
  Future<bool> get hasAdjustments => plugin.hasAdjustments(_asset.id);

  /// Obtain the base (unedited) file of the asset, before any adjustments were
  /// applied in the Photos app.
  ///
  /// When the asset has no adjustments this resolves to the same content as
  /// [AssetEntity.originFile]. Returns `null` if the base resource cannot be
  /// exported.
  ///
  ///  * [isOrigin] requests the original, full-resolution base resource.
  ///  * [progressHandler] observes the (possibly network-bound) export progress.
  ///  * [darwinFileType] tries to define the export format, e.g. exporting a
  ///    MOV file to MP4.
  ///  * [cancelToken] cancels the export.
  ///
  /// See also:
  ///  * [hasAdjustments] to check whether a distinct base version exists.
  Future<File?> baseFile({
    bool isOrigin = true,
    PMProgressHandler? progressHandler,
    PMDarwinAVFileType? darwinFileType,
    PMCancelToken? cancelToken,
  }) async {
    final String? path = await plugin.getBaseAdjustmentFile(
      _asset.id,
      isOrigin: isOrigin,
      progressHandler: progressHandler,
      darwinFileType: darwinFileType,
      cancelToken: cancelToken,
    );
    if (path == null) {
      return null;
    }
    return File(path);
  }

  /// Export the raw AAE adjustment (edit-history) data for this asset, or
  /// `null` when the asset has no adjustments.
  ///
  /// Backed by the `PHAssetResourceTypeAdjustmentData` resource. Combine it with
  /// [baseFile] (the unedited base image) and [AssetEntity.file] (the rendered
  /// result) to reconstruct a non-destructive editing pipeline.
  ///
  ///  * [progressHandler] observes the (possibly network-bound) export progress.
  ///
  /// See also:
  ///  * [hasAdjustments] to cheaply check whether adjustment data exists.
  Future<typed_data.Uint8List?> adjustmentData({
    PMProgressHandler? progressHandler,
  }) {
    return plugin.getAdjustmentData(
      _asset.id,
      progressHandler: progressHandler,
    );
  }
}

/// A Darwin (iOS/macOS) only view over an [AssetPathEntity].
///
/// Obtain it through [AssetPathEntity.darwin]. Mirrors [DarwinAsset] for
/// album/folder hierarchy reads that only exist on Apple platforms.
///
/// {@macro photo_manager.DarwinView.migration}
class DarwinAssetPath {
  /// Creates a Darwin view over the given [_path].
  ///
  /// Prefer [AssetPathEntity.darwin] which performs the platform check for you.
  const DarwinAssetPath(this._path);

  final AssetPathEntity _path;

  /// Request the parent folders that contain this album or folder.
  ///
  /// Useful for breadcrumb navigation and walking up nested folder structures.
  /// Backed by `PHCollectionList.fetchCollectionListsContainingCollection:`.
  ///
  /// Returns an empty list for the root, system albums (e.g. Recent, All
  /// Photos), or collections that are not contained by any folder.
  ///
  /// See also:
  ///  * [AssetPathEntity.getSubPathList] to walk down the hierarchy instead.
  Future<List<AssetPathEntity>> getParentPathList() {
    return plugin.getParentPathEntities(_path);
  }
}

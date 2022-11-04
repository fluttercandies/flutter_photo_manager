// Copyright 2018 The FlutterCandies author. All rights reserved.
// Use of this source code is governed by an Apache license that can be found
// in the LICENSE file.

import 'dart:io';
import 'dart:typed_data';

import '../types/entity.dart';
import 'plugin.dart';

class Editor {
  final IosEditor _ios = const IosEditor();
  final DarwinEditor _darwin = const DarwinEditor();
  final AndroidEditor _android = const AndroidEditor();

  @Deprecated('Use `Editor.darwin` instead. This will be removed in 3.0.0')
  IosEditor get iOS {
    if (Platform.isIOS || Platform.isMacOS) {
      return _ios;
    }
    throw const OSError('iOS Editor should only be use on iOS.');
  }

  /// Support iOS and macOS.
  DarwinEditor get darwin {
    if (Platform.isIOS || Platform.isMacOS) {
      return _darwin;
    }
    throw const OSError('Darwin Editor should only be use on iOS or macOS.');
  }

  AndroidEditor get android {
    if (Platform.isAndroid) {
      return _android;
    }
    throw const OSError('Android Editor should only be use on Android.');
  }

  /// Delete entities with specific IDs.
  ///
  /// Entities will be deleted no matter which album they're located at on iOS.
  Future<List<String>> deleteWithIds(List<String> ids) {
    return plugin.deleteWithIds(ids);
  }

  /// Save image to gallery from the given [data].
  ///
  /// {@template photo_manager.Editor.TitleWhenSaving}
  /// [title] typically means the filename of the saving entity, which can be
  /// obtained by `basename(file.path)`.
  /// {@endtemplate}
  ///
  /// {@template photo_manager.Editor.DescriptionWhenSaving}
  /// [desc] is the description field that only works on Android.
  /// {@endtemplate}
  ///
  /// {@template photo_manager.Editor.SavingAssets}
  /// On Android 29 and above, you can use [relativePath] to specify the
  /// `RELATIVE_PATH` used in the MediaStore.
  /// The MIME type will either be formed from the title if you pass one,
  /// or guessed by the system, which does not always work.
  /// {@endtemplate}
  Future<AssetEntity?> saveImage(
    Uint8List data, {
    required String title,
    String? desc,
    String? relativePath,
  }) {
    return plugin.saveImage(
      data,
      title: title,
      desc: desc,
      relativePath: relativePath,
    );
  }

  /// Save image to gallery from the given [path].
  ///
  /// {@macro photo_manager.Editor.TitleWhenSaving}
  ///
  /// {@macro photo_manager.Editor.DescriptionWhenSaving}
  ///
  /// {@macro photo_manager.Editor.SavingAssets}
  Future<AssetEntity?> saveImageWithPath(
    String path, {
    required String title,
    String? desc,
    String? relativePath,
  }) {
    return plugin.saveImageWithPath(
      path,
      title: title,
      desc: desc,
      relativePath: relativePath,
    );
  }

  /// Save video to gallery from the given [file].
  ///
  /// {@macro photo_manager.Editor.TitleWhenSaving}
  ///
  /// {@macro photo_manager.Editor.DescriptionWhenSaving}
  ///
  /// {@macro photo_manager.Editor.SavingAssets}
  Future<AssetEntity?> saveVideo(
    File file, {
    required String title,
    String? desc,
    String? relativePath,
  }) {
    return plugin.saveVideo(
      file,
      title: title,
      desc: desc,
      relativePath: relativePath,
    );
  }

  /// Copy asset to another gallery.
  ///
  /// - Android: Produce a copy of the original file.
  /// - iOS/macOS: Make a soft link to the target file.
  Future<AssetEntity?> copyAssetToPath({
    required AssetEntity asset,
    required AssetPathEntity pathEntity,
  }) {
    return plugin.copyAssetToGallery(asset, pathEntity);
  }
}

class DarwinEditor {
  const DarwinEditor();

  /// {@template photo_manager.IosEditor.EnsureParentIsRootOrFolder}
  /// Folders and albums can be only created under the root path or folders,
  /// so the [parent] should be null, the root path or accessible folders.
  /// {@endtemplate}
  void _ensureParentIsRootOrFolder(AssetPathEntity? parent) {
    if (parent != null && parent.albumType != 2 && !parent.isAll) {
      throw ArgumentError('Use a folder path or the root path.');
    }
  }

  /// {@template photo_manager.IosEditor.EnsureParentIsNotRootOrFolder}
  /// Entities' entry can be only removed from non-root albums,
  /// so the [parent] should be non-albums.
  /// {@endtemplate}
  void _ensureParentIsNotRootOrFolder(AssetPathEntity parent) {
    if (parent.isAll) {
      throw ArgumentError('Use PhotoManager.editor.deleteWithIds instead.');
    }
    if (parent.albumType == 2) {
      throw ArgumentError('Use a non-root album path.');
    }
  }

  /// Creates a folder under the root path or other folders.
  ///
  /// [name] Define the folder name.
  /// {@macro photo_manager.IosEditor.EnsureParentIsRootOrFolder}
  Future<AssetPathEntity?> createFolder(
    String name, {
    AssetPathEntity? parent,
  }) async {
    _ensureParentIsRootOrFolder(parent);
    return plugin.iosCreateFolder(
      name,
      parent == null || parent.isAll,
      parent,
    );
  }

  /// Creates an album under the root path or other folders.
  ///
  /// [name] Define the album name.
  /// {@macro photo_manager.IosEditor.EnsureParentIsRootOrFolder}
  Future<AssetPathEntity?> createAlbum(
    String name, {
    AssetPathEntity? parent,
  }) async {
    _ensureParentIsRootOrFolder(parent);
    return plugin.iosCreateAlbum(
      name,
      parent == null || parent.isAll,
      parent,
    );
  }

  /// {@macro photo_manager.IosEditor.EnsureParentIsNotRootOrFolder}
  Future<bool> removeInAlbum(AssetEntity entity, AssetPathEntity parent) async {
    _ensureParentIsNotRootOrFolder(parent);
    return plugin.iosRemoveInAlbum(<AssetEntity>[entity], parent);
  }

  /// Remove [list]'s items from [parent] in batches.
  /// {@macro photo_manager.IosEditor.EnsureParentIsNotRootOrFolder}
  Future<bool> removeAssetsInAlbum(
    List<AssetEntity> list,
    AssetPathEntity parent,
  ) async {
    if (list.isEmpty) {
      return false;
    }
    _ensureParentIsNotRootOrFolder(parent);
    return plugin.iosRemoveInAlbum(list, parent);
  }

  /// Delete the [path].
  Future<bool> deletePath(AssetPathEntity path) {
    return plugin.iosDeleteCollection(path);
  }

  Future<AssetEntity?> favoriteAsset({
    required AssetEntity entity,
    required bool favorite,
  }) async {
    final bool result = await plugin.favoriteAsset(entity.id, favorite);
    if (result) {
      return entity.copyWith(isFavorite: favorite);
    }
    return null;
  }

  /// Save Live Photo to the gallery from the given [imageFile] and [videoFile].
  ///
  /// {@macro photo_manager.Editor.TitleWhenSaving}
  ///
  /// {@macro photo_manager.Editor.DescriptionWhenSaving}
  ///
  /// {@macro photo_manager.Editor.SavingAssets}
  Future<AssetEntity?> saveLivePhoto({
    required File imageFile,
    required File videoFile,
    required String title,
    String? desc,
    String? relativePath,
  }) {
    return plugin.saveLivePhoto(
      imageFile: imageFile,
      videoFile: videoFile,
      title: title,
      desc: desc,
      relativePath: relativePath,
    );
  }
}

class IosEditor extends DarwinEditor {
  const IosEditor();
}

class AndroidEditor {
  const AndroidEditor();

  Future<bool> moveAssetToAnother({
    required AssetEntity entity,
    required AssetPathEntity target,
  }) {
    return plugin.androidMoveAssetToPath(entity, target);
  }

  Future<bool> removeAllNoExistsAsset() {
    return plugin.androidRemoveNoExistsAssets();
  }
}

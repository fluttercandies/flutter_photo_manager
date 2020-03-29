part of '../photo_manager.dart';

class Editor {
  final _iOS = IosEditor();
  final _android = AndroidEditor();

  IosEditor get iOS {
    assert(Platform.isIOS, "the iOS editor just use in iOS.");
    return _iOS;
  }

  AndroidEditor get android {
    assert(Platform.isAndroid, "the android editor just use in android.");
    return _android;
  }

  /// All assets will be deleted. On iOS, assets in all albums will be deleted, not just the gallery you selected.
  Future<List<String>> deleteWithIds(List<String> ids) async {
    return _plugin.deleteWithIds(ids);
  }

  /// Save image to gallery.
  ///
  /// in iOS is Recent.
  /// in Android is Picture.
  Future<AssetEntity> saveImage(
    Uint8List uint8List, {
    String title,
    String desc,
  }) async {
    return _plugin.saveImage(uint8List, title: title, desc: desc);
  }

  /// Save image to gallery.
  ///
  /// in iOS is Recent.
  /// in Android is picture directory .(in android 28 or lower, If the path at the external storage, It will use the path.)
  Future<AssetEntity> saveImageWithPath(
    String path, {
    String title,
    String desc,
  }) async {
    return _plugin.saveImageWithPath(path, title: title, desc: desc);
  }

  /// Save video to gallery.
  ///
  /// in iOS is Recent.
  /// in Android is video directory .(in android 28 or lower, If the path at the external storage, It will use the path.)
  Future<AssetEntity> saveVideo(
    File file, {
    String title,
    String desc,
    Duration duration,
  }) async {
    return _plugin.saveVideo(
      file,
      title: title,
      desc: desc,
    );
  }

  /// Copy asset to another gallery.
  ///
  /// In iOS, just something similar to a shortcut, it points to the same asset.
  /// In android, the asset file will produce a copy.
  Future<AssetEntity> copyAssetToPath({
    @required AssetEntity asset,
    @required AssetPathEntity pathEntity,
  }) {
    assert(asset != null);
    assert(pathEntity != null);
    return _plugin.copyAssetToGallery(asset, pathEntity);
  }
}

/// For iOS
class IosEditor {
  /// [name] The folder name.
  ///
  /// [parent] is nullable, if it's null, the folder will be create in root. If isn't null, the [AssetPathEntity.albumType] must be 2.
  /// The only exception, Recent can be specified, but the same as null.
  Future<AssetPathEntity> createFolder(
    String name, {
    AssetPathEntity parent,
  }) {
    if (parent == null || parent.isAll) {
      return _plugin.iosCreateFolder(name, true, null);
    } else {
      if (parent.albumType == 1) {
        assert(parent.albumType == 1, "The folder can't add");
        return null;
      }
      return _plugin.iosCreateFolder(name, false, parent);
    }
  }

  Future<AssetPathEntity> createAlbum(
    String name, {
    AssetPathEntity parent,
  }) {
    if (parent == null || parent.isAll) {
      return _plugin.iosCreateAlbum(name, true, null);
    } else {
      if (parent.albumType == 1) {
        assert(parent.albumType == 1, "The folder can't add");
        return null;
      }
      return _plugin.iosCreateAlbum(name, false, parent);
    }
  }
}

class AndroidEditor {}

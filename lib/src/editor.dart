part of '../photo_manager.dart';

class Editor {
  Future<List<String>> deleteWithIds(List<String> ids) async {
    return _plugin.deleteWithIds(ids);
  }

  Future<AssetEntity> saveImage(
    Uint8List uint8List, {
    String title,
    String desc,
  }) async {
    return _plugin.saveImage(uint8List, title: title, desc: desc);
  }

  Future<AssetEntity> saveImageWithPath(
    String path, {
    String title,
    String desc,
  }) async {
    return _plugin.saveImageWithPath(path, title: title, desc: desc);
  }

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
}

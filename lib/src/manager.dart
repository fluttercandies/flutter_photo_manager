part of '../photo_manager.dart';

Plugin _plugin = Plugin();

/// use the class method to help user load asset list and asset info.
///
/// 这个类可以获取
class PhotoManager {
  static const MethodChannel _channel = const MethodChannel('image_scanner');

  /// in android WRITE_EXTERNAL_STORAGE  READ_EXTERNAL_STORAGE
  ///
  /// in ios request the photo permission
  static Future<bool> requestPermission() async {
    return _plugin.requestPermission();
  }

  /// get gallery list
  ///
  /// 获取相册"文件夹" 列表
  ///
  /// [hasAll] contains all path, such as "Camera Roll" on ios or "Recent" on android.
  /// [hasAll] 包含所有项目的相册
  static Future<List<AssetPathEntity>> getAssetPathList({
    bool hasAll = true,
    RequestType type,
    DateTime fetchDateTime,
  }) async {
    return _plugin.getAllGalleryList(
      type: type.index,
      dt: fetchDateTime,
      hasAll: hasAll,
    );
  }

  static Future<List<AssetPathEntity>> getImageAsset() {
    return getAssetPathList(type: RequestType.image);
  }

  static Future<List<AssetPathEntity>> getVideoAsset() {
    return getAssetPathList(type: RequestType.video);
  }

  static Future<void> setLog(bool isLog) {
    return _plugin.setLog(isLog);
  }

  /// get video asset
  /// open setting page
  static void openSetting() {
    _plugin.openSetting();
  }

  static Future<List<AssetEntity>> _getAssetListPaged(
      AssetPathEntity assetPathEntity,
      int page,
      int pageCount,
      DateTime pagedDt) async {
    return _plugin.getAssetWithGalleryIdPaged(
      assetPathEntity.id,
      page: page,
      pageCount: pageCount,
      type: assetPathEntity.typeInt,
      pagedDt: pagedDt,
    );
  }

  /// Release all native(ios/android) caches, normally no calls are required.
  ///
  /// The main purpose is to help clean up problems where memory usage may be too large when there are too many pictures.
  ///
  /// Warning:
  ///
  ///   Once this method is invoked, unless you call the [getAssetPathList] method again, all the [AssetEntity] and [AssetPathEntity] methods/fields you have acquired will fail or produce unexpected results.
  ///
  ///   This method should only be invoked when you are sure you really want to do so.
  ///
  ///   This method is asynchronous, and calling [getAssetPathList] before the Future of this method returns causes an error.
  ///
  ///
  /// 释放资源的方法,一般情况下不需要调用
  ///
  /// 主要目的是帮助清理当图片过多时,内存占用可能过大的问题
  ///
  /// 警告:
  ///
  /// 一旦调用这个方法,除非你重新调用  [getAssetPathList] 方法,否则你已经获取的所有[AssetEntity]/[AssetPathEntity]的所有字段都将失效或产生无法预期的效果
  ///
  /// 这个方法应当只在你确信你真的需要这么做的时候再调用
  ///
  /// 这个方法是异步的,在本方法的Future返回前调用getAssetPathList 可能会产生错误
  static Future releaseCache() async {
    await _plugin.releaseCache();
  }

  /// Notification class for managing photo changes.
  static _NotifyManager _notifyManager = _NotifyManager();

  /// see [_NotifyManager]
  static void addChangeCallback(ValueChanged<MethodCall> callback) =>
      _notifyManager.addCallback(callback);

  /// see [_NotifyManager]
  static void removeChangeCallback(ValueChanged<MethodCall> callback) =>
      _notifyManager.removeCallback(callback);

  /// see [_NotifyManager]
  static void startChangeNotify() => _notifyManager.startHandleNotify();

  /// see [_NotifyManager]
  static void stopChangeNotify() => _notifyManager.stopHandleNotify();

  static Future<File> _getFileWithId(String id, {bool isOrigin = false}) async {
    if (Platform.isIOS || Platform.isAndroid) {
      final path = await _plugin.getFullFile(id, isOrigin: isOrigin);
      if (path == null) {
        return null;
      }
      return File(path);
    }
    return null;
  }

  static Future<Uint8List> _getFullDataWithId(String id) async {
    return _plugin.getOriginBytes(id);
  }

  static _getThumbDataWithId(
    String id, {
    int width = 150,
    int height = 150,
  }) {
    return _plugin.getThumb(
      id: id,
      width: width,
      height: height,
    );
  }

  static Future<bool> _assetExistsWithId(String id) async {
    return true;
  }

  // static Future<AssetEntity> _createAssetEntityWithId(String id) async {
  //   return AssetEntity(id: id);
  // }

  static Future<AssetPathEntity> fetchPathProperties(
    AssetPathEntity entity,
    DateTime time,
  ) async {
    var result =
        await _plugin.fetchPathProperties(entity.id, entity.typeInt, time);
    if (result == null) {
      return null;
    }
    var list = result["data"];
    if (list is List && list.isNotEmpty) {
      return ConvertUtils.convertPath(result,
          dt: time, type: entity.typeInt)[0];
    } else {
      return null;
    }
  }

  static Future<void> forceOldApi() async{
    await _plugin.forceOldApi();
  }

  // static bool get androidQExperimental => _plugin.androidQExperimental;

  // static set androidQExperimental(bool value)=> _plugin.androidQExperimental = value;

  // static Future<void> setAndroidQExperimental(bool open) async {
  //   await _plugin.setAndroidQExperimental(open);
  // }
}

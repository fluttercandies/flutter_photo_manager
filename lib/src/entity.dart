part of '../photo_manager.dart';

/// asset entity, for entity info.
class AssetPathEntity {
  /// id
  ///
  /// in ios is localIdentifier
  ///
  /// in android is content provider database _id column
  String id;

  /// name
  ///
  /// in android is path name
  ///
  /// in ios is photos gallery name
  String name;

  /// gallery asset count
  int assetCount;

  /// path asset type.
  RequestType _type;

  /// The value used internally by the user.
  /// Used to indicate the value that should be available inside the path.
  RequestType get type => _type;

  set type(RequestType type) {
    _type = type;
    typeInt = type.index;
  }

  /// Users should not edit this value.
  ///
  /// This is a field used internally by the library.
  int typeInt = 0;

  /// This path is the path that contains all the assets.
  bool isAll = false;

  /// The timestamp of the path, when the request page number is 0, reset it to the current time. When other page numbers are passed directly.
  DateTime fetchDatetime;

  AssetPathEntity({this.id, this.name});

  Future<void> refreshPathProperties({DateTime dt}) async {
    dt ??= DateTime.now();
    final result = await PhotoManager.fetchPathProperties(this, dt);
    if (result != null) {
      this.assetCount = result.assetCount;
      this.fetchDatetime = result.fetchDatetime;
      this.name = result.name;
    }
  }

  /// the image entity list with pagination
  ///
  /// Doesn't support AssetPathEntity with only(Video/Image) flag.
  /// Throws UnsupportedError
  ///
  /// [page] is starting 0.
  ///
  /// [pageSize] is item count of page.
  ///
  Future<List<AssetEntity>> getAssetListPaged(int page, int pageSize) {
    return PhotoManager._getAssetListPaged(this, page, pageSize, fetchDatetime);
  }

  /// all of asset, It is recommended to use the latest api (pagination) [getAssetListPaged].
  Future<List<AssetEntity>> get assetList => getAssetListPaged(0, assetCount);

  @override
  bool operator ==(other) {
    if (other is! AssetPathEntity) {
      return false;
    }
    return this.id == other.id;
  }

  @override
  int get hashCode {
    return this.id.hashCode;
  }

  @override
  String toString() {
    return "AssetPathEntity{ name: $name id:$id , length = $assetCount}";
  }
}

/// Used to describe a picture or video
class AssetEntity {
  /// in android is full path
  ///
  /// in ios is local id
  String id;

  /// see [id]
  AssetEntity({this.id});

  /// the asset type
  ///
  /// see [AssetType]
  AssetType get type {
    switch (typeInt) {
      case 1:
        return AssetType.image;
      case 2:
        return AssetType.video;
      default:
        return AssetType.other;
    }
  }

  /// Asset type int value.
  ///
  /// see [type]
  int typeInt;

  /// Duration of video, unit is second.
  ///
  /// If [type] is [AssetType.image], then it's value is 0.
  int duration;

  /// width of asset.
  int width;

  /// height of asset.
  int height;

  /// if you need upload file ,then you can use the file, nullable.
  Future<File> get file async => PhotoManager._getFileWithId(this.id);

  /// This contains all the EXIF information, but in contrast, `Image` widget may not be able to display pictures.
  ///
  /// Usually, you can use the [file] attribute
  Future<File> get originFile async =>
      PhotoManager._getFileWithId(id, isOrigin: true);

  /// the image's bytes ,
  Future<Uint8List> get fullData => PhotoManager._getFullDataWithId(id);

  /// thumb data , for display
  Future<Uint8List> get thumbData => PhotoManager._getThumbDataWithId(id);

  /// get thumb with size
  Future<Uint8List> thumbDataWithSize(int width, int height) {
    return PhotoManager._getThumbDataWithId(id, width: width, height: height);
  }

  /// if not video ,duration is null
  Duration get videoDuration => Duration(seconds: duration);

  /// nullable, if the manager is null.
  Size get size => Size(width.toDouble(), height.toDouble());

  /// unix timestamp of asset, milliseconds
  int createTime;

  /// create time of asset
  DateTime get createDateTime {
    return DateTime.fromMillisecondsSinceEpoch(createTime ?? 0);
  }

  /// If the asset is deleted, return false.
  Future<bool> get exists => PhotoManager._assetExistsWithId(id);

  @override
  int get hashCode {
    return id.hashCode;
  }

  @override
  bool operator ==(other) {
    if (other is! AssetEntity) {
      return false;
    }
    return this.id == other.id;
  }

  @override
  String toString() {
    return "AssetEntity{id:$id}";
  }
}

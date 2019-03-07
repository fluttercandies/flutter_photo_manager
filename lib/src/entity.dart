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

  bool _hasVideo;

  /// hasVideo
  set hasVideo(bool value) => _hasVideo = value;

  /// hasVideo
  bool get hasVideo => onlyVideo == true || _hasVideo == true;

  /// only have video
  bool onlyVideo = false;

  /// only have image
  bool onlyImage = false;

  /// contains all asset
  bool isAll = false;

  AssetPathEntity({this.id, this.name, bool hasVideo}) : _hasVideo = hasVideo;

  /// the image entity list
  Future<List<AssetEntity>> get assetList => PhotoManager._getAssetList(this);

  static var _all = AssetPathEntity()
    ..id = "allall--dfnsfkdfj2454AJJnfdkl"
    ..name = "Recent"
    ..isAll = true
    ..hasVideo = true;

  static var _allVideo = AssetPathEntity()
    ..id = "videovideo--87yuhijn3cvx"
    ..name = "Recent"
    ..isAll = true
    ..onlyVideo = true;

  static var _allImage = AssetPathEntity()
    ..id = "imageimage--89hdsinvosd"
    ..onlyImage = true
    ..isAll = true
    ..name = "Recent";

  /// all asset path
  static AssetPathEntity get all => _all;

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
    return "AssetPathEntity{id:$id}";
  }
}

/// Used to describe a picture or video
class AssetEntity {
  /// in android is full path
  ///
  /// in ios is asset id
  String id;

  /// see [id]
  AssetEntity({this.id});

  /// the asset type
  ///
  /// see [AssetType]
  AssetType type;

  // /// isCloud
  // Future get isCloud async => PhotoManager._isCloudWithAsset(this);

  /// thumb path
  ///
  /// you can use File(path) to use
  // Future<File> get thumb async => PhotoManager._getThumbWithId(id);

  /// if you need upload file ,then you can use the file
  Future<File> get file async => PhotoManager._getFullFileWithId(id);

  /// This contains all the EXIF information, but in contrast, `Image` widget may not be able to display pictures.
  ///
  /// Usually, you can use the [file] attribute
  Future<File> get originFile async =>
      PhotoManager._getFullFileWithId(id, isOrigin: true);

  /// the image's bytes ,
  Future<Uint8List> get fullData => PhotoManager._getDataWithId(id);

  /// thumb data , for display
  Future<Uint8List> get thumbData => PhotoManager._getThumbDataWithId(id);

  /// get thumb with size
  Future<Uint8List> thumbDataWithSize(int width, int height) {
    return PhotoManager._getThumbDataWithId(id, width: width, height: height);
  }

  /// if not video ,duration is null
  Future<Duration> get videoDuration async {
    if (type != AssetType.video) {
      return null;
    }
    return PhotoManager._getDurationWithId(id);
  }

  /// nullable, if the manager is null.
  Future<Size> get size async {
    try {
      return await PhotoManager._getSizeWithId(id);
    } on Exception {
      return null;
    }
  }

  /// unix timestamp of asset, milliseconds
  int createTime;

  /// create time of asset
  DateTime get createDateTime {
    print(createTime);
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

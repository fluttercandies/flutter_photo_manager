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

  final FilterOptionGroup filterOption;

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

  AssetPathEntity({this.id, this.name, this.filterOption});

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
    assert(pageSize > 0, "The pageSize must better than 0.");
    return PhotoManager._getAssetListPaged(this, page, pageSize);
  }

  /// The [start] and [end] like the [String.substring].
  Future<List<AssetEntity>> getAssetListRange({int start, int end}) async {
    assert(start >= 0, "The start must better than 0.");
    assert(end > start, "The end must better than start.");
    return PhotoManager._getAssetWithRange(
        entity: this, start: start, end: end);
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

  /// It is title `MediaStore.MediaColumns.DISPLAY_NAME` in MediaStore on android.
  ///
  /// It is `PHAssetResource.originalFilename` on iOS.
  ///
  /// Nullable in iOS. If you must need it, See [FilterOption.needTitle] or use [titleAsync].
  String title;

  /// It is [title] in Android.
  ///
  /// It is [PHAsset valueForKey:@"originalFilename"] in iOS.
  Future<String> get titleAsync => _plugin.getTitleAsync(this);

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
  ///
  /// Also see [videoDuration]
  int duration;

  /// width of asset.
  int width;

  /// height of asset.
  int height;

  /// Gps information when shooting, nullable.
  ///
  /// When the device is android10 or above, always null.
  double _latitude;

  /// Gps information when shooting, nullable.
  ///
  /// When the device is android10 or above, always null.
  double get latitude => _latitude ?? 0;

  /// Gps information when shooting, nullable.
  ///
  /// When the device is android10 or above, always null.
  set latitude(double latitude) {
    _latitude = latitude;
  }

  /// Gps information when shooting, nullable.
  ///
  /// When the device is android10 or above, always null.
  double _longitude;

  /// Gps information when shooting, nullable.
  ///
  /// When the device is android10 or above, always null.
  double get longitude => _longitude ?? 0;

  /// Gps information when shooting, nullable.
  ///
  /// When the device is android10 or above, always null.
  set longitude(double longitude) {
    _longitude = longitude;
  }

  /// Get latitude and longitude from MediaStore(android) / Photos(iOS).
  ///
  /// except : In androidQ, the location info come from exif.
  ///
  /// [LatLng.latitude] or [LatLng.longitude] maybe zero or null.
  Future<LatLng> latlngAsync() {
    return _plugin.getLatLngAsync(this);
  }

  /// if you need upload file ,then you can use the file, nullable.
  Future<File> get file async => PhotoManager._getFileWithId(this.id);

  /// This contains all the EXIF information, but in contrast, `Image` widget may not be able to display pictures.
  ///
  /// Usually, you can use the [file] attribute
  Future<File> get originFile async =>
      PhotoManager._getFileWithId(id, isOrigin: true);

  /// The asset's bytes.
  ///
  /// Use [originBytes]
  ///
  /// The property will be remove in 0.5.0.
  @Deprecated("Use originBytes instead")
  Future<Uint8List> get fullData => PhotoManager._getFullDataWithId(id);

  /// The raw data stored in the device, the data may be large.
  ///
  /// This property is not recommended for video types.
  Future<Uint8List> get originBytes => PhotoManager._getOriginBytes(this);

  /// thumb data , for display
  Future<Uint8List> get thumbData => PhotoManager._getThumbDataWithId(id);

  /// get thumb with size
  Future<Uint8List> thumbDataWithSize(
    int width,
    int height, {
    ThumbFormat format = ThumbFormat.jpeg,
  }) {
    return PhotoManager._getThumbDataWithId(
      id,
      width: width,
      height: height,
      format: format,
    );
  }

  /// if not video ,duration is null
  Duration get videoDuration => Duration(seconds: duration ?? 0);

  /// nullable, if the manager is null.
  Size get size => Size(width.toDouble(), height.toDouble());

  /// unix timestamp of asset, milliseconds
  int createDtSecond;

  /// create time of asset
  DateTime get createDateTime {
    final sec = (createDtSecond ?? 0);
    return DateTime.fromMillisecondsSinceEpoch(sec * 1000);
  }

  /// second of modified.
  int modifiedDateSecond;

  DateTime get modifiedDateTime {
    final sec = modifiedDateSecond ?? 0;
    return DateTime.fromMillisecondsSinceEpoch(sec * 1000);
  }

  /// If the asset is deleted, return false.
  Future<bool> get exists => PhotoManager._assetExistsWithId(id);

  /// The url is provided to some video player. Such as [flutter_ijkplayer](https://pub.dev/packages/flutter_ijkplayer)
  ///
  /// It is such as `file:///var/mobile/Media/DCIM/118APPLE/IMG_8371.MOV` in iOS.
  ///
  /// Android28 or lower: `file:///storage/emulated/0/DCIM/Camera/20201020_202020.MP4`
  ///
  /// AndroidQ or higher: `content://media/external/video/media/894857`
  Future<String> getMediaUrl() {
    if (type == AssetType.video) {
      return PhotoManager._getMediaUrl(this);
    }
    return null;
  }

  /// Orientation of android MediaStore. See [ORIENTATION](https://developer.android.com/reference/android/provider/MediaStore.MediaColumns#ORIENTATION)
  /// Example values for android: 0 90 180 270
  ///
  /// The value always 0 in iOS.
  int orientation;

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

class LatLng {
  double longitude;
  double latitude;
}

// ignore_for_file: must_be_immutable
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';

import '../filter/filter_option_group.dart';
import '../internal/constants.dart';
import '../internal/editor.dart';
import '../internal/enums.dart';
import '../internal/plugin.dart';
import '../internal/progress_handler.dart';
import '../managers/photo_manager.dart';
import 'thumb_option.dart';
import 'types.dart';

/// The abstraction of albums and folders.
/// It represent a bucket in the `MediaStore` on Android,
/// and the `PHAssetCollection` object on iOS/macOS.
@immutable
class AssetPathEntity {
  /// Obtain an entity from ID.
  ///
  /// This method is not recommend in general, since the correspoding folder
  /// could be deleted in anytime, which will cause properties invalid.
  static Future<AssetPathEntity> fromId(
    String id, {
    FilterOptionGroup? filterOption,
    RequestType type = RequestType.common,
    int albumType = 1,
  }) async {
    assert(albumType == 1 || Platform.isIOS || Platform.isMacOS);
    final AssetPathEntity entity = AssetPathEntity()
      ..id = id
      ..albumType = albumType
      ..filterOption = filterOption ?? FilterOptionGroup()
      ..type = type;
    await entity.refreshPathProperties();
    return entity;
  }

  /// The ID of the album (asset collection).
  ///  * Android: `MediaStore.Images.Media.BUCKET_ID`.
  ///  * iOS/macOS: localIndentifier.
  late final String id;

  /// The name of the album.
  ///  * Android: Path name.
  ///  * iOS/macOS: Album/Folder name.
  late String name;

  /// Total assets count of the album.
  late int assetCount;

  /// The type of the album.
  ///  * Android: Always be 1.
  ///  * iOS: 1 - Album, 2 - Folder.
  late int albumType;

  /// The collection of filter options of the album.
  late FilterOptionGroup filterOption;

  /// The latest modification date of the album.
  ///
  /// This field will only be included when
  /// [FilterOptionGroup.containsPathModified] is true.
  DateTime? lastModified;

  /// The value used internally by the user.
  /// Used to indicate the value that should be available inside the path.
  /// The [RequestType] of the album.
  ///
  /// this value is determined as final when user construct the album.
  late RequestType type;

  /// Whether the album contains all assets.
  ///
  /// An album includes all assets is the default album in general.
  late bool isAll;

  /// Call this method to update the property
  Future<void> refreshPathProperties({
    bool maxDateTimeToNow = true,
  }) async {
    if (maxDateTimeToNow) {
      filterOption = filterOption.copyWith(
        createTimeCond: filterOption.createTimeCond.copyWith(
          max: DateTime.now(),
        ),
        updateTimeCond: filterOption.updateTimeCond.copyWith(
          max: DateTime.now(),
        ),
      );
    }

    final AssetPathEntity? result = await PhotoManager.fetchPathProperties(
      entity: this,
      filterOptionGroup: filterOption,
    );
    if (result != null) {
      assetCount = result.assetCount;
      name = result.name;
      isAll = result.isAll;
      type = result.type;
      filterOption = filterOption;
      lastModified = result.lastModified;
    }
  }

  /// Entity list with pagination support.
  ///
  /// [page] should starts with and greater than 0.
  /// [pageSize] is item count of current [page].
  Future<List<AssetEntity>> getAssetListPaged(int page, int pageSize) {
    assert(albumType == 1, 'Only album can request for assets.');
    assert(pageSize > 0, 'The pageSize must be greater than 0.');
    return plugin.getAssetWithGalleryIdPaged(
      id,
      page: page,
      pageCount: pageSize,
      type: type,
      optionGroup: filterOption,
    );
  }

  /// Getting assets in range using [start] and [end].
  ///
  /// The [start] and [end] are similar to [String.substring], but it'll return
  /// the maxmium assets if the total count of assets is fewer than the range,
  /// instead of throwing a [RangeError] like [String.substring].
  Future<List<AssetEntity>> getAssetListRange({
    required int start,
    required int end,
  }) async {
    assert(albumType == 1, 'Only album can request for assets.');
    assert(start >= 0, 'The start must be greater than 0.');
    assert(end > start, 'The end must be greater than start.');
    if (end > assetCount) {
      end = assetCount;
    }
    return plugin.getAssetWithRange(
      id,
      type: type,
      start: start,
      end: end,
      optionGroup: filterOption,
    );
  }

  /// Request subpaths for the album.
  ///
  /// An empty list will always be returned on Android.
  Future<List<AssetPathEntity>> getSubPathList() async {
    if (Platform.isIOS || Platform.isMacOS) {
      return plugin.getSubPathEntities(this);
    }
    return <AssetPathEntity>[];
  }

  @override
  bool operator ==(Object other) {
    if (other is! AssetPathEntity) {
      return false;
    }
    return id == other.id &&
        name == other.name &&
        assetCount == other.assetCount &&
        albumType == other.albumType &&
        type == other.type &&
        lastModified == other.lastModified &&
        isAll == other.isAll;
  }

  @override
  int get hashCode =>
      hashValues(id, name, assetCount, albumType, type, lastModified, isAll);

  @override
  String toString() {
    return 'AssetPathEntity(id: $id, name: $name, assetCount: $assetCount)';
  }
}

/// The abstraction of assets (images/videos/audios).
/// It represent a series of fields with `MediaStore` on Android,
/// and the `PHAsset` object on iOS/macOS.
@immutable
class AssetEntity {
  AssetEntity({
    required this.id,
    required this.typeInt,
    required this.width,
    required this.height,
    this.duration = 0,
    this.orientation = 0,
    this.isFavorite = false,
    this.title,
    this.createDtSecond,
    this.modifiedDateSecond,
    this.relativePath,
    double? latitude,
    double? longitude,
    this.mimeType,
    this.subtype = 0,
  })  : _latitude = latitude,
        _longitude = longitude;

  /// Obtain an entity from ID.
  ///
  /// This method is not recommend in general, since the correspoding asset
  /// could be deleted in anytime, which will cause properties invalid.
  static Future<AssetEntity?> fromId(String id) async {
    try {
      return await PhotoManager.refreshAssetProperties(id);
    } catch (e) {
      return null;
    }
  }

  /// Refresh properties for the current asset and return a new object.
  Future<AssetEntity?> refreshProperties() {
    return PhotoManager.refreshAssetProperties(id);
  }

  /// The ID of the asset.
  ///  * Android: `_id` column in `MediaStore` database.
  ///  * iOS/macOS: `localIndentifier`.
  final String id;

  /// The title field of the asset.
  ///  * Android: `MediaStore.MediaColumns.DISPLAY_NAME`.
  ///  * iOS/macOS: `PHAssetResource.filename`.
  ///
  /// This field is nullable on iOS.
  /// If you need to obtain it, set [FilterOption.needTitle] to `true`
  /// or use the async getter [titleAsync].
  final String? title;

  ///  * Android: `MediaStore.MediaColumns.DISPLAY_NAME`.
  ///  * iOS/macOS: `PHAssetResource.filename`.
  Future<String> get titleAsync => plugin.getTitleAsync(this);

  /// {@macro photo_manager.AssetType}
  AssetType get type => AssetType.values[typeInt];

  /// The subtype of the asset.
  ///
  /// * Android: Always 0.
  /// * iOS/macOS: https://developer.apple.com/documentation/photokit/phassetmediasubtype
  final int subtype;

  /// Whether the asset is a live photo. Only valid on iOS/macOS.
  bool get isLivePhoto => subtype == 8;

  /// The type value of the [type].
  final int typeInt;

  /// The duration of the asset, but in different units.
  ///  * [AssetType.audio]: Milliseconds.
  ///  * [AssetType.video]: Seconds.
  ///  * [AssetType.image] and [AssetType.other]: Always 0.
  ///
  /// See also:
  ///  * [videoDuration] which is a duration getter for videos.
  final int duration;

  /// The width of the asset.
  ///
  /// This field could be 0 in cases that EXIF info is failed to parse.
  final int width;

  /// The height of the asset.
  ///
  /// This field could be 0 in cases that EXIF info is failed to parse.
  final int height;

  bool get _isLandscape => orientation == 90 || orientation == 270;

  int get orientatedWidth => _isLandscape ? height : width;

  int get orientatedHeight => _isLandscape ? width : height;

  Size get orientatedSize => _isLandscape ? size.flipped : size;

  /// Latitude value of the location when shooting.
  ///  * Android: `MediaStore.Images.ImageColumns.LATITUDE`.
  ///  * iOS/macOS: `PHAsset.location.coordinate.latitude`.
  ///
  /// It's always null when the device is Android 10 or above.
  ///
  /// See also:
  ///  * https://developer.android.com/reference/android/provider/MediaStore.Images.ImageColumns#LATITUDE
  ///  * https://developer.apple.com/documentation/corelocation/cllocation?language=objc#declaration
  double? get latitude => _latitude;
  final double? _latitude;

  /// Latitude value of the location when shooting.
  ///  * Android: `MediaStore.Images.ImageColumns.LONGITUDE`.
  ///  * iOS/macOS: `PHAsset.location.coordinate.longitude`.
  ///
  /// It's always null when the device is Android 10 or above.
  ///
  /// See also:
  ///  * https://developer.android.com/reference/android/provider/MediaStore.Images.ImageColumns#LATITUDE
  ///  * https://developer.apple.com/documentation/corelocation/cllocation?language=objc#declaration
  double? get longitude => _longitude;
  final double? _longitude;

  /// Whether this asset is locally available.
  ///  * Android: Always true.
  ///  * iOS/macOS: Whether the asset has been uploaded to iCloud
  ///    and locally exist.
  Future<bool> get isLocallyAvailable => plugin.isLocallyAvailable(id);

  /// Obtain latitude and longitude.
  ///  * Android: Obtain from `MediaStore` or EXIF (Android 10).
  ///  * iOS/macOS: Obtain from photos.
  ///
  /// [LatLng.latitude] and [LatLng.longitude] might be 0.
  Future<LatLng> latlngAsync() => plugin.getLatLngAsync(this);

  /// Obtain the compressed file of the asset.
  ///
  /// See also:
  ///  * [originFile] which can obtain the origin file.
  ///  * [loadFile] which can obtain file with [PMProgressHandler].
  Future<File?> get file => _getFile();

  /// Obtain the original file that contain all EXIF informations.
  ///
  /// Be aware the original file is not always suit for all kinds of usages.
  /// Typically when you're using an [Image] to display a HEIC image on
  /// Android 10, it'll failed to display the image.
  ///
  /// See also:
  ///  * [file] which can obtain the compressed file.
  ///  * [loadFile] which can obtain file with [PMProgressHandler].
  Future<File?> get originFile => _getFile(isOrigin: true);

  /// Obtain file of the asset with a [PMProgressHandler].
  ///
  /// See also:
  ///  * [file] which can obtain the compressed file.
  ///  * [originFile] which can obtain the original file.
  Future<File?> loadFile({
    bool isOrigin = true,
    PMProgressHandler? progressHandler,
  }) {
    return _getFile(isOrigin: isOrigin, progressHandler: progressHandler);
  }

  /// Obtain the raw data of the asset.
  ///
  /// **Use it with cautious** since the original data might be epic large.
  /// Generally use this method only for images.
  Future<Uint8List?> get originBytes => _getOriginBytes();

  /// Obtain the thumbnail data with [PMConstants.vDefaultThumbnailSize]
  /// size of the asset, typically use it for preview displays.
  ///
  /// {@template photo_manager.thumbnailForVideos}
  /// Thumbnail data for videos are images, not compressed video.
  /// {@endtemplate}
  ///
  /// See also:
  ///  * [thumbDataWithSize] which is a common method to obtain thumbnails.
  ///  * [thumbDataWithOption] which accepts customized [ThumbOption].
  Future<Uint8List?> get thumbData => thumbDataWithSize(
        PMConstants.vDefaultThumbnailSize,
        PMConstants.vDefaultThumbnailSize,
      );

  /// Obtain the thumbnail data with the given [width] and [height] of the asset.
  ///
  /// {@macro photo_manager.thumbnailForVideos}
  ///
  /// See also:
  ///  * [thumbData] which obtain the thumbnail data with fixed size.
  ///  * [thumbDataWithOption] which accepts customized [ThumbOption].
  Future<Uint8List?> thumbDataWithSize(
    int width,
    int height, {
    ThumbFormat format = ThumbFormat.jpeg,
    int quality = 100,
    PMProgressHandler? progressHandler,
  }) {
    assert(() {
      _checkThumbnailAssertion();
      return true;
    }());
    // Return null if the asset is audio or others.
    if (type == AssetType.audio || type == AssetType.other) {
      return Future<Uint8List?>.value();
    }
    final ThumbOption option;
    if (Platform.isIOS || Platform.isMacOS) {
      option = ThumbOption.ios(
        width: width,
        height: height,
        format: format,
        quality: quality,
      );
    } else {
      option = ThumbOption(
        width: width,
        height: height,
        format: format,
        quality: quality,
      );
    }
    assert(() {
      option.checkAssertions();
      return true;
    }());

    return thumbDataWithOption(option, progressHandler: progressHandler);
  }

  /// Obtain the thumbnail data with the given customized [ThumbOption].
  ///
  /// See also:
  ///  * [thumbData] which obtain the thumbnail data with fixed size.
  ///  * [thumbDataWithSize] which is a common method to obtain thumbnails.
  Future<Uint8List?> thumbDataWithOption(
    ThumbOption option, {
    PMProgressHandler? progressHandler,
  }) {
    assert(() {
      _checkThumbnailAssertion();
      return true;
    }());
    // Return null if the asset is audio or others.
    if (type == AssetType.audio || type == AssetType.other) {
      return Future<Uint8List?>.value();
    }
    assert(() {
      option.checkAssertions();
      return true;
    }());
    return plugin.getThumb(
      id: id,
      option: option,
      progressHandler: progressHandler,
    );
  }

  void _checkThumbnailAssertion() {
    assert(
      type == AssetType.image || type == AssetType.video,
      'Only images and videos can obtain thumbnails.',
    );
  }

  /// The video duration in seconds.
  ///
  /// This getter will return [Duration.zero] if the asset if not video.
  ///
  /// See also:
  ///  * [duration] which is the duration of the asset, but in different units.
  Duration get videoDuration => Duration(seconds: duration);

  /// The [Size] for the asset.
  Size get size => Size(width.toDouble(), height.toDouble());

  /// The create time in unix timestamp of the asset.
  int? createDtSecond;

  /// The create time of the asset in [DateTime].
  DateTime get createDateTime {
    final int value = createDtSecond ?? 0;
    return DateTime.fromMillisecondsSinceEpoch(value * 1000);
  }

  /// The modified time in unix timestamp of the asset.
  int? modifiedDateSecond;

  /// The modified time of the asset in [DateTime].
  DateTime get modifiedDateTime {
    final int value = modifiedDateSecond ?? 0;
    return DateTime.fromMillisecondsSinceEpoch(value * 1000);
  }

  /// Check whether the asset has been deleted.
  Future<bool> get exists => plugin.assetExistsWithId(id);

  /// Provide regular URL for players. Only available for audios and videos.
  ///  * Android: Content URI, e.g.
  ///    `content://media/external/video/media/894857`.
  ///  * iOS/macOS: File URL. e.g.
  ///    `file:///var/mobile/Media/DCIM/118APPLE/IMG_8371.MOV`.
  ///
  /// See also:
  ///  * https://developer.android.com/reference/android/content/ContentUris
  ///  * https://developer.apple.com/documentation/avfoundation/avurlasset
  Future<String?> getMediaUrl() async {
    if (type == AssetType.video || type == AssetType.audio || isLivePhoto) {
      return plugin.getMediaUrl(this);
    }
    return null;
  }

  bool get _platformMatched =>
      Platform.isIOS || Platform.isMacOS || Platform.isAndroid;

  Future<File?> _getFile({
    bool isOrigin = false,
    PMProgressHandler? progressHandler,
  }) async {
    assert(
      _platformMatched,
      '${Platform.operatingSystem} does not support obtain file.',
    );
    if (!_platformMatched) {
      return null;
    }
    final String? path = await plugin.getFullFile(
      id,
      isOrigin: isOrigin,
      progressHandler: progressHandler,
    );
    if (path == null) {
      return null;
    }
    return File(path);
  }

  Future<Uint8List?> _getOriginBytes({
    PMProgressHandler? progressHandler,
  }) async {
    assert(
      _platformMatched,
      '${Platform.operatingSystem} does not support obtain raw data.',
    );
    if (!_platformMatched) {
      return null;
    }
    if (Platform.isAndroid &&
        int.parse(await plugin.getSystemVersion()) >= 29) {
      return plugin.getOriginBytes(id, progressHandler: progressHandler);
    }
    final File? file = await originFile;
    return file?.readAsBytes();
  }

  /// The orientation of the asset.
  ///  * Android: `MediaStore.MediaColumns.ORIENTATION`,
  ///    could be 0, 90, 180, 270.
  ///  * iOS/macOS: Always 0.
  ///
  /// See also:
  ///  * https://developer.android.com/reference/android/provider/MediaStore.MediaColumns#ORIENTATION
  int orientation;

  /// Whether the asset is favorited on the device.
  ///  * Android: Always false.
  ///  * iOS/macOS: `PHAsset.isFavorite`.
  ///
  /// See also:
  ///  * [IosEditor.favoriteAsset] to update the favorite status.
  bool isFavorite;

  /// The relative path abstraction of the asset.
  ///  * Android 10 and above: `MediaStore.MediaColumns.RELATIVE_PATH`.
  ///  * Android 9 and below: The parent path of `MediaStore.MediaColumns.DATA`.
  ///  * iOS/macOS: Always null.
  String? relativePath;

  /// The mime type of the asset.
  ///  * Android: `MediaStore.MediaColumns.MIME_TYPE`.
  ///  * iOS/macOS: Always null.
  ///
  /// See also:
  ///  * https://developer.android.com/reference/android/provider/MediaStore.MediaColumns#MIME_TYPE
  String? mimeType;

  @override
  int get hashCode => hashValues(id, isFavorite);

  @override
  bool operator ==(Object other) {
    if (other is! AssetEntity) {
      return false;
    }
    return id == other.id && isFavorite == other.isFavorite;
  }

  @override
  String toString() => 'AssetEntity(id: $id , type: $type)';
}

/// Longitude and latitude.
@immutable
class LatLng {
  const LatLng({this.latitude, this.longitude});

  final double? latitude;
  final double? longitude;

  @override
  int get hashCode => hashValues(latitude, longitude);

  @override
  bool operator ==(Object other) {
    if (other is! AssetEntity) {
      return false;
    }
    return latitude == other.latitude && longitude == other.longitude;
  }
}

// Copyright 2018 The FlutterCandies author. All rights reserved.
// Use of this source code is governed by an Apache license that can be found
// in the LICENSE file.

import 'dart:io';
import 'dart:typed_data' as typed_data;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';

import '../filter/base_filter.dart';
import '../filter/classical/filter_option_group.dart';
import '../filter/path_filter.dart';
import '../internal/constants.dart';
import '../internal/enums.dart';
import '../internal/plugin.dart';
import '../internal/progress_handler.dart';
import '../utils/convert_utils.dart';
import 'thumbnail.dart';
import 'types.dart';

/// The abstraction of albums and folders.
/// It represent a bucket in the `MediaStore` on Android,
/// and the `PHAssetCollection` object on iOS/macOS.
@immutable
class AssetPathEntity {
  AssetPathEntity({
    required this.id,
    required this.name,
    this.albumType = 1,
    this.lastModified,
    this.type = RequestType.common,
    this.isAll = false,
    PMFilter? filterOption,
    this.darwinSubtype,
    this.darwinType,
  }) : filterOption = filterOption ??= FilterOptionGroup();

  /// Obtain an entity from ID.
  ///
  /// This method is not recommend in general, since the corresponding folder
  /// could be deleted in anytime, which will cause properties invalid.
  static Future<AssetPathEntity> fromId(
    String id, {
    FilterOptionGroup? filterOption,
    RequestType type = RequestType.common,
    int albumType = 1,
  }) async {
    assert(albumType == 1 || Platform.isIOS || Platform.isMacOS);
    final AssetPathEntity entity = await obtainPathFromProperties(
      id: id,
      albumType: albumType,
      type: type,
      optionGroup: filterOption ?? FilterOptionGroup(),
    );
    return entity;
  }

  /// The ID of the album (asset collection).
  ///  * Android: `MediaStore.Images.Media.BUCKET_ID`.
  ///  * iOS/macOS: localIdentifier.
  final String id;

  /// The name of the album.
  ///  * Android: Path name.
  ///  * iOS/macOS: Album/Folder name.
  final String name;

  /// Total assets count of the path with the asynchronized getter.
  Future<int> get assetCountAsync => plugin.getAssetCountFromPath(this);

  /// The type of the album.
  ///  * Android: Always be 1.
  ///  * iOS: 1 - Album, 2 - Folder.
  final int albumType;

  /// The latest modification date of the album.
  ///
  /// This field will only be included when
  /// [FilterOptionGroup.containsPathModified] is true.
  final DateTime? lastModified;

  /// The value used internally by the user.
  /// Used to indicate the value that should be available inside the path.
  /// The [RequestType] of the album.
  ///
  /// this value is determined as final when user construct the album.
  final RequestType type;

  /// Whether the album contains all assets.
  ///
  /// An album includes all assets is the default album in general.
  final bool isAll;

  /// The collection of filter options of the album.
  final PMFilter filterOption;

  /// The darwin collection type, in android, the value is always null.
  ///
  /// If the [albumType] is 2, the value will be null.
  final PMDarwinAssetCollectionType? darwinType;

  /// The darwin collection subtype, in android, the value is always null.
  ///
  /// If the [albumType] is 2, the value will be null.
  final PMDarwinAssetCollectionSubtype? darwinSubtype;

  /// Call this method to obtain new path entity.
  static Future<AssetPathEntity> obtainPathFromProperties({
    required String id,
    int albumType = 1,
    RequestType type = RequestType.common,
    PMFilter? optionGroup,
    bool maxDateTimeToNow = true,
  }) async {
    optionGroup ??= FilterOptionGroup();
    final StateError error = StateError(
      'Unable to fetch properties for path $id.',
    );

    if (maxDateTimeToNow) {
      if (optionGroup is FilterOptionGroup) {
        optionGroup = optionGroup.copyWith(
          createTimeCond: optionGroup.createTimeCond.copyWith(
            max: DateTime.now(),
          ),
          updateTimeCond: optionGroup.updateTimeCond.copyWith(
            max: DateTime.now(),
          ),
        );
      }
    } else {
      optionGroup = optionGroup;
    }

    final Map<dynamic, dynamic>? result = await plugin.fetchPathProperties(
      id,
      type,
      optionGroup,
    );
    if (result == null) {
      throw error;
    }
    final Object? list = result['data'];
    if (list is List && list.isNotEmpty) {
      return ConvertUtils.convertToPathList(
        result.cast<String, dynamic>(),
        type: type,
        filterOption: optionGroup,
      ).first;
    }
    throw error;
  }

  /// Call this method to obtain new path entity.
  Future<AssetPathEntity> obtainForNewProperties({
    bool maxDateTimeToNow = true,
  }) {
    return AssetPathEntity.obtainPathFromProperties(
      id: id,
      albumType: albumType,
      type: type,
      optionGroup: filterOption,
    );
  }

  /// Entity list with pagination support.
  ///
  /// [page] should starts with and greater than 0.
  /// [size] is item count of current [page].
  Future<List<AssetEntity>> getAssetListPaged({
    required int page,
    required int size,
  }) {
    assert(albumType == 1, 'Only album can request for assets.');
    assert(size > 0, 'Page size must be greater than 0.');

    final filterOption = this.filterOption;

    if (filterOption is FilterOptionGroup) {
      assert(
        type == RequestType.image || !filterOption.onlyLivePhotos,
        'Filtering only Live Photos is only supported '
        'when the request type contains image.',
      );
    }
    return plugin.getAssetListPaged(
      id,
      page: page,
      size: size,
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
    final filterOption = this.filterOption;

    if (filterOption is FilterOptionGroup) {
      assert(
        type == RequestType.image || !filterOption.onlyLivePhotos,
        'Filtering only Live Photos is only supported '
        'when the request type contains image.',
      );
    }
    final int count = await assetCountAsync;
    if (end > count) {
      end = count;
    }
    return plugin.getAssetListRange(
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

  /// Obtain a new [AssetPathEntity] from the current one
  /// with refreshed properties.
  Future<AssetPathEntity?> fetchPathProperties({
    FilterOptionGroup? filterOptionGroup,
  }) async {
    final Map<dynamic, dynamic>? result = await plugin.fetchPathProperties(
      id,
      type,
      filterOptionGroup ?? filterOption,
    );
    if (result == null) {
      return null;
    }
    final Object? list = result['data'];
    if (list is List && list.isNotEmpty) {
      return ConvertUtils.convertToPathList(
        result.cast<String, dynamic>(),
        type: type,
        filterOption: filterOptionGroup ?? filterOption,
      ).first;
    }
    return null;
  }

  AssetPathEntity copyWith({
    String? id,
    String? name,
    int? albumType = 1,
    DateTime? lastModified,
    RequestType? type,
    bool? isAll,
    PMFilter? filterOption,
    PMDarwinAssetCollectionType? darwinType,
    PMDarwinAssetCollectionSubtype? darwinSubtype,
  }) {
    return AssetPathEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      albumType: albumType ?? this.albumType,
      lastModified: lastModified ?? this.lastModified,
      type: type ?? this.type,
      isAll: isAll ?? this.isAll,
      filterOption: filterOption ?? this.filterOption,
      darwinSubtype: darwinSubtype ?? this.darwinSubtype,
      darwinType: darwinType ?? this.darwinType,
    );
  }

  @override
  bool operator ==(Object other) {
    if (other is! AssetPathEntity) {
      return false;
    }
    return id == other.id &&
        name == other.name &&
        albumType == other.albumType &&
        type == other.type &&
        lastModified == other.lastModified &&
        isAll == other.isAll;
  }

  @override
  int get hashCode =>
      id.hashCode ^
      name.hashCode ^
      albumType.hashCode ^
      type.hashCode ^
      lastModified.hashCode ^
      isAll.hashCode;

  @override
  String toString() {
    return 'AssetPathEntity(id: $id, name: $name)';
  }
}

/// {@template photo_manager.AssetEntity}
/// The abstraction of assets (images/videos/audios).
/// It represents a series of fields `MediaStore` on Android
/// and the `PHAsset` object on iOS/macOS.
/// {@endtemplate}
@immutable
class AssetEntity {
  const AssetEntity({
    required this.id,
    required this.typeInt,
    required this.width,
    required this.height,
    this.duration = 0,
    this.orientation = 0,
    this.isFavorite = false,
    this.title,
    this.createDateSecond,
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
  /// This method is not recommend in general, since the corresponding asset
  /// could be deleted in anytime, which will cause properties invalid.
  static Future<AssetEntity?> fromId(String id) async {
    try {
      return await _obtainAssetFromId(id);
    } catch (e) {
      return null;
    }
  }

  /// Refresh the property of [AssetPathEntity] from the given ID.
  static Future<AssetEntity?> _obtainAssetFromId(String id) async {
    final Map<dynamic, dynamic>? result =
        await plugin.fetchEntityProperties(id);
    if (result == null) {
      return null;
    }
    return ConvertUtils.convertMapToAsset(result.cast<String, dynamic>());
  }

  /// Refresh properties for the current asset and return a new object.
  Future<AssetEntity?> obtainForNewProperties() => _obtainAssetFromId(id);

  /// The ID of the asset.
  ///  * Android: `_id` column in `MediaStore` database.
  ///  * iOS/macOS: `localIdentifier`.
  final String id;

  /// The title field of the asset.
  ///  * Android: `MediaStore.MediaColumns.DISPLAY_NAME`.
  ///  * iOS/macOS: `PHAssetResource.filename`.
  ///
  /// This field is nullable on iOS.
  /// If you need to obtain it, set [FilterOption.needTitle] to `true`
  /// or use the async getter [titleAsync].
  final String? title;

  ///  {@template photo_manager.AssetEntity.titleAsync}
  ///  * Android: `MediaStore.MediaColumns.DISPLAY_NAME`.
  ///  * iOS/macOS: `PHAssetResource.originalFilename`.
  ///  {@endtemplate}
  Future<String> get titleAsync => plugin.getTitleAsync(this);

  /// {@macro photo_manager.AssetEntity.titleAsync}
  Future<String> get titleAsyncWithSubtype =>
      plugin.getTitleAsync(this, subtype: subtype);

  /// {@macro photo_manager.AssetType}
  AssetType get type => AssetType.values[typeInt];

  /// The subtype of the asset.
  ///
  /// * Android: Always 0.
  /// * iOS/macOS: https://developer.apple.com/documentation/photokit/phassetmediasubtype
  final int subtype;

  /// Whether the asset is a live photo. Only valid on iOS/macOS.
  bool get isLivePhoto => subtype & _livePhotosType == _livePhotosType;

  /// The type value of the [type].
  final int typeInt;

  /// The duration of the asset, but in different units.
  ///  * [AssetType.audio] is in **milliseconds**.
  ///  * [AssetType.video] is in **seconds**.
  ///  * [AssetType.image] and [AssetType.other] are Always 0.
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
  ///    and locally exist (including cached or not).
  Future<bool> isLocallyAvailable({bool isOrigin = false}) {
    return plugin.isLocallyAvailable(id, isOrigin: isOrigin);
  }

  /// Obtain latitude and longitude.
  ///  * Android: Obtain from `MediaStore` or EXIF (Android 10).
  ///  * iOS/macOS: Obtain from photos.
  ///
  /// [LatLng.latitude] and [LatLng.longitude] might be 0.
  Future<LatLng> latlngAsync() => plugin.getLatLngAsync(this);

  /// Obtain the compressed file of the asset.
  ///
  /// See also:
  ///  * [fileWithSubtype] which can obtain the compressed file with subtype.
  ///  * [originFile] which can obtain the origin file.
  ///  * [originFileWithSubtype] which can obtain the origin file with subtype.
  ///  * [loadFile] which can obtain file with [PMProgressHandler].
  Future<File?> get file => _getFile();

  /// Obtain the compressed file of the asset with subtype.
  ///
  /// This method only takes effect on iOS, typically for Live Photos.
  ///
  /// See also:
  ///  * [file] which can obtain the compressed file.
  ///  * [originFile] which can obtain the origin file.
  ///  * [originFileWithSubtype] which can obtain the origin file with subtype.
  ///  * [loadFile] which can obtain file with [PMProgressHandler].
  Future<File?> get fileWithSubtype => _getFile(subtype: subtype);

  /// Obtain the original file that contain all EXIF information.
  ///
  /// Be aware the original file is not always suit for all kinds of usages.
  /// Typically when you're using an [Image] to display a HEIC image on
  /// Android 10, it'll failed to display the image.
  ///
  /// See also:
  ///  * [file] which can obtain the compressed file.
  ///  * [fileWithSubtype] which can obtain the compressed file with subtype.
  ///  * [originFileWithSubtype] which can obtain the origin file with subtype.
  ///  * [loadFile] which can obtain file with [PMProgressHandler].
  Future<File?> get originFile => _getFile(isOrigin: true);

  /// Obtain the origin file with subtype.
  ///
  /// This method only takes effect on iOS, typically for Live Photos.
  ///
  /// See also:
  ///  * [file] which can obtain the compressed file.
  ///  * [fileWithSubtype] which can obtain the compressed file with subtype.
  ///  * [originFile] which can obtain the origin file.
  ///  * [loadFile] which can obtain file with [PMProgressHandler].
  Future<File?> get originFileWithSubtype {
    return _getFile(isOrigin: true, subtype: subtype);
  }

  /// Obtain file of the asset with a [PMProgressHandler].
  ///
  /// [withSubtype] only takes effect on iOS, typically for Live Photos.
  ///
  /// See also:
  ///  * [file] which can obtain the compressed file.
  ///  * [fileWithSubtype] which can obtain the compressed file with subtype.
  ///  * [originFile] which can obtain the original file.
  ///  * [originFileWithSubtype] which can obtain the origin file with subtype.
  Future<File?> loadFile({
    bool isOrigin = true,
    bool withSubtype = false,
    PMProgressHandler? progressHandler,
  }) {
    return _getFile(
      isOrigin: isOrigin,
      subtype: withSubtype ? subtype : 0,
      progressHandler: progressHandler,
    );
  }

  /// Obtain the raw data of the asset.
  ///
  /// **Use it with cautious** since the original data might be epic large.
  /// Generally use this method only for images.
  Future<typed_data.Uint8List?> get originBytes => _getOriginBytes();

  /// Obtain the thumbnail data with [PMConstants.vDefaultThumbnailSize]
  /// size of the asset, typically use it for preview displays.
  ///
  /// {@template photo_manager.thumbnailForVideos}
  /// Thumbnail data for videos are images, not compressed video.
  /// {@endtemplate}
  ///
  /// See also:
  ///  * [thumbnailDataWithSize] which is a common method to obtain thumbnails.
  ///  * [thumbnailDataWithOption] which accepts customized [ThumbnailOption].
  Future<typed_data.Uint8List?> get thumbnailData => thumbnailDataWithSize(
        const ThumbnailSize.square(PMConstants.vDefaultThumbnailSize),
      );

  /// Obtain the thumbnail data with the given [width] and [height] of the asset.
  ///
  /// {@macro photo_manager.thumbnailForVideos}
  ///
  /// See also:
  ///  * [thumbnailData] which obtain the thumbnail data with fixed size.
  ///  * [thumbnailDataWithOption] which accepts customized [ThumbnailOption].
  Future<typed_data.Uint8List?> thumbnailDataWithSize(
    ThumbnailSize size, {
    ThumbnailFormat format = ThumbnailFormat.jpeg,
    int quality = 100,
    PMProgressHandler? progressHandler,
    int frame = 0,
  }) {
    assert(() {
      _checkThumbnailAssertion();
      return true;
    }());
    // Return null if the asset is audio or others.
    if (type == AssetType.audio || type == AssetType.other) {
      return Future<typed_data.Uint8List?>.value();
    }
    final ThumbnailOption option;
    if (Platform.isIOS || Platform.isMacOS) {
      option = ThumbnailOption.ios(
        size: size,
        format: format,
        quality: quality,
      );
    } else {
      option = ThumbnailOption(
        size: size,
        format: format,
        quality: quality,
        frame: frame,
      );
    }
    assert(() {
      option.checkAssertions();
      return true;
    }());

    return thumbnailDataWithOption(option, progressHandler: progressHandler);
  }

  /// Obtain the thumbnail data with the given customized [ThumbnailOption].
  ///
  /// See also:
  ///  * [thumbnailData] which obtain the thumbnail data with fixed size.
  ///  * [thumbnailDataWithSize] which is a common method to obtain thumbnails.
  Future<typed_data.Uint8List?> thumbnailDataWithOption(
    ThumbnailOption option, {
    PMProgressHandler? progressHandler,
  }) {
    assert(() {
      _checkThumbnailAssertion();
      return true;
    }());
    // Return null if the asset is audio or others.
    if (type == AssetType.audio || type == AssetType.other) {
      return Future<typed_data.Uint8List?>.value();
    }
    assert(() {
      option.checkAssertions();
      return true;
    }());
    return plugin.getThumbnail(
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
  final int? createDateSecond;

  /// The create time of the asset in [DateTime].
  DateTime get createDateTime {
    final int value = createDateSecond ?? 0;
    return DateTime.fromMillisecondsSinceEpoch(value * 1000);
  }

  /// The modified time in unix timestamp of the asset.
  final int? modifiedDateSecond;

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
    int subtype = 0,
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
      subtype: subtype,
    );
    if (path == null) {
      return null;
    }
    return File(path);
  }

  Future<typed_data.Uint8List?> _getOriginBytes({
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
  final int orientation;

  /// Whether the asset is favorite on the device.
  ///  * Android: Always false.
  ///  * iOS/macOS: `PHAsset.isFavorite`.
  ///
  /// See also:
  ///  * [IosEditor.favoriteAsset] to update the favorite status.
  final bool isFavorite;

  /// The relative path abstraction of the asset.
  ///  * Android 10 and above: `MediaStore.MediaColumns.RELATIVE_PATH`.
  ///  * Android 9 and below: The parent path of `MediaStore.MediaColumns.DATA`.
  ///  * iOS/macOS: Always null.
  final String? relativePath;

  /// The mime type of the asset.
  ///  * Android: `MediaStore.MediaColumns.MIME_TYPE`.
  ///  * iOS/macOS: Always null. Use the async getter [mimeTypeAsync] instead.
  ///
  /// See also:
  ///  * [mimeTypeAsync] which is the asynchronized getter of the MIME type.
  ///  * https://developer.android.com/reference/android/provider/MediaStore.MediaColumns#MIME_TYPE
  final String? mimeType;

  /// Get the mime type async.
  ///  * Android: `MediaStore.MediaColumns.MIME_TYPE`.
  ///  * iOS/macOS: MIME type from `PHAssetResource.uniformTypeIdentifier`.
  ///
  /// For Live Photos on iOS, the getter returns
  /// the paired image file's MIME type.
  ///
  /// See also:
  ///  * [mimeType] which is the synchronized getter of the MIME type.
  ///  * https://developer.apple.com/library/archive/documentation/FileManagement/Conceptual/understanding_utis/understand_utis_conc/understand_utis_conc.html#//apple_ref/doc/uid/TP40001319-CH202-SW1
  Future<String?> get mimeTypeAsync => plugin.getMimeTypeAsync(this);

  AssetEntity copyWith({
    String? id,
    int? typeInt,
    int? width,
    int? height,
    int? duration,
    int? orientation,
    bool? isFavorite,
    String? title,
    int? createDateSecond,
    int? modifiedDateSecond,
    String? relativePath,
    double? latitude,
    double? longitude,
    String? mimeType,
    int? subtype,
  }) {
    return AssetEntity(
      id: id ?? this.id,
      typeInt: typeInt ?? this.typeInt,
      width: width ?? this.width,
      height: height ?? this.height,
      duration: duration ?? this.duration,
      orientation: orientation ?? this.orientation,
      isFavorite: isFavorite ?? this.isFavorite,
      title: title ?? this.title,
      createDateSecond: createDateSecond ?? this.createDateSecond,
      modifiedDateSecond: modifiedDateSecond ?? this.modifiedDateSecond,
      relativePath: relativePath ?? this.relativePath,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      mimeType: mimeType ?? this.mimeType,
      subtype: subtype ?? this.subtype,
    );
  }

  @override
  int get hashCode => id.hashCode ^ isFavorite.hashCode;

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

/// Represents a geographical location as a latitude-longitude pair.
@immutable
class LatLng {
  /// Creates a new [LatLng] object with the given latitude and longitude.
  const LatLng({this.latitude, this.longitude});

  /// The latitude of this location in degrees.
  final double? latitude;

  /// The longitude of this location in degrees.
  final double? longitude;

  @override
  bool operator ==(Object other) {
    if (other is! AssetEntity) {
      return false;
    }
    return latitude == other.latitude && longitude == other.longitude;
  }

  @override
  int get hashCode => latitude.hashCode ^ longitude.hashCode;
}

/// The subtype value for Live Photos.
const int _livePhotosType = 1 << 3;

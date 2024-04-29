// Copyright 2018 The FlutterCandies author. All rights reserved.
// Use of this source code is governed by an Apache license that can be found
// in the LICENSE file.

import 'dart:io';

import 'package:flutter/foundation.dart';

import '../../../platform_utils.dart';
import '../../utils/column_utils.dart';

/// {@template custom_columns}
///
/// A class that contains the names of the columns used in the custom filter.
///
/// The names of the columns are different on different platforms. For example,
/// the `width` column on Android is `width`, but on iOS it is `pixelWidth`.
/// The definition of the column name can be found in next link:
///  - Android: https://developer.android.com/reference/android/provider/MediaStore.MediaColumns
///  - iOS: https://developer.apple.com/documentation/photokit/phasset
///
/// Special Columns to see [AndroidMediaColumns] and [DarwinColumns].
///
/// Example:
/// ```dart
///  OrderByItem(CustomColumns.base.width, true);
/// ```
///
/// {@endtemplate}
class CustomColumns {
  /// {@macro custom_columns}
  const CustomColumns();

  /// The base columns, contains the common columns.
  static const CustomColumns base = CustomColumns();

  /// The android columns, contains the android specific columns.
  static const AndroidMediaColumns android = AndroidMediaColumns();

  /// The darwin columns, contains the ios and macos specific columns.
  static const DarwinColumns darwin = DarwinColumns();

  /// The ohos columns, contains the ohos specific columns.
  static const AndroidMediaColumns ohos = AndroidMediaColumns();

  static const ColumnUtils utils = ColumnUtils.instance;

  /// Whether the current platform is android.
  bool get isAndroid => Platform.isAndroid;

  /// Whether the current platform is ios or macos.
  bool get isDarwin => Platform.isIOS || Platform.isMacOS;

  /// Whether the current platform is OpenHarmony OS.
  bool get isOhos => PlatformUtils.isOhos;

  /// The id column.
  String get id {
    if (isAndroid) {
      return '_id';
    } else if (isDarwin) {
      return 'localIdentifier';
    } else if (isOhos) {
      return 'uri';
    }
    throw UnsupportedError('Unsupported platform with id');
  }

  /// The media type column.
  ///
  /// The value is number,
  ///
  /// In android:
  /// - 1: image
  /// - 2: audio
  /// - 3: video
  ///
  /// In iOS/macOS:
  /// - 1: image
  /// - 2: video
  /// - 3: audio
  String get mediaType {
    if (isAndroid || isOhos) {
      return 'media_type';
    } else if (isDarwin) {
      return 'mediaType';
    } else {
      throw UnsupportedError('Unsupported platform with mediaType');
    }
  }

  /// The width column.
  ///
  /// In android, the value of this column maybe null.
  ///
  /// In iOS/macOS, the value of this column not null.
  String get width {
    if (isAndroid || isOhos) {
      return 'width';
    } else if (isDarwin) {
      return 'pixelWidth';
    } else {
      throw UnsupportedError('Unsupported platform with width');
    }
  }

  /// The height column.
  ///
  /// In android, the value of this column maybe null.
  ///
  /// In iOS/macOS, the value of this column not null.
  String get height {
    if (isAndroid || isOhos) {
      return 'height';
    } else if (isDarwin) {
      return 'pixelHeight';
    } else {
      throw UnsupportedError('Unsupported platform with height');
    }
  }

  /// The duration column.
  ///
  /// In android, the value of this column maybe null.
  ///
  /// In iOS/macOS, the value of this column is 0 when the media is image.
  String get duration {
    if (isAndroid || isOhos) {
      return 'duration';
    } else if (isDarwin) {
      return 'duration';
    } else {
      throw UnsupportedError('Unsupported platform with duration');
    }
  }

  /// The creation date column.
  ///
  /// {@template date_column}
  ///
  /// The value is unix timestamp seconds in android.
  ///
  /// The value is NSDate in iOS/macOS.
  ///
  /// Please use [ColumnUtils.convertDateTimeToSql] to convert date value.
  ///
  /// Simple use: [DateColumnWhereCondition].
  ///
  /// Exmaple:
  /// ```dart
  /// final date = DateTime(2015, 6, 15);
  /// final condition = DateColumnWhereCondition(
  //    column: CustomColumns.base.createDate,
  //    operator: '<=',
  //    value: date,
  //  );
  /// ```
  ///
  /// {@endtemplate}
  String get createDate {
    if (isAndroid || isOhos) {
      return 'date_added';
    } else if (isDarwin) {
      return 'creationDate';
    } else {
      throw UnsupportedError('Unsupported platform with createDate');
    }
  }

  /// The modified date column.
  ///
  /// {@macro date_column}
  String get modifiedDate {
    if (isAndroid || isOhos) {
      return 'date_modified';
    } else if (isDarwin) {
      return 'modificationDate';
    } else {
      throw UnsupportedError('Unsupported platform with modifiedDate');
    }
  }

  /// The favorite column.
  ///
  /// in darwin: 1 is favorite, 0 is not favorite.
  ///
  ///
  String get isFavorite {
    if (isAndroid || isOhos) {
      return 'is_favorite';
    } else if (isDarwin) {
      return 'favorite';
    } else {
      throw UnsupportedError('Unsupported platform with isFavorite');
    }
  }

  List<String> getValues() {
    return [
      id,
      mediaType,
      width,
      height,
      duration,
      createDate,
      modifiedDate,
      isFavorite,
    ];
  }

  static List<String> values() {
    return const CustomColumns().getValues();
  }

  static List<String> dateColumns() {
    if (Platform.isAndroid) {
      const android = CustomColumns.android;
      return [
        android.createDate,
        android.modifiedDate,
        android.dateTaken,
        android.dateExpires,
      ];
    } else if (Platform.isIOS || Platform.isMacOS) {
      const darwin = CustomColumns.darwin;
      return [darwin.createDate, darwin.modifiedDate];
    }
    return [];
  }

  static List<String> platformValues() {
    if (Platform.isAndroid) {
      return const AndroidMediaColumns().getValues();
    } else if (Platform.isIOS || Platform.isMacOS) {
      return const DarwinColumns().getValues();
    } else if (PlatformUtils.isOhos) {
      return const OhosColumns().getValues();
    } else {
      throw UnsupportedError('Unsupported platform with platformValues');
    }
  }
}

// columns: [instance_id, compilation, disc_number, duration, album_artist,
// resolution, orientation, artist, author, format, height, is_drm,
// bucket_display_name, owner_package_name, parent, volume_name,
// date_modified, writer, date_expires, composer,
// _display_name, datetaken, mime_type, bitrate, cd_track_number, _id,
// xmp, year, _data, _size, album, genre, title, width, is_favorite,
// is_trashed, group_id, document_id, generation_added, is_download,
// generation_modified, is_pending, date_added, capture_framerate, num_tracks,
// original_document_id, bucket_id, media_type, relative_path]

/// A class that contains the names of the columns used in the custom filter.
///
/// About the values mean, please see document of android: https://developer.android.com/reference/android/provider/MediaStore
class AndroidMediaColumns extends CustomColumns {
  const AndroidMediaColumns();

  String _getKey(String value) {
    if (isAndroid) {
      return value;
    } else {
      throw UnsupportedError('Unsupported column $value in platform');
    }
  }

  String get instanceId => _getKey('instance_id');

  String get compilation => _getKey('compilation');

  String get discNumber => _getKey('disc_number');

  String get albumArtist => _getKey('album_artist');

  String get resolution => _getKey('resolution');

  String get orientation => _getKey('orientation');

  String get artist => _getKey('artist');

  String get author => _getKey('author');

  String get format => _getKey('format');

  String get isDrm => _getKey('is_drm');

  String get bucketDisplayName => _getKey('bucket_display_name');

  String get ownerPackageName => _getKey('owner_package_name');

  String get parent => _getKey('parent');

  String get volumeName => _getKey('volume_name');

  String get writer => _getKey('writer');

  String get dateExpires => _getKey('date_expires');

  String get composer => _getKey('composer');

  String get displayName => _getKey('_display_name');

  String get dateTaken => _getKey('datetaken');

  String get mimeType => _getKey('mime_type');

  String get bitRate => _getKey('bitrate');

  String get cdTrackNumber => _getKey('cd_track_number');

  String get xmp => _getKey('xmp');

  String get year => _getKey('year');

  String get data => _getKey('_data');

  String get size => _getKey('_size');

  String get album => _getKey('album');

  String get genre => _getKey('genre');

  String get title => _getKey('title');

  String get isTrashed => _getKey('is_trashed');

  String get groupId => _getKey('group_id');

  String get documentId => _getKey('document_id');

  String get generationAdded => _getKey('generation_added');

  String get isDownload => _getKey('is_download');

  String get generationModified => _getKey('generation_modified');

  String get isPending => _getKey('is_pending');

  String get captureFrameRate => _getKey('capture_framerate');

  String get numTracks => _getKey('num_tracks');

  String get originalDocumentId => _getKey('original_document_id');

  String get bucketId => _getKey('bucket_id');

  String get relativePath => _getKey('relative_path');

  @override
  List<String> getValues() {
    return [
      ...super.getValues(),
      instanceId,
      compilation,
      discNumber,
      albumArtist,
      resolution,
      orientation,
      artist,
      author,
      format,
      isDrm,
      bucketDisplayName,
      ownerPackageName,
      parent,
      volumeName,
      writer,
      dateExpires,
      composer,
      displayName,
      dateTaken,
      mimeType,
      bitRate,
      cdTrackNumber,
      xmp,
      year,
      data,
      size,
      album,
      genre,
      title,
      isTrashed,
      groupId,
      documentId,
      generationAdded,
      isDownload,
      generationModified,
      isPending,
      captureFrameRate,
      numTracks,
      originalDocumentId,
      bucketId,
      relativePath,
    ];
  }

  static List<String> values() {
    return const AndroidMediaColumns().getValues();
  }
}

/// A class that contains the names of the columns of the iOS/macOS platform.
///
/// About the values mean, please see document of iOS: https://developer.apple.com/documentation/photokit/phasset
class DarwinColumns extends CustomColumns {
  const DarwinColumns();

  String _getKey(String value) {
    if (isDarwin) {
      return value;
    } else {
      throw UnsupportedError('Unsupported column $value in platform');
    }
  }

  String get mediaSubtypes => _getKey('mediaSubtypes');

  String get sourceType => _getKey('sourceType');

  String get location => _getKey('location');

  String get hidden => _getKey('hidden');

  String get hasAdjustments => _getKey('hasAdjustments');

  String get adjustmentFormatIdentifier =>
      _getKey('adjustmentFormatIdentifier');

  // An enumeration of asset playback styles that dictate how to present an asset to the user.
  // unsupported = 0, image = 1, imageAnimated = 2, livePhoto = 3, video = 4, videoLooping = 5
  //
  // Ex: If I want to filter only GIFs in SQL query string, I can use:
  // '${CustomColumns.darwin.playbackStyle} == 2'
  //
  // About the playbackStyle, please see document of iOS: https://developer.apple.com/documentation/photokit/phasset/playbackstyle
  String get playbackStyle => _getKey('playbackStyle');

  @override
  List<String> getValues() {
    return [
      ...super.getValues(),
      mediaSubtypes,
      sourceType,
      location,
      hidden,
      hasAdjustments,
      adjustmentFormatIdentifier,
      playbackStyle,
    ];
  }

  static List<String> values() {
    return const DarwinColumns().getValues();
  }
}

/// A class that contains the names of the columns used in the custom filter.
///
/// About the values mean, please see document of ohos: https://developer.android.com/reference/android/provider/MediaStore
class OhosColumns extends CustomColumns {
  const OhosColumns();

  String _getKey(String value) {
    if (isOhos) {
      return value;
    } else {
      throw UnsupportedError('Unsupported column $value in platform');
    }
  }

  String get displayName => _getKey('display_name');

  String get size => _getKey('size');

  String get dateTaken => _getKey('date_taken');

  String get orientation => _getKey('orientation');

  String get title => _getKey('title');

  @override
  List<String> getValues() {
    return [
      ...super.getValues(),
      displayName,
      size,
      dateTaken,
      orientation,
      title,
    ];
  }

  static List<String> values() {
    return const OhosColumns().getValues();
  }
}

/// Where item class
///
/// If text() throws an exception, it will return an empty string.
class WhereItem {
  const WhereItem(this.column, this.condition);

  final ValueGetter<String> column;
  final ValueGetter<String> condition;

  String text() {
    try {
      return '${column()} ${condition()}';
    } on UnsupportedError {
      return '';
    }
  }
}

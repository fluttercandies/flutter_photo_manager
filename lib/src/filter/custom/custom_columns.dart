import 'dart:io';

/// A class that contains the names of the columns used in the custom filter.
///
/// The names of the columns are different on different platforms.
///
/// For example, the `width` column on Android is `width`, but on iOS it is `pixelWidth`.
///
/// The definition of the column name can be found in next link:
///
/// Android: https://developer.android.com/reference/android/provider/MediaStore.MediaColumns
///
/// iOS: https://developer.apple.com/documentation/photokit/phasset
///
/// Special Columns to see [AndroidMediaColumns] and [DarwinColumns].
class CustomColumns {
  CustomColumns();

  bool get isAndroid => Platform.isAndroid;
  bool get isDarwin => Platform.isIOS || Platform.isMacOS;

  String get id {
    if (isAndroid) {
      return '_id';
    } else if (isDarwin) {
      return 'localIdentifier';
    } else {
      throw UnsupportedError('Unsupported platform with id');
    }
  }

  String get mediaType {
    if (isAndroid) {
      return 'media_type';
    } else if (isDarwin) {
      return 'mediaType';
    } else {
      throw UnsupportedError('Unsupported platform with mediaType');
    }
  }

  String get width {
    if (isAndroid) {
      return 'width';
    } else if (isDarwin) {
      return 'pixelWidth';
    } else {
      throw UnsupportedError('Unsupported platform with width');
    }
  }

  String get height {
    if (isAndroid) {
      return 'height';
    } else if (isDarwin) {
      return 'pixelHeight';
    } else {
      throw UnsupportedError('Unsupported platform with height');
    }
  }

  String get duration {
    if (isAndroid) {
      return 'duration';
    } else if (isDarwin) {
      return 'duration';
    } else {
      throw UnsupportedError('Unsupported platform with duration');
    }
  }

  String get createDate {
    if (isAndroid) {
      return 'date_added';
    } else if (isDarwin) {
      return 'creationDate';
    } else {
      throw UnsupportedError('Unsupported platform with createDate');
    }
  }

  String get modifiedDate {
    if (isAndroid) {
      return 'date_modified';
    } else if (isDarwin) {
      return 'modificationDate';
    } else {
      throw UnsupportedError('Unsupported platform with modifiedDate');
    }
  }

  String get isFavorite {
    if (isAndroid) {
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
    return CustomColumns().getValues();
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
class AndroidMediaColumns extends CustomColumns {
  AndroidMediaColumns();

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

  List<String> getValues() {
    return [
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
    return AndroidMediaColumns().getValues();
  }
}

class DarwinColumns extends CustomColumns {
  DarwinColumns();

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

  List<String> getValues() {
    return [
      mediaSubtypes,
      sourceType,
      location,
      hidden,
      hasAdjustments,
      adjustmentFormatIdentifier,
    ];
  }

  static List<String> values() {
    return DarwinColumns().getValues();
  }
}

/// Where item class
///
/// If text() throws an exception, it will return an empty string.
class WhereItem {
  final String column;
  final String condition;

  WhereItem(this.column, this.condition);

  String text() {
    try {
      return "$column $condition";
    } on UnsupportedError {
      return '';
    }
  }
}

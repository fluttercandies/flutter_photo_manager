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
      throw UnsupportedError('Unsupported platform');
    }
  }

  String get mediaType {
    if (isAndroid) {
      return 'media_type';
    } else if (isDarwin) {
      return 'mediaType';
    } else {
      throw UnsupportedError('Unsupported platform');
    }
  }

  String get width {
    if (isAndroid) {
      return 'width';
    } else if (isDarwin) {
      return 'pixelWidth';
    } else {
      throw UnsupportedError('Unsupported platform');
    }
  }

  String get height {
    if (isAndroid) {
      return 'height';
    } else if (isDarwin) {
      return 'pixelHeight';
    } else {
      throw UnsupportedError('Unsupported platform');
    }
  }

  String get duration {
    if (isAndroid) {
      return 'duration';
    } else if (isDarwin) {
      return 'duration';
    } else {
      throw UnsupportedError('Unsupported platform');
    }
  }

  String get createDate {
    if (isAndroid) {
      return 'date_added';
    } else if (isDarwin) {
      return 'creationDate';
    } else {
      throw UnsupportedError('Unsupported platform');
    }
  }

  String get modifiedDate {
    if (isAndroid) {
      return 'date_modified';
    } else if (isDarwin) {
      return 'modificationDate';
    } else {
      throw UnsupportedError('Unsupported platform');
    }
  }
}

class AndroidMediaColumns extends CustomColumns {
  AndroidMediaColumns();

  String get bucketId => 'bucket_id';
  String get bucketDisplayName => 'bucket_display_name';
  String get displayName => '_display_name';
}

class DarwinColumns extends CustomColumns {}

// Copyright 2018 The FlutterCandies author. All rights reserved.
// Use of this source code is governed by an Apache license that can be found
// in the LICENSE file.

import 'dart:io';

/// Utility functions for working with the [CustomColumns] class.
class ColumnUtils {
  const ColumnUtils._internal();

  /// An instance of the [ColumnUtils] class.
  static const instance = ColumnUtils._internal();

  /// Converts a [DateTime] object to the format used by [MediaStore][] on Android or [NSPredicate][] on iOS/macOS.
  ///
  /// [MediaStore]: https://developer.android.com/reference/android/provider/MediaStore
  /// [NSPredicate]: https://developer.apple.com/documentation/foundation/nspredicate
  String convertDateTimeToSql(DateTime date, {bool isSeconds = true}) {
    final unix = date.millisecondsSinceEpoch;

    if (Platform.isAndroid) {
      return isSeconds ? (unix ~/ 1000).toString() : unix.toString();
    } else if (Platform.isIOS || Platform.isMacOS) {
      // The NSDate epoch starts at 2001-01-01T00:00:00Z, so we subtract this from the Unix timestamp in seconds.
      final secondsFrom2001 = (unix / 1000) - 978307200;
      final dateStr = secondsFrom2001.toStringAsFixed(6);
      return 'CAST($dateStr, "NSDate")';
    } else {
      throw UnsupportedError('Unsupported platform with date');
    }
  }
}

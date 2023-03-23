import 'dart:io';

/// The utils for the [CustomColumns].
class ColumnUtils {
  const ColumnUtils._internal();

  static const ColumnUtils instance = ColumnUtils._internal();

  /// Convert to the format for the [MediaStore] in android or [NSPredicate] in iOS.
  String convertDateTimeToSql(DateTime date, {bool isSeconds = true}) {
    final unix = date.millisecondsSinceEpoch;
    if (Platform.isAndroid) {
      return isSeconds ? (unix ~/ 1000).toString() : unix.toString();
    } else if (Platform.isIOS || Platform.isMacOS) {
      final date = (unix / 1000) - 978307200;
      // 978307200 is 2001-01-01 00:00:00 UTC, the 0 of the NSDate.
      // The NSDate will be converted to CAST(unix - 978307200, "NSDate") in NSPredicate.
      final dateStr = date.toStringAsFixed(6);
      return 'CAST($dateStr, "NSDate")';
    } else {
      throw UnsupportedError('Unsupported platform with date');
    }
  }
}

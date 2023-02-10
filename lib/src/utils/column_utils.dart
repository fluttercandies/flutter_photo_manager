import 'dart:io';

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
      final dateStr = date.toStringAsFixed(6);
      return 'CAST($dateStr, "NSDate")';
    } else {
      throw UnsupportedError('Unsupported platform with date');
    }
  }
}

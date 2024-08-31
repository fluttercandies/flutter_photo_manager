import 'package:path_provider/path_provider.dart';

/// Because the photo_manager plugin does not depend on the path_provider plugin,
/// we need to create a new class in the example to get the log file path.
class PMVerboseLogUtil {
  PMVerboseLogUtil();

  static final shared = PMVerboseLogUtil();

  static String? _logDirPath;

  String _logFilePath = '';

  /// Get the log file path.
  ///
  /// Use in the `PhotoManager.setLog` method.
  Future<String> getLogFilePath() async {
    if (_logFilePath.isNotEmpty) {
      return _logFilePath;
    }

    if (_logDirPath == null) {
      final cacheDir = await getApplicationCacheDirectory();
      _logDirPath = cacheDir.path;
    }

    final timeStr = DateTime.now().toIso8601String();
    _logFilePath = '$_logDirPath/pmlog-$timeStr.txt';

    return _logFilePath;
  }
}

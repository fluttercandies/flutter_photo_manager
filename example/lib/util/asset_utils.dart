import 'dart:io';

import 'package:http/http.dart';
import 'package:path_provider/path_provider.dart';

class AssetsUtils {
  AssetsUtils._();

  static const String jpegUrl =
      'https://gitlab.com/CaiJingLong/ExampleAsset/-/raw/main/IMG_1096.jpeg?ref_type=heads';

  static Future<File> downloadJpeg() async {
    final cacheDir = await getTemporaryDirectory();

    final dtMs = DateTime.now().millisecondsSinceEpoch;
    final file = File('${cacheDir.path}/$dtMs.jpg');

    final bytes = await get(Uri.parse(jpegUrl));
    await file.writeAsBytes(bytes.bodyBytes);
    return file;
  }
}

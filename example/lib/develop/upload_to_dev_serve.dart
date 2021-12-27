import 'dart:io';
import 'dart:typed_data';

import 'package:photo_manager/photo_manager.dart';

class UploadToDevServer {
  const UploadToDevServer._();

  static Future<void> upload(AssetEntity entity) async {
    final Uint8List? data = await entity.originBytes;
    if (data == null) {
      return;
    }
    print(data.length);
    final HttpClient client = HttpClient();

    final HttpClientRequest req = await client.postUrl(
      Uri.parse('http://192.168.31.252:8090/upload'),
    );
    req.add(data);
    await req.close();

    client.close();
  }
}

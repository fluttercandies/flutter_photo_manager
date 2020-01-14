import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:photo_manager/photo_manager.dart';

class DeveloperIndexPage extends StatefulWidget {
  @override
  _DeveloperIndexPageState createState() => _DeveloperIndexPageState();
}

class _DeveloperIndexPageState extends State<DeveloperIndexPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("develop index"),
      ),
      body: ListView(
        children: <Widget>[
          RaisedButton(
            child: Text("upload file to local to test EXIF."),
            onPressed: _upload,
          ),
        ],
      ),
    );
  }

  void _upload() async {
    final path = await PhotoManager.getImageAsset();
    final assetList = await path[0].getAssetListRange(start: 0, end: 5);
    final asset = assetList[0];

    // for (final tmpAsset in assetList) {
    //   await tmpAsset.originFile;
    // }

    final file = await asset.originFile;

    print("file length = ${file.lengthSync()}");

    http.BaseClient client = http.Client();
    final req = http.MultipartRequest(
      "post",
      Uri.parse("http://172.16.100.7:10001/upload/file"),
    );

    req.files
        .add(await http.MultipartFile.fromPath("file", file.absolute.path));

    req.fields["type"] = "jpg";

    final response = await client.send(req);
    final body = await utf8.decodeStream(response.stream);
    print(body);
  }
}

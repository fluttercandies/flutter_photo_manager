import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

class SaveImageExample extends StatefulWidget {
  @override
  _SaveImageExampleState createState() => _SaveImageExampleState();
}

class _SaveImageExampleState extends State<SaveImageExample> {
  final imageUrl =
      "https://ww4.sinaimg.cn/bmiddle/005TR3jLly1ga48shax8zj30u02ickjl.jpg";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Save image"),
      ),
      body: Container(
        child: RaisedButton(
          child: Text("Save image"),
          onPressed: () async {
            final client = HttpClient();
            final req = await client.getUrl(Uri.parse(imageUrl));
            final resp = await req.close();
            List<int> bytes = [];
            resp.listen((data) {
              bytes.addAll(data);
            }, onDone: () {
              final image = Uint8List.fromList(bytes);
              saveImage(image);
              client.close();
            });
          },
        ),
      ),
    );
  }

  void saveImage(Uint8List uint8List) async {
    final asset = await PhotoManager.editor.saveImage(uint8List);
    print(asset);
  }
}

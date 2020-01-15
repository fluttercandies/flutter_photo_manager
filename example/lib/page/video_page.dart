import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_ijkplayer/flutter_ijkplayer.dart';

class VidePage extends StatefulWidget {
  @override
  _VidePageState createState() => _VidePageState();
}

class _VidePageState extends State<VidePage> {
  IjkMediaController controller = IjkMediaController();

  @override
  void initState() {
    super.initState();
    final file = File(
        "/storage/emulated/0/Android/data/top.kikt.imagescannerexample/cache/1.mp4");
    if (file.existsSync()) {
      print(file.lengthSync());
      controller.setDataSource(DataSource.file(file), autoPlay: true);
    }
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Video page"),
      ),
      body: Container(
        child: IjkPlayer(mediaController: controller),
      ),
    );
  }
}

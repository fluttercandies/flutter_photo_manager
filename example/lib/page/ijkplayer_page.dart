import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_ijkplayer/flutter_ijkplayer.dart';
import 'package:photo_manager/photo_manager.dart';

class IjkPlayerPage extends StatefulWidget {
  final AssetEntity entity;

  const IjkPlayerPage({Key key, this.entity}) : super(key: key);

  @override
  _IjkPlayerPageState createState() => _IjkPlayerPageState();
}

class _IjkPlayerPageState extends State<IjkPlayerPage> {
  IjkMediaController controller = IjkMediaController();

  @override
  void initState() {
    super.initState();
    useHardwareDecoding();
    widget.entity.getMediaUrl().then((url) async {
      print(url);
      await controller.setDataSource(DataSource.photoManagerUrl(url));
      await controller.play();
    });
  }

  void useHardwareDecoding() {
    controller.addIjkPlayerOptions([
      TargetPlatform.iOS
    ], [
      IjkOption(IjkOptionCategory.player, 'videotoolbox', 1),
      IjkOption(IjkOptionCategory.player, 'video-max-frame-width-default', 1),
      IjkOption(IjkOptionCategory.player, 'videotoolbox-max-frame-width', 1920),
      // IjkOption(IjkOptionCategory.player, 'videotoolbox-max-frame-width', 960),
    ]);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Column(
        children: <Widget>[
          AspectRatio(
            aspectRatio: 1920 / 1080,
            child: IjkPlayer(mediaController: controller),
          ),
        ],
      ),
    );
  }
}

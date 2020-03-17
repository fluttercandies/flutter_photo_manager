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
  final controller = IjkMediaController();

  @override
  void initState() {
    super.initState();
    useHardwareDecoding();// some h265 video need hardware-decoding
    widget.entity.getMediaUrl().then((url) async {
      await controller.setDataSource(DataSource.photoManagerUrl(url));
      await controller.play();
    });
  }

  void useHardwareDecoding() {
    controller.addIjkPlayerOptions([
      TargetPlatform.iOS,
      TargetPlatform.android,
    ], [
      IjkOption(IjkOptionCategory.player, 'videotoolbox', 1),
      IjkOption(IjkOptionCategory.player, 'video-max-frame-width-default', 1),
      IjkOption(IjkOptionCategory.player, 'videotoolbox-max-frame-width', 1920),
      IjkOption(IjkOptionCategory.player, 'mediacodec', 1),
      IjkOption(IjkOptionCategory.player, 'mediacodec-hevc', 1),
    ]);
  }

  Future<void> release() async {
    controller.dispose();
  }

  @override
  void dispose() {
    release();
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
            child: IjkPlayer(
              mediaController: controller,
            ),
          ),
        ],
      ),
    );
  }
}

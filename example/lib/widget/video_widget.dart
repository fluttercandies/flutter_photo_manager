import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class VideoWidget extends StatefulWidget {
  final String mediaUrl;

  const VideoWidget({
    Key key,
    @required this.mediaUrl,
  }) : super(key: key);

  @override
  _VideoWidgetState createState() => _VideoWidgetState();
}

class _VideoWidgetState extends State<VideoWidget> {
  VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    // _controller = VideoPlayerController.file(widget.file)
    _controller = VideoPlayerController.network(widget.mediaUrl)
      ..initialize().then((_) {
        setState(() {});
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _controller.value.initialized
        ? AspectRatio(
            aspectRatio: _controller.value.aspectRatio,
            child: GestureDetector(
              child: buildVideoPlayer(),
              onTap: () {
                _controller.value.isPlaying
                    ? _controller.pause()
                    : _controller.play();
                setState(() {});
              },
            ),
          )
        : Container();
  }

  buildVideoPlayer() {
    var children = <Widget>[
      VideoPlayer(_controller),
    ];

    if (!_controller.value.isPlaying) {
      children.add(
        IgnorePointer(
          child: Center(
              child: Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.black38,
              borderRadius: BorderRadius.circular(30),
            ),
            child: Icon(
              Icons.play_arrow,
              color: Colors.white,
            ),
          )),
        ),
      );
    }

    return Stack(
      children: children,
    );
  }
}

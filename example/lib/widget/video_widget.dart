import 'dart:io';

import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:video_player/video_player.dart';

class VideoWidget extends StatefulWidget {
  const VideoWidget({
    Key? key,
    required this.entity,
    this.mediaUrl,
  }) : super(key: key);

  final AssetEntity entity;
  final String? mediaUrl;

  @override
  _VideoWidgetState createState() => _VideoWidgetState();
}

class _VideoWidgetState extends State<VideoWidget> {
  VideoPlayerController? _controller;

  bool get isAudio => widget.entity.type == AssetType.audio;

  @override
  void initState() {
    super.initState();
    if (widget.mediaUrl != null) {
      _controller = VideoPlayerController.network(widget.mediaUrl!)
        ..initialize()
        ..addListener(() => setState(() {}));
    } else {
      widget.entity.file.then((File? file) {
        if (!mounted || file == null) {
          return;
        }
        _controller = VideoPlayerController.file(file)
          ..initialize()
          ..addListener(() => setState(() {}));
        setState(() {});
      });
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Widget buildVideoPlayer() {
    final VideoPlayerController controller = _controller!;
    return Stack(
      children: <Widget>[
        if (isAudio)
          Container(
            alignment: Alignment.center,
            color: Colors.white,
            child: const Icon(Icons.audiotrack, size: 200, color: Colors.grey),
          )
        else
          VideoPlayer(controller),
        if (!controller.value.isPlaying)
          IgnorePointer(
            child: Center(
              child: Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.black38,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const Icon(Icons.play_arrow, color: Colors.white),
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_controller?.value.isInitialized != true) {
      return const SizedBox.shrink();
    }
    final VideoPlayerController c = _controller!;
    return AspectRatio(
      aspectRatio: isAudio ? 1 : c.value.aspectRatio,
      child: GestureDetector(
        child: buildVideoPlayer(),
        onTap: () {
          c.value.isPlaying ? c.pause() : c.play();
          setState(() {});
        },
      ),
    );
  }
}

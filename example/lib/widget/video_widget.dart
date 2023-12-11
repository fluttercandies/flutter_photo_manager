import 'dart:io';

import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:video_player/video_player.dart';

import '../util/log.dart';

class VideoWidget extends StatefulWidget {
  const VideoWidget({
    super.key,
    required this.entity,
    this.usingMediaUrl = true,
  });

  final AssetEntity entity;
  final bool usingMediaUrl;

  @override
  State<VideoWidget> createState() => _VideoWidgetState();
}

class _VideoWidgetState extends State<VideoWidget> {
  final Stopwatch _stopwatch = Stopwatch();
  VideoPlayerController? _controller;

  bool get isAudio => widget.entity.type == AssetType.audio;

  @override
  void initState() {
    super.initState();
    _stopwatch.start();
    if (widget.usingMediaUrl) {
      _initVideoWithMediaUrl();
    } else {
      _initVideoWithFile();
    }
  }

  @override
  void didUpdateWidget(VideoWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.entity == oldWidget.entity &&
        widget.usingMediaUrl == oldWidget.usingMediaUrl) {
      return;
    }
    _controller?.dispose();
    _controller = null;
    _stopwatch.start();
    if (widget.usingMediaUrl) {
      _initVideoWithMediaUrl();
    } else {
      _initVideoWithFile();
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _initVideoWithFile() {
    widget.entity.file.then((File? file) {
      _stopwatch.stop();
      Log.d('Elapsed time for `file`: ${_stopwatch.elapsed}');
      if (!mounted || file == null) {
        return;
      }
      _controller = VideoPlayerController.file(file)
        ..initialize()
        ..addListener(() => setState(() {}));
      setState(() {});
    });
  }

  void _initVideoWithMediaUrl() {
    widget.entity.getMediaUrl().then((String? url) {
      _stopwatch.stop();
      Log.d('Elapsed time for `getMediaUrl`: ${_stopwatch.elapsed}');
      if (!mounted || url == null) {
        return;
      }
      _controller = VideoPlayerController.networkUrl(Uri.parse(url))
        ..initialize()
        ..addListener(() => setState(() {}));
      setState(() {});
    });
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

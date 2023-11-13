///
/// [Author] Alex (https://github.com/AlexV525)
/// [Date] 2021/12/27 14:57
///
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';
import 'package:video_player/video_player.dart';

class LivePhotosWidget extends StatefulWidget {
  const LivePhotosWidget({
    Key? key,
    required this.entity,
    required this.useOrigin,
  }) : super(key: key);

  final AssetEntity entity;
  final bool useOrigin;

  @override
  State<LivePhotosWidget> createState() => _LivePhotosWidgetState();
}

class _LivePhotosWidgetState extends State<LivePhotosWidget> {
  VideoPlayerController? _controller;

  @override
  void initState() {
    super.initState();
    _initializeController();
  }

  Future<void> _initializeController() async {
    if (!await widget.entity.isLocallyAvailable()) {
      if (widget.useOrigin) {
        await widget.entity.originFileWithSubtype;
      } else {
        await widget.entity.fileWithSubtype;
      }
    }
    final String? url = await widget.entity.getMediaUrl();
    if (!mounted || url == null) {
      return;
    }
    _controller = VideoPlayerController.networkUrl(
      Uri.parse(url),
      videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
    )
      ..initialize()
      ..setVolume(0)
      ..addListener(() {
        if (mounted) {
          setState(() {});
        }
      });
    setState(() {});
  }

  void _play() {
    _controller?.play();
  }

  Future<void> _stop() async {
    await _controller?.pause();
    await _controller?.seekTo(Duration.zero);
  }

  Widget _buildImage(BuildContext context) {
    return AssetEntityImage(
      widget.entity,
      isOriginal: widget.useOrigin == true,
      fit: BoxFit.contain,
      loadingBuilder: (_, Widget child, ImageChunkEvent? progress) {
        if (progress != null) {
          final double? value;
          if (progress.expectedTotalBytes != null) {
            value =
                progress.cumulativeBytesLoaded / progress.expectedTotalBytes!;
          } else {
            value = null;
          }
          return Center(
            child: SizedBox.fromSize(
              size: const Size.square(30),
              child: CircularProgressIndicator(value: value),
            ),
          );
        }
        return child;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onLongPress: () => _play(),
      onLongPressEnd: (_) => _stop(),
      child: AspectRatio(
        aspectRatio: widget.entity.size.aspectRatio,
        child: Stack(
          children: <Widget>[
            if (_controller?.value.isInitialized == true)
              Positioned.fill(child: VideoPlayer(_controller!)),
            if (_controller != null)
              Positioned.fill(
                child: ValueListenableBuilder<VideoPlayerValue>(
                  valueListenable: _controller!,
                  builder: (_, VideoPlayerValue value, Widget? child) {
                    return AnimatedOpacity(
                      opacity: value.isPlaying ? 0 : 1,
                      duration: kThemeAnimationDuration,
                      child: child,
                    );
                  },
                  child: _buildImage(context),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

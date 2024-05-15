import 'package:photo_manager_example/main.dart' as example;
import 'package:photo_manager_example/widget/video_widget.dart';
import 'package:video_player/video_player.dart';

void main() {
  VideoPlayerControllerHelper.fileFd = (
    int fileFd, {
    Future<ClosedCaptionFile>? closedCaptionFile,
    VideoPlayerOptions? videoPlayerOptions,
    Map<String, String> httpHeaders = const <String, String>{},
  }) {
    return VideoPlayerController.fileFd(
      fileFd,
      closedCaptionFile: closedCaptionFile,
      videoPlayerOptions: videoPlayerOptions,
      httpHeaders: httpHeaders,
    );
  };
  example.main();
}

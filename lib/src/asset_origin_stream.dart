part of '../photo_manager.dart';

class AssetOriginStream {
  MyNotifier completionNotifier = MyNotifier();

  final MethodChannel _channel;

  AssetEntity assetEntity;

  StreamController<Uint8List> _controller = StreamController.broadcast();

  Stream<Uint8List> get stream => _controller.stream;

  var running = false;

  AssetOriginStream.fromMap(Map map)
      : _channel = MethodChannel(map['channelName']),
        running = map['running'] {
    _channel.setMethodCallHandler(this.onMethodCall);
  }

  Future onMethodCall(MethodCall call) async {
    switch (call.method) {
      case "onReceived":
        Map map = call.arguments;
        Uint8List data = map["data"];
        _controller.add(data);
        break;
      case "happenError":
        Map map = call.arguments;
        var error = map["error"];
        _controller.addError(error);
        running = false;
        break;
      case "completion":
        completionNotifier.notifyListeners();
        running = false;
        break;
    }
  }

  Future<void> start() async {
    await _channel.invokeMethod("start");
    running = true;
  }

  Future<void> stop() async {
    await _channel.invokeMethod("stop");
    running = false;
  }

  /// When not in use, this method must be called to release the native object.
  Future<void> release() async {
    running = false;
    await PhotoManager._releaseAssetStream(this);
    _controller.close();
  }
}

class MyNotifier extends ChangeNotifier {
  @override
  void notifyListeners() {
    super.notifyListeners();
  }
}

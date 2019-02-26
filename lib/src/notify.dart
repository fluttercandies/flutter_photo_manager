part of '../photo_manager.dart';

class _NotifyManager {
  static const MethodChannel _channel =
      const MethodChannel("photo_manager/notify");

  var notifyCallback = <VoidCallback>[];

  void addCallback(VoidCallback callback) => notifyCallback.add(callback);

  void removeCallback(VoidCallback callback) => notifyCallback.remove(callback);

  void startHandleNotify() {
    _channel.setMethodCallHandler(_notify);
  }

  void stopHandleNotify() {
    _channel.setMethodCallHandler(null);
  }

  Future<dynamic> _notify(MethodCall call) async {
    if (call.method == "change") {
      _onChange(call);
    }
    return 1;
  }

  Future<dynamic> _onChange(MethodCall call) async {
    notifyCallback.forEach((callback) => callback?.call());
  }
}

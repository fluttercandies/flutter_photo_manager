part of '../photo_manager.dart';

/// manage photo changes
///
/// 当相册发生变化时, 通知
class _NotifyManager {
  static const MethodChannel _channel =
      const MethodChannel("top.kikt/photo_manager/notify");

  /// callbacks
  var notifyCallback = <VoidCallback>[];

  /// add callback
  void addCallback(VoidCallback callback) => notifyCallback.add(callback);

  /// remove callback
  void removeCallback(VoidCallback callback) => notifyCallback.remove(callback);

  /// start handle notify
  void startHandleNotify() {
    _channel.setMethodCallHandler(_notify);
  }

  /// stop handle notify
  void stopHandleNotify() {
    _channel.setMethodCallHandler(null);
  }

  Future<dynamic> _notify(MethodCall call) async {
    print("call.method = ${call.method}");
    if (call.method == "change") {
      _onChange(call);
    }
    return 1;
  }

  Future<dynamic> _onChange(MethodCall call) async {
    notifyCallback.forEach((callback) => callback?.call());
  }
}

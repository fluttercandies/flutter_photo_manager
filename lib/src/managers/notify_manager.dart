import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../internal/plugin.dart';

/// manage photo changes
///
/// 当相册发生变化时, 通知
class NotifyManager {
  static const MethodChannel _channel = MethodChannel(
    "top.kikt/photo_manager/notify",
  );

  final StreamController<bool> _controller = StreamController.broadcast();

  /// When the notification status change, the listen of stream will be called.
  Stream<bool> get notifyStream => _controller.stream;

  /// callbacks
  var notifyCallback = <ValueChanged<MethodCall>>[];

  /// add callback
  void addCallback(ValueChanged<MethodCall> callback) =>
      notifyCallback.add(callback);

  /// remove callback
  void removeCallback(ValueChanged<MethodCall> callback) =>
      notifyCallback.remove(callback);

  /// start handle notify
  void startHandleNotify() {
    _channel.setMethodCallHandler(_notify);
    plugin.notifyChange(start: true);
    _controller.add(true);
  }

  /// stop handle notify
  void stopHandleNotify() {
    plugin.notifyChange(start: false);
    _channel.setMethodCallHandler(null);
    _controller.add(false);
  }

  Future<dynamic> _notify(MethodCall call) async {
    if (call.method == "change") {
      print(call.arguments);
      _onChange(call);
    } else if (call.method == "setAndroidQExperimental") {
      // PhotoManager.androidQExperimental = call.arguments["open"];
    }
    return 1;
  }

  Future<dynamic> _onChange(MethodCall methodCall) async {
    notifyCallback.toList().forEach((callback) => callback.call(methodCall));
  }
}

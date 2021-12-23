import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../internal/constants.dart';
import '../internal/plugin.dart';

/// The notify manager when assets changed.
class NotifyManager {
  static const MethodChannel _channel = MethodChannel(
    '${PMConstants.channelPrefix}/notify',
  );

  Stream<bool> get notifyStream => _controller.stream;
  final StreamController<bool> _controller = StreamController<bool>.broadcast();

  final List<ValueChanged<MethodCall>> notifyCallback =
      <ValueChanged<MethodCall>>[];

  /// Add a callback.
  void addCallback(ValueChanged<MethodCall> c) => notifyCallback.add(c);

  /// Remove the callback
  void removeCallback(ValueChanged<MethodCall> c) => notifyCallback.remove(c);

  /// Start to handle notify.
  void startHandleNotify() {
    _channel.setMethodCallHandler(_notify);
    _controller.add(true);
    plugin.notifyChange(start: true);
  }

  /// Stop to handle notify.
  void stopHandleNotify() {
    plugin.notifyChange(start: false);
    _controller.add(false);
    _channel.setMethodCallHandler(null);
  }

  Future<dynamic> _notify(MethodCall call) async {
    if (call.method == 'change') {
      _onChange(call);
    } else if (call.method == 'setAndroidQExperimental') {
      // PhotoManager.androidQExperimental = call.arguments["open"];
    }
    return 1;
  }

  Future<dynamic> _onChange(MethodCall m) async {
    notifyCallback.toList().forEach((ValueChanged<MethodCall> c) => c.call(m));
  }

  @override
  String toString() => '$runtimeType(callbacks: ${notifyCallback.length})';
}

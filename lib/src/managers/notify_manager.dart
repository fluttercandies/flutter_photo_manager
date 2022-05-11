// Copyright 2018 The FlutterCandies author. All rights reserved.
// Use of this source code is governed by an Apache license that can be found
// in the LICENSE file.

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

  final List<ValueChanged<MethodCall>> _notifyCallback =
      <ValueChanged<MethodCall>>[];

  /// {@template photo_manager.NotifyManager.addChangeCallback}
  /// Add a callback for assets changing.
  /// {@endtemplate}
  void addChangeCallback(ValueChanged<MethodCall> c) => _notifyCallback.add(c);

  /// {@template photo_manager.NotifyManager.removeChangeCallback}
  /// Remove the callback for assets changing.
  /// {@endtemplate}
  void removeChangeCallback(ValueChanged<MethodCall> c) =>
      _notifyCallback.remove(c);

  /// {@template photo_manager.NotifyManager.startChangeNotify}
  /// Enable notifications for assets changing.
  ///
  /// Make sure you've added a callback for changes.
  /// {@endtemplate}
  void startChangeNotify() {
    _channel.setMethodCallHandler(_notify);
    _controller.add(true);
    plugin.notifyChange(start: true);
  }

  /// {@template photo_manager.NotifyManager.stopChangeNotify}
  /// Disable notifications for assets changing.
  ///
  /// Remember to remove callbacks for changes.
  /// {@endtemplate}
  void stopChangeNotify() {
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
    _notifyCallback.toList().forEach((ValueChanged<MethodCall> c) => c.call(m));
  }

  @override
  String toString() => '$runtimeType(callbacks: ${_notifyCallback.length})';
}

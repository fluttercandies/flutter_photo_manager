// Copyright 2018 The FlutterCandies author. All rights reserved.
// Use of this source code is governed by an Apache license that can be found
// in the LICENSE file.

import 'dart:async';

import 'package:flutter/foundation.dart' as foundation;
import 'package:flutter/services.dart';

import '../internal/constants.dart';
import '../internal/plugin.dart';

/// The notify manager when assets changed.
class NotifyManager {
  static const _channel = MethodChannel('${PMConstants.channelPrefix}/notify');

  Stream<bool> get notifyStream => _controller.stream;
  final _controller = StreamController<bool>.broadcast();

  final _notifyCallback = <foundation.ValueChanged<MethodCall>>[];

  /// {@template photo_manager.NotifyManager.addChangeCallback}
  /// Add a callback for assets changing.
  /// {@endtemplate}
  void addChangeCallback(foundation.ValueChanged<MethodCall> c) =>
      _notifyCallback.add(c);

  /// {@template photo_manager.NotifyManager.removeChangeCallback}
  /// Remove the callback for assets changing.
  /// {@endtemplate}
  void removeChangeCallback(foundation.ValueChanged<MethodCall> c) =>
      _notifyCallback.remove(c);

  /// {@template photo_manager.NotifyManager.startChangeNotify}
  /// Enable notifications for assets changing.
  ///
  /// Make sure you've added a callback for changes.
  /// {@endtemplate}
  Future<bool> startChangeNotify() async {
    final bool result = await plugin.notifyChange(start: true);
    if (result) {
      _channel.setMethodCallHandler(_notify);
      _controller.add(true);
    }
    return result;
  }

  /// {@template photo_manager.NotifyManager.stopChangeNotify}
  /// Disable notifications for assets changing.
  ///
  /// Remember to remove callbacks for changes.
  /// {@endtemplate}
  Future<bool> stopChangeNotify() async {
    final bool result = await plugin.notifyChange(start: false);
    if (result) {
      _controller.add(false);
      _channel.setMethodCallHandler(null);
    }
    return result;
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
    _notifyCallback.toList().forEach((c) => c.call(m));
  }

  @override
  String toString() => '$runtimeType(callbacks: ${_notifyCallback.length})';
}

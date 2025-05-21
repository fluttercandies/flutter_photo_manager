// Copyright 2018 The FlutterCandies author. All rights reserved.
// Use of this source code is governed by an Apache license that can be found
// in the LICENSE file.

import 'dart:async';

import 'package:flutter/foundation.dart' as foundation;
import 'package:flutter/services.dart';

import '../internal/constants.dart';
import '../internal/plugin.dart';

/// The manager for receiving notifications when assets change.
///
/// This class provides methods for starting and stopping asset change notifications, as well as adding and removing callbacks to be executed upon changes. It also exposes a [Stream] of boolean values that can be used to track whether notifications are currently enabled or disabled.
class NotifyManager {
  /// The method channel used to communicate with the native platform.
  static const _channel = MethodChannel('${PMConstants.channelPrefix}/notify');

  /// Returns a [Stream] that emits a boolean value indicating whether asset change notifications are currently enabled.
  Stream<bool> get notifyStream => _controller.stream;

  /// The stream controller used to manage the [notifyStream].
  final _controller = StreamController<bool>.broadcast();

  /// The list of callback functions to be executed upon asset changes.
  final _notifyCallback = <foundation.ValueChanged<MethodCall>>[];

  /// {@template photo_manager.NotifyManager.addChangeCallback}
  /// Adds a callback function to be executed upon asset changes.
  ///
  /// * [callback]: A required parameter. The function to be executed upon asset changes.
  /// {@endtemplate}
  void addChangeCallback(foundation.ValueChanged<MethodCall> callback) =>
      _notifyCallback.add(callback);

  /// {@template photo_manager.NotifyManager.removeChangeCallback}
  /// Removes a callback function from the list to be executed upon asset changes.
  ///
  /// * [callback]: A required parameter. The function to remove.
  /// {@endtemplate}
  void removeChangeCallback(foundation.ValueChanged<MethodCall> callback) =>
      _notifyCallback.remove(callback);

  /// {@template photo_manager.NotifyManager.startChangeNotify}
  /// Enables asset change notifications.
  ///
  /// Make sure you've added at least one callback function for changes.
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

  /// Disables asset change notifications.
  ///
  /// Remember to remove all callback functions for changes.
  /// {@endtemplate}
  Future<bool> stopChangeNotify() async {
    final bool result = await plugin.notifyChange(start: false);
    if (result) {
      _controller.add(false);
      _channel.setMethodCallHandler(null);
    }
    return result;
  }

  /// The handler function for incoming method calls from the native platform.
  Future<dynamic> _notify(MethodCall call) async {
    if (call.method == 'change') {
      _onChange(call);
    } else if (call.method == 'setAndroidQExperimental') {
      // PhotoManager.androidQExperimental = call.arguments["open"];
    }
    return 1;
  }

  /// Executes all registered callback functions upon receipt of an asset change notification.
  Future<dynamic> _onChange(MethodCall m) async {
    _notifyCallback.toList().forEach((c) => c.call(m));
  }

  @override
  String toString() => '$runtimeType(callbacks: ${_notifyCallback.length})';
}

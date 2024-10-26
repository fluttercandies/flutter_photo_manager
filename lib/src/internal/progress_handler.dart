// Copyright 2018 The FlutterCandies author. All rights reserved.
// Use of this source code is governed by an Apache license that can be found
// in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'constants.dart';
import 'enums.dart';

/// {@template photo_manager.PMProgressHandler}
/// Manages the progress of asset downloads from cloud storage services,
/// such as iCloud.
/// {@endtemplate}
class PMProgressHandler {
  /// Creates a new [PMProgressHandler] object.
  ///
  /// Throws an error if used on a platform other than iOS or macOS.
  PMProgressHandler() : _channelIndex = _incrementalIndex {
    assert(
      Platform.isIOS || Platform.isMacOS,
      '$runtimeType should only be used on iOS or macOS.',
    );
    _channel = OptionalMethodChannel(
      '${PMConstants.channelPrefix}/progress/$_channelIndex',
    );
    _channel.setMethodCallHandler(_onProgress);
    _incrementalIndex++;
  }

  /// An incremental index that increases each time this class is instantiated.
  static int _incrementalIndex = 0;

  /// The channel index associated with this instance.
  int get channelIndex => _channelIndex;
  final int _channelIndex;

  late final OptionalMethodChannel _channel;

  final StreamController<PMProgressState> _controller =
      StreamController<PMProgressState>.broadcast();

  /// A stream that provides information about the download status and progress of the asset being downloaded.
  Stream<PMProgressState> get stream => _controller.stream;

  Future<dynamic> _onProgress(MethodCall call) async {
    final Map<dynamic, dynamic>? arguments =
        call.arguments as Map<dynamic, dynamic>?;
    switch (call.method) {
      case 'notifyProgress':
        final double progress = arguments!['progress'] as double;
        final int stateIndex = arguments['state'] as int;
        final PMRequestState state = PMRequestState.values[stateIndex];
        _controller.add(PMProgressState(progress, state));
        break;
    }
    return;
  }
}

/// A state class that contains [progress] of the current downloading
/// and [state] to indicate the request state of the asset.
@immutable
class PMProgressState {
  /// Creates a new [PMProgressState] object with the given progress and state values.
  const PMProgressState(this.progress, this.state);

  /// A value between 0.0 and 1.0 representing the progress of the download.
  final double progress;

  /// {@macro photo_manager.PMRequestState}
  ///
  /// See also:
  ///
  /// * [PMRequestState], which defines possible states for an asset download request.
  final PMRequestState state;

  @override
  bool operator ==(Object other) {
    return other is PMProgressState &&
        other.state == state &&
        other.progress == progress;
  }

  @override
  int get hashCode => progress.hashCode ^ state.hashCode;

  @override
  String toString() => '$runtimeType($state, $progress)';
}

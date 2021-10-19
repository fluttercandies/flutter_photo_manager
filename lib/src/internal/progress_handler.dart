import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'constants.dart';
import 'enums.dart';

/// Handling assets loading progress when they need to download from cloud.
/// Typically for iCloud assets downloading.
class PMProgressHandler {
  PMProgressHandler() : _channelIndex = _incrementalIndex {
    assert(
      Platform.isIOS || Platform.isMacOS,
      '$runtimeType should only used on iOS or macOS.',
    );
    _channel = OptionalMethodChannel(
      '${PMConstants.channelPrefix}/progress/$_channelIndex',
    );
    _channel.setMethodCallHandler(_onProgress);
    _incrementalIndex++;
  }

  /// Increamental index that increase for each use.
  static int _incrementalIndex = 0;

  int get channelIndex => _channelIndex;
  final int _channelIndex;

  late final OptionalMethodChannel _channel;

  StreamController<PMProgressState> _controller = StreamController.broadcast();

  /// Obtain the download progress and status of the downloading asset
  /// from the stream.
  Stream<PMProgressState> get stream => _controller.stream;

  Future<dynamic> _onProgress(MethodCall call) async {
    switch (call.method) {
      case 'notifyProgress':
        final double progress = call.arguments['progress'];
        final int stateIndex = call.arguments['state'];
        final state = PMRequestState.values[stateIndex];
        _controller.add(PMProgressState(progress, state));
        break;
    }
    return;
  }
}

/// A state class that contains [progress] of the current downloading
/// and [state] to indicate the request state of the asset.
class PMProgressState {
  const PMProgressState(this.progress, this.state);

  /// From 0.0 to 1.0.
  final double progress;

  /// {@macro photo_manager.PMRequestState}
  final PMRequestState state;

  @override
  bool operator ==(Object other) {
    return other is PMProgressState &&
        other.state == state &&
        other.progress == progress;
  }

  @override
  int get hashCode => hashValues(progress, state);

  @override
  String toString() => '$runtimeType($state, $progress)';
}

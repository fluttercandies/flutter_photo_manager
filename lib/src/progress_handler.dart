part of '../photo_manager.dart';

/// Only works in iOS.
class PMProgressHandler {
  static int _index = 0;

  StreamController<PMProgresState> _controller = StreamController.broadcast();

  Stream<PMProgresState> get stream => _controller.stream;

  int channelIndex = 0;

  PMProgressHandler() {
    final index = _index;
    _index = _index + 1;
    channelIndex = index;
    _channel = OptionalMethodChannel('top.kikt/photo_manager/progress/$index');
    _channel.setMethodCallHandler(this._onProgress);
  }

  OptionalMethodChannel _channel;

  Future<dynamic> _onProgress(MethodCall call) async {
    switch (call.method) {
      case 'notifyProgress':
        final double progress = call.arguments['progress'];
        final int stateIndex = call.arguments['state'];
        final state = PMRequestState.values[stateIndex];
        _controller.add(PMProgresState(progress, state));
        break;
    }
    return;
  }
}

class PMProgresState {
  final double progress;
  final PMRequestState state;

  PMProgresState(this.progress, this.state);
}

enum PMRequestState {
  prepare,
  loading,
  sucesss,
  failed,
}

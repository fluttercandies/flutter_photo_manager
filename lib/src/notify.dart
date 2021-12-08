part of '../photo_manager.dart';

typedef NotifyChangeInfoCallback = void Function(NotifyChangeInfo info);

/// manage photo changes
///
/// 当相册发生变化时, 通知
class _NotifyManager {
  static const MethodChannel _channel =
      const MethodChannel("top.kikt/photo_manager/notify");

  StreamController<bool> _controller = StreamController.broadcast();

  /// When the notification status change, the listen of stream will be called.
  Stream<bool> get notifyStream => _controller.stream;

  /// callbacks
  final _notifyCallbacks = <NotifyChangeInfoCallback>[];

  /// add callback
  void addCallback(NotifyChangeInfoCallback callback) {
    _notifyCallbacks.add(callback);
  }

  /// remove callback
  void removeCallback(NotifyChangeInfoCallback callback) {
    _notifyCallbacks.remove(callback);
  }

  /// start handle notify
  void startHandleNotify() {
    _channel.setMethodCallHandler(_notify);
    _plugin.notifyChange(start: true);
    _controller.add(true);
  }

  /// stop handle notify
  void stopHandleNotify() {
    _plugin.notifyChange(start: false);
    _channel.setMethodCallHandler(null);
    _controller.add(false);
  }

  Future<dynamic> _notify(MethodCall call) async {
    if (call.method == "change") {
      final info =
          NotifyChangeInfo.fromJson(call.arguments as Map<String, dynamic>);
      debugPrint(info.toString());
      _onChange(info);
    } else if (call.method == "setAndroidQExperimental") {
      // PhotoManager.androidQExperimental = call.arguments["open"];
    }
    return 1;
  }

  void _onChange(NotifyChangeInfo info) {
    _notifyCallbacks.toList().forEach((callback) => callback.call(info));
  }
}

class NotifyChangeInfo {
  final String platform;
  final Uri uri;
  final NotifyChangeType changeType;
  final AssetType mediaType;

  const NotifyChangeInfo.raw({
    required this.platform,
    required this.uri,
    required this.changeType,
    required this.mediaType,
  });

  factory NotifyChangeInfo.fromJson(Map<String, dynamic> map) {
    return NotifyChangeInfo.raw(
      platform: map['platform'],
      uri: Uri.parse(map['uri']),
      changeType: _parseNotifyChangeType(map['type']),
      mediaType: _parseTypeFromId(map['mediaType']),
    );
  }

  static AssetType _parseTypeFromId(int type) {
    switch (type) {
      case 1:
        return AssetType.image;
      case 2:
        return AssetType.video;
      case 3:
        return AssetType.audio;
      default:
        return AssetType.other;
    }
  }

  static NotifyChangeType _parseNotifyChangeType(String type) {
    switch (type) {
      case 'delete':
        return NotifyChangeType.delete;
      case 'insert':
        return NotifyChangeType.insert;
      case 'update':
        return NotifyChangeType.update;
      default:
        throw UnimplementedError('$type is not present in NotifyChangeType');
    }
  }

  @override
  String toString() {
    return 'NotifyChangeInfo(platform: $platform, uri: $uri, changeType: $changeType, mediaType: $mediaType)';
  }
}

enum NotifyChangeType { delete, insert, update }

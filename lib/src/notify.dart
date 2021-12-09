part of '../photo_manager.dart';

typedef NotifyChangeInfoCallback = void Function(NotifyChangeInfo info);

/// Manage photo changes. Basic usage:
///
/// ```dart
/// final manager = NotifyManager();
/// manager.onNotify.listen((info) {
///   print(info);
/// });
/// ```
///
/// You can also use [PhotoManager]'s abstraction of this:
///
/// ```dart
/// PhotoManager.onChangeNotify.listen((info) {
///   print(info);
/// });
/// ```
///
/// 当相册发生变化时, 通知
class NotifyManager {
  static const _channel = MethodChannel("top.kikt/photo_manager/notify");

  final _controller = StreamController<NotifyChangeInfo>.broadcast();

  /// {@template notify.onNotify}
  /// When the notification status change, the listen of stream will be called.
  /// {@end-template}
  Stream<NotifyChangeInfo> get onNotify => _controller.stream;

  bool _active = false;

  /// Whether the listening is active or not. It's active when [onNotify] has
  /// any listeners.
  bool get active => _active;

  NotifyManager() {
    _channel.setMethodCallHandler(_notify);

    _controller.onListen = () {
      if (!_active) {
        _plugin.notifyChange(start: true);
        _active = true;
      }
    };

    _controller.onCancel = () {
      if (_controller.hasListener) {
        _plugin.notifyChange(start: false);
        _active = false;
      }
    };
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
    _controller.add(info);
  }

  /// Dispose this instance to free up resources.
  ///
  /// Note that this can't be used once disposed
  void dispose() {
    _controller.close();
    _plugin.notifyChange(start: false);
    _channel.setMethodCallHandler(null);
    _active = false;
  }
}

class NotifyChangeInfo {
  /// The platform from where this comes from.
  ///
  /// It can be android, iOS or macOS
  final String platform;

  /// The media path
  final Uri uri;

  /// The type of the change
  final NotifyChangeType changeType;

  /// The type of the media
  final AssetType mediaType;

  const NotifyChangeInfo._raw({
    required this.platform,
    required this.uri,
    required this.changeType,
    required this.mediaType,
  });

  factory NotifyChangeInfo.fromJson(Map<String, dynamic> map) {
    return NotifyChangeInfo._raw(
      platform: map['platform'] ??
          () {
            if (Platform.isAndroid) return 'android';
            if (Platform.isIOS) return 'iOS';
            if (Platform.isMacOS) return 'macOS';
          }(),
      uri: Uri.parse(map['uri'] ?? ''),
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

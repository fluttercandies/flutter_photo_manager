import 'dart:developer' as _dev;

import 'package:flutter/foundation.dart';

typedef LogFunction = void Function(
  Object message,
  String tag,
  StackTrace stackTrace, {
  bool? isError,
});

class Log {
  const Log._();

  static const String _TAG = 'PhotoManager';

  static final ObserverList<LogFunction> _listeners =
      ObserverList<LogFunction>();

  static void addListener(LogFunction listener) {
    _listeners.add(listener);
  }

  static void removeListener(LogFunction listener) {
    _listeners.remove(listener);
  }

  static void i(
    Object? message, {
    String tag = _TAG,
    StackTrace? stackTrace,
    bool report = false,
  }) {
    _printLog(
      message,
      '$tag ❕',
      stackTrace,
      report: report,
    );
  }

  static void d(
    Object? message, {
    String tag = _TAG,
    StackTrace? stackTrace,
    bool report = false,
  }) {
    _printLog(
      message,
      '$tag 📣',
      stackTrace,
      report: report,
    );
  }

  static void w(
    Object? message, {
    String tag = _TAG,
    StackTrace? stackTrace,
    bool report = false,
  }) {
    _printLog(
      message,
      '$tag ⚠️',
      stackTrace,
      report: report,
    );
  }

  static void e(
    Object? message, {
    String tag = _TAG,
    StackTrace? stackTrace,
    bool report = true,
  }) {
    _printLog(
      message,
      '$tag ❌',
      stackTrace,
      isError: true,
      report: report,
    );
  }

  static void json(
    Object? message, {
    String tag = _TAG,
    StackTrace? stackTrace,
    bool report = false,
  }) {
    _printLog(message, '$tag 💠', stackTrace, report: report);
  }

  static void _printLog(
    Object? message,
    String tag,
    StackTrace? stackTrace, {
    bool isError = false,
    bool report = false,
  }) {
    final DateTime _time = DateTime.now();
    final String _timeString = _time.toIso8601String();
    if (isError) {
      if (kDebugMode) {
        FlutterError.presentError(
          FlutterErrorDetails(
            exception: message ?? 'NULL',
            stack: stackTrace,
            library: tag == _TAG ? 'Framework' : tag,
          ),
        );
      } else {
        _dev.log(
          '$_timeString - An error occurred.',
          time: _time,
          name: tag,
          error: message,
          stackTrace: stackTrace,
        );
      }
    } else {
      _dev.log(
        '$_timeString - $message',
        time: _time,
        name: tag,
        stackTrace: stackTrace,
      );
    }
  }
}

import 'package:flutter/foundation.dart';

import '../internal/plugin.dart';

/// The cancel token is used to cancel the request.
class PMCancelToken {
  PMCancelToken({this.debugLabel}) : index = _index++;

  static int _index = 0;

  final int index;
  final String? debugLabel;

  /// The key of cancel token, usually to use by
  /// [PhotoManagerPlugin.cancelRequest].
  /// User don't need to use this.
  @nonVirtual
  String get key => _index.toString();

  /// Cancel the request.
  Future<void> cancelRequest() => plugin.cancelRequest(this);

  @override
  String toString() => 'PMCancelToken($key)';
}

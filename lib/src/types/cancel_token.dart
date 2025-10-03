import 'package:flutter/foundation.dart';

import '../internal/plugin.dart';

/// The cancel token is used to cancel the request.
class PMCancelToken {
  PMCancelToken({this.debugLabel}) : index = _index++;

  static int _index = 0;

  final int index;
  final String? debugLabel;

  /// The key of cancel token, typically used in
  /// [PhotoManagerPlugin.cancelRequest].
  ///
  /// This field is useless to the user end.
  @nonVirtual
  String get key => index.toString();

  /// Cancel the request.
  Future<void> cancelRequest() => plugin.cancelRequest(this);

  @override
  String toString() =>
      'PMCancelToken($key${debugLabel != null ? ', $debugLabel' : ''})';
}

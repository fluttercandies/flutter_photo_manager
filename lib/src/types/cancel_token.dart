import '../internal/plugin.dart';

/// The cancel token is used to cancel the request.
class PMCancelToken {
  PMCancelToken({this.debugLabel}) : index = getIndex();

  static int _index = 0;

  static int getIndex() {
    final res = _index;
    _index++;
    return res;
  }

  final String? debugLabel;
  final int index;

  /// The key of cancel token, usually to use by [PhotoManagerPlugin.cancelRequest].
  /// User don't need to use this.
  String get key => _index.toString();

  /// Cancel the request.
  Future<void> cancelRequest() async {
    await plugin.cancelRequest(this);
  }
}

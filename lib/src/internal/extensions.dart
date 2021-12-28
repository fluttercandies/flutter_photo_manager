import 'enums.dart';

extension PermissionStateExt on PermissionState {
  /// Whether authorized or not.
  bool get isAuth {
    return this == PermissionState.authorized;
  }
}

import 'enums.dart';

extension PermissionStateExt on PermissionState {
  /// Whether authorized or not.
  bool get isAuth {
    return this == PermissionState.authorized;
  }
}

extension IosAccessLevelExt on IosAccessLevel {
  int getValue() {
    switch (this) {
      case IosAccessLevel.addOnly:
        return 1;
      case IosAccessLevel.readWrite:
        return 2;
    }
  }
}

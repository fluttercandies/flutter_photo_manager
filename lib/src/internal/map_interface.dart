// Copyright 2018 The FlutterCandies author. All rights reserved.
// Use of this source code is governed by an Apache license that can be found
// in the LICENSE file.

/// Contains an abstract method toMap to indicate that it can be converted into a Map object
mixin IMapMixin {
  /// Convert current object to a map.
  ///
  /// Usually for transfer to MethodChannel.
  Map<String, dynamic> toMap();
}

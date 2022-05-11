// Copyright 2018 The FlutterCandies author. All rights reserved.
// Use of this source code is governed by an Apache license that can be found
// in the LICENSE file.

/// The main library that contains all functions integrating with photo library.
///
/// To use, import `package:photo_manager/photo_manager.dart`.
library photo_manager;

export 'src/filter/filter_option_group.dart';
export 'src/filter/filter_options.dart';

export 'src/internal/enums.dart';
export 'src/internal/extensions.dart';
export 'src/internal/image_provider.dart';
export 'src/internal/plugin.dart' show PhotoManagerPlugin;
export 'src/internal/progress_handler.dart';

export 'src/managers/caching_manager.dart';
export 'src/managers/notify_manager.dart';
export 'src/managers/photo_manager.dart';

export 'src/types/entity.dart';
export 'src/types/thumbnail.dart';
export 'src/types/types.dart';

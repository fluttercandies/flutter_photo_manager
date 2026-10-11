// Copyright 2018 The FlutterCandies author. All rights reserved.
// Use of this source code is governed by an Apache license that can be found
// in the LICENSE file.

import 'custom/custom_columns.dart';
import 'custom/custom_filter.dart';
import 'custom/order_by_item.dart';

/// The type of the filter.
enum BaseFilterType {
  /// The classical filter.
  classical,

  /// The custom filter.
  custom,
}

/// The extension of [BaseFilterType].
extension BaseFilterTypeExtension on BaseFilterType {
  /// The value of the [BaseFilterType].
  int get value {
    switch (this) {
      case BaseFilterType.classical:
        return 0;
      case BaseFilterType.custom:
        return 1;
    }
  }
}

/// The base class of all the filters.
///
/// See also:
abstract class PMFilter {
  /// Construct a default filter.
  PMFilter();

  /// Construct a default filter.
  factory PMFilter.defaultValue({
    bool containsPathModified = false,
    bool includeHiddenAssets = false,
  }) {
    return CustomFilter.sql(
      where: '',
      orderBy: [
        OrderByItem.named(
          column: CustomColumns.base.createDate,
          isAsc: false,
        ),
      ],
    );
  }

  /// Whether the [AssetPathEntity]s will return with modified time.
  ///
  /// This option is performance-consuming. Use with caution.
  ///
  /// See also:
  ///  * [AssetPathEntity.lastModified].
  bool containsPathModified = false;

  /// Whether to include hidden assets in the results.
  ///
  /// This option only takes effect on iOS.
  /// Beginning with iOS 16, users can require authentication to view the
  /// hidden album, and the user setting is true by default. When true,
  /// the system doesn’t return hidden assets even if the option is true.
  ///
  /// See also:
  ///  * [PHFetchOptions.includeHiddenAssets](https://developer.apple.com/documentation/photos/phfetchoptions/includehiddenassets).
  bool includeHiddenAssets = false;

  /// [checkIfExists] controls whether assets whose file no longer exists are
  /// excluded from the result. Defaults to `true`. Set it to `false` to skip
  /// the per-asset file check, which is much faster for large ranges but may
  /// include assets that were deleted outside of MediaStore.
  ///  * Android: Each asset is checked with `File.exists()` when `true`.
  ///  * iOS/macOS: Ignored. PhotoKit never returns missing assets.
  ///  * OpenHarmony: Ignored.
  ///
  /// Only [AssetPathEntity.getAssetListPaged] and
  /// [AssetPathEntity.getAssetListRange] read this flag.
  /// [PhotoManager.getAssetListRange] and [PhotoManager.getAssetListPaged]
  /// never check for missing files on Android.
  bool checkIfExists = true;

  /// The type of the filter.
  BaseFilterType get type;

  /// The child map of the filter.
  ///
  /// The subclass should override this method to make params.
  Map<String, dynamic> childMap();

  /// The method only supports for [FilterOptionGroup].
  PMFilter updateDateToNow();

  /// Convert the filter to a map for channel.
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'type': type.value,
      'child': {
        ...childMap(),
        ..._paramMap(),
      },
    };
  }

  Map<String, dynamic> _paramMap() {
    return <String, dynamic>{
      'containsPathModified': containsPathModified,
      'includeHiddenAssets': includeHiddenAssets,
      'checkIfExists': checkIfExists,
    };
  }
}

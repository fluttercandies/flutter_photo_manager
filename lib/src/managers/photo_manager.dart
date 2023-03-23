// Copyright 2018 The FlutterCandies author. All rights reserved.
// Use of this source code is governed by an Apache license that can be found
// in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../filter/base_filter.dart';
import '../internal/editor.dart';
import '../internal/enums.dart';
import '../internal/plugin.dart' as base;
import '../types/entity.dart';
import '../types/types.dart';
import 'notify_manager.dart';

/// The core manager of this plugin.
/// Use various methods in this class to access & manage assets.
class PhotoManager {
  @visibleForTesting
  PhotoManager.withPlugin([base.PhotoManagerPlugin? photoManagerPlugin]) {
    if (photoManagerPlugin != null && photoManagerPlugin != base.plugin) {
      base.plugin = photoManagerPlugin;
    }
  }

  /// Editor instance for editing assets.
  static final Editor editor = Editor();

  /// Notify manager instance for managing photo changes.
  static final NotifyManager _notifyManager = NotifyManager();

  /// The core class plugin that handles all methods in channels.
  static base.PhotoManagerPlugin get plugin => base.plugin;

  /// ### Android (AndroidManifest.xml)
  ///  * READ_EXTERNAL_STORAGE (REQUIRED)
  ///  * WRITE_EXTERNAL_STORAGE
  ///  * ACCESS_MEDIA_LOCATION
  ///
  /// ### iOS (Info.plist)
  ///  * NSPhotoLibraryUsageDescription
  ///  * NSPhotoLibraryAddUsageDescription
  ///
  /// ### macOS (Debug/Release.entitlements)
  ///  * com.apple.security.assets.movies.read-write
  ///  * com.apple.security.assets.music.read-write
  ///
  /// See also:
  ///  * [PermissionState] which defines the permission state
  ///    of the current application.
  static Future<PermissionState> requestPermissionExtend({
    PermissionRequestOption requestOption = const PermissionRequestOption(),
  }) {
    return plugin.requestPermissionExtend(requestOption);
  }

  /// Prompts the limited assets selection modal on iOS.
  ///
  /// This method only supports from iOS 14.0, and will behave differently on
  /// iOS 14 and 15:
  ///  * iOS 14: Immediately complete the future call since there is no complete
  ///    handler with the API on iOS 14.
  ///  * iOS 15: The Future will be completed after the modal was dismissed.
  ///
  /// See the documents from Apple:
  ///  * iOS 14: https://developer.apple.com/documentation/photokit/phphotolibrary/3616113-presentlimitedlibrarypickerfromv/
  ///  * iOS 15: https://developer.apple.com/documentation/photokit/phphotolibrary/3752108-presentlimitedlibrarypickerfromv/
  static Future<void> presentLimited() => plugin.presentLimited();

  /// Obtain albums/folders list with couple filter options.
  ///
  /// To obtain albums list that contains the root album
  /// (generally named 'Recent'), set [hasAll] to true.
  ///
  /// To obtain only the root album in the list, set [onlyAll] to true.
  ///
  /// To request multiple assets type, set [type] accordingly.
  ///
  /// To filter assets with provided options, use [filterOption].
  static Future<List<AssetPathEntity>> getAssetPathList({
    bool hasAll = true,
    bool onlyAll = false,
    RequestType type = RequestType.common,
    PMFilter? filterOption,
  }) async {
    return plugin.getAssetPathList(
      hasAll: hasAll,
      onlyAll: onlyAll,
      type: type,
      filterOption: filterOption,
    );
  }

  /// Whether the plugin should produce logs during the running process.
  static Future<void> setLog(bool isLog) => plugin.setLog(isLog);

  /// Whether to ignore all runtime permissions check.
  ///
  /// ### Common scenarios on Android
  /// Service and other background process are common use cases ignore checks.
  /// Because permissions checks required a valid `Activity`.
  /// Be aware that asset deletions above Android 10 required an `Activity`.
  static Future<void> setIgnorePermissionCheck(bool ignore) {
    return plugin.ignorePermissionCheck(ignore);
  }

  /// Open the system settings page of the current app.
  static Future<void> openSetting() => plugin.openSetting();

  /// Release native caches, there are no common use case for this method,
  /// so this method is not recommended.
  ///
  /// The main purpose is to help with issues when the memory usage
  /// is too large with too many pictures.
  ///
  /// After this method is called, all existing [AssetEntity] and
  /// [AssetPathEntity] are not able to call further methods.
  /// In order to obtain new instances and their data,
  /// call the [getAssetPathList] to start again.
  ///
  /// Make sure callers of this method have `await`ed properly.
  static Future<void> releaseCache() => plugin.releaseCache();

  /// {@macro photo_manager.NotifyManager.addChangeCallback}
  static void addChangeCallback(ValueChanged<MethodCall> callback) =>
      _notifyManager.addChangeCallback(callback);

  /// {@macro photo_manager.NotifyManager.removeChangeCallback}
  static void removeChangeCallback(ValueChanged<MethodCall> callback) =>
      _notifyManager.removeChangeCallback(callback);

  /// Whether assets change event should be notified.
  static bool get notifyingOfChange => _notifyingOfChange;
  static bool _notifyingOfChange = false;

  /// The notify enable flag in stream.
  static Stream<bool> get notifyStream => _notifyManager.notifyStream;

  /// {@macro photo_manager.NotifyManager.startChangeNotify}
  static Future<void> startChangeNotify() async {
    if (await _notifyManager.startChangeNotify()) {
      _notifyingOfChange = true;
    }
  }

  /// {@macro photo_manager.NotifyManager.stopChangeNotify}
  static Future<void> stopChangeNotify() async {
    if (await _notifyManager.stopChangeNotify()) {
      _notifyingOfChange = false;
    }
  }

  static Future<void> forceOldApi() => plugin.forceOldApi();

  /// Get the system version.
  static Future<String> systemVersion() => plugin.getSystemVersion();

  /// Clear all file caches.
  static Future<void> clearFileCache() => plugin.clearFileCache();

  /// Get the asset count
  static Future<int> getAssetCount({
    PMFilter? filterOption,
    RequestType type = RequestType.common,
  }) {
    return plugin.getAssetCount(filterOption: filterOption, type: type);
  }

  /// Get the asset list with range.
  ///
  /// The [start] is base 0.
  ///
  /// The [end] is not included.
  ///
  /// The [filterOption] is used to filter the assets.
  ///
  /// The [type] is used to filter the assets type.
  static Future<List<AssetEntity>> getAssetListRange({
    required int start,
    required int end,
    PMFilter? filterOption,
    RequestType type = RequestType.common,
  }) async {
    assert(start >= 0, 'start must >= 0');
    assert(end >= 0, 'end must >= 0');
    assert(start < end, 'start must < end');
    return plugin.getAssetListWithRange(
      start: start,
      end: end,
      filterOption: filterOption,
      type: type,
    );
  }

  /// Get the asset list with page.
  ///
  /// The [page] is base 0.
  ///
  /// The [pageCount] is the count of each page.
  ///
  /// The [filterOption] is used to filter the assets.
  ///
  /// The [type] is used to filter the assets type.
  static Future<List<AssetEntity>> getAssetListPaged({
    required int page,
    required int pageCount,
    PMFilter? filterOption,
    RequestType type = RequestType.common,
  }) async {
    assert(page >= 0, 'page must >= 0');
    assert(pageCount > 0, 'pageCount must > 0');
    final start = page * pageCount;
    final end = start + pageCount;
    return getAssetListRange(
      start: start,
      end: end,
      filterOption: filterOption,
      type: type,
    );
  }
}

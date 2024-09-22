// Copyright 2018 The FlutterCandies author. All rights reserved.
// Use of this source code is governed by an Apache license that can be found
// in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../filter/base_filter.dart';
import '../filter/path_filter.dart';
import '../internal/editor.dart';
import '../internal/enums.dart';
import '../internal/plugin.dart' as base;
import '../types/entity.dart';
import '../types/types.dart';
import 'notify_manager.dart';

/// The core manager of this package, providing methods for accessing and managing assets.
class PhotoManager {
  /// Creates a new instance of the [PhotoManagerPlugin] class with an optional plugin instance to use instead of the global singleton.
  ///
  /// This is primarily intended for use in testing scenarios where you need to inject a mock or stubbed plugin instance.
  @visibleForTesting
  PhotoManager.withPlugin([base.PhotoManagerPlugin? photoManagerPlugin]) {
    if (photoManagerPlugin != null && photoManagerPlugin != base.plugin) {
      base.plugin = photoManagerPlugin;
    }
  }

  /// An editor instance for performing edits on assets.
  static final Editor editor = Editor();

  /// A notify manager instance for managing asset change notifications.
  static final NotifyManager _notifyManager = NotifyManager();

  /// The global singleton of the [PhotoManagerPlugin] class that handles all method channels.
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

  /// Get the current [PermissionState] of the photo library
  /// with the given [requestOption].
  ///
  /// Example:
  /// ```dart
  /// final PermissionState state = await PhotoManager.getPermissionState(
  ///   requestOption: const PermissionRequestOption(
  ///     androidPermission: AndroidPermission(
  //        type: RequestType.image,
  //        mediaLocation: false,
  //      ),
  ///   ),
  /// );
  /// if (state == PermissionState.authorized) {
  ///   print('The application has full access permission');
  /// } else {
  ///   print('The application does not have full access permission');
  /// }
  /// ```
  ///
  /// Note: On Android, this method may require an `Activity` context.
  /// Call [setIgnorePermissionCheck] if the call is from background service.
  static Future<PermissionState> getPermissionState({
    required PermissionRequestOption requestOption,
  }) {
    return plugin.getPermissionState(requestOption);
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
  static Future<void> presentLimited({
    RequestType type = RequestType.all,
  }) =>
      plugin.presentLimited(type);

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
    PMPathFilter pathFilterOption = const PMPathFilter(),
  }) async {
    return plugin.getAssetPathList(
      hasAll: hasAll,
      onlyAll: onlyAll,
      type: type,
      filterOption: filterOption,
      pathFilterOption: pathFilterOption,
    );
  }

  /// Controls whether the plugin should log messages to the console during operation.
  ///
  /// The [isLog] parameter is used to enable or disable logging.
  /// The [verboseFilePath] parameter is used to specify the path to record verbose logs.
  static Future<void> setLog(
    bool isLog, {
    String? verboseFilePath,
  }) async {
    final isVerbose = isLog && verboseFilePath != null;
    await plugin.setLog(isLog);
    if (verboseFilePath != null) {
      plugin.setVerbose(isVerbose, verboseFilePath);
    }
  }

  /// Get the verbose file path
  static String? getVerboseFilePath() => plugin.getVerboseFilePath();

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
  /// The method does not supported on OpenHarmony.
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

  /// Forces the plugin to use the old API for accessing the device's media library on Android 10 and above.
  ///
  /// This method should only be used as a last resort if the new API is not functioning correctly on certain devices.
  /// Using this method may have negative effects on performance and stability, and is not recommended unless absolutely necessary.
  /// If you are planning to publish your app on Google Play Store, it is not recommended to use this API.
  ///
  /// This method is asynchronous and returns a [Future] that completes when the operation is finished.
  static Future<void> forceOldApi() => plugin.forceOldApi();

  /// Get the system version.
  static Future<String> systemVersion() => plugin.getSystemVersion();

  /// Clear all file caches.
  /// The method does not supported on OpenHarmony.
  static Future<void> clearFileCache() => plugin.clearFileCache();

  /// Returns the count of assets.
  ///
  /// This static method invokes the `getAssetCount()` method of the `plugin`
  /// object to get the count of all assets. The optional `filterOption` parameter
  /// allows you to filter the assets based on specific criteria.
  /// By default, the `type` parameter is set to `RequestType.common`, which means that only common assets are counted.
  ///
  /// Parameters:
  /// - `filterOption`: An optional parameter of type `PMFilter` that filters the assets based on specific criteria. Defaults to null.
  /// - `type`: An optional parameter of type `RequestType`. Specifies the type of asset to count. Defaults to `RequestType.common`.
  ///
  /// Returns: A `Future<int>` object representing the number of assets requested.
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

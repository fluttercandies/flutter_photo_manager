import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../filter/filter_option_group.dart';
import '../internal/editor.dart';
import '../internal/enums.dart';
import '../internal/extensions.dart';
import '../internal/plugin.dart';
import '../types/entity.dart';
import '../types/types.dart';
import '../utils/convert_utils.dart';
import 'notify_manager.dart';

/// The core manager of this plugin.
/// Use various methods in this class to access & manage assets.
class PhotoManager {
  const PhotoManager._();

  @Deprecated(
    'Use requestPermissionExtend for better compatibility. '
    'This feature was deprecated after v2.0.0.',
  )
  static Future<bool> requestPermission() async {
    return (await requestPermissionExtend()).isAuth;
  }

  /// ### Android (AndroidManifest.xml)
  ///  * WRITE_EXTERNAL_STORAGE
  ///  * READ_EXTERNAL_STORAGE
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
    PermisstionRequestOption requestOption = const PermisstionRequestOption(),
  }) async {
    final int resultIndex = await plugin.requestPermissionExtend(requestOption);
    return PermissionState.values[resultIndex];
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

  static Editor editor = Editor();

  /// Obtain albums/folders list with couple filter options.
  ///
  /// To obtain albums list that contains the root album
  /// (generally named "Recent"), set [hasAll] to true.
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
    FilterOptionGroup? filterOption,
  }) async {
    if (onlyAll) {
      assert(hasAll, 'If only is true, then the hasAll must be not null.');
    }
    filterOption ??= FilterOptionGroup();
    assert(
      type != RequestType.all,
      'The request type must have video, image or audio.',
    );
    if (type == RequestType.all) {
      return <AssetPathEntity>[];
    }
    return plugin.getAllGalleryList(
      hasAll: hasAll,
      onlyAll: onlyAll,
      type: type,
      optionGroup: filterOption,
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

  /// Notification class for managing photo changes.
  static final NotifyManager _notifyManager = NotifyManager();

  /// Add a callback for assets changing.
  static void addChangeCallback(ValueChanged<MethodCall> callback) =>
      _notifyManager.addCallback(callback);

  /// Remove the callback for assets changing.
  static void removeChangeCallback(ValueChanged<MethodCall> callback) =>
      _notifyManager.removeCallback(callback);

  /// Whether assets change event should be notified.
  static bool notifyingOfChange = false;

  /// The notify enable flag in stream.
  static Stream<bool> get notifyStream => _notifyManager.notifyStream;

  /// Enable notifications for assets changing.
  ///
  /// Make sure you've added a callback for changes.
  static void startChangeNotify() {
    _notifyManager.startHandleNotify();
    notifyingOfChange = true;
  }

  /// Disable notifications for assets changing.
  ///
  /// Remember to remove callbacks for changes.
  static void stopChangeNotify() {
    _notifyManager.stopHandleNotify();
    notifyingOfChange = false;
  }

  /// Refresh the property of [AssetPathEntity] from the given ID.
  static Future<AssetEntity?> refreshAssetProperties(String id) async {
    final Map<dynamic, dynamic>? map =
        await plugin.getPropertiesFromAssetEntity(id);
    final AssetEntity? asset = ConvertUtils.convertToAsset(
      map?.cast<String, dynamic>(),
    );
    if (asset == null) {
      return null;
    }
    return asset;
  }

  /// Obtain a new [AssetPathEntity] from the given one
  /// with refreshed properties.
  static Future<AssetPathEntity?> fetchPathProperties({
    required AssetPathEntity entity,
    required FilterOptionGroup filterOptionGroup,
  }) async {
    final Map<dynamic, dynamic>? result = await plugin.fetchPathProperties(
      entity.id,
      entity.type,
      entity.filterOption,
    );
    if (result == null) {
      return null;
    }
    final Object? list = result['data'];
    if (list is List && list.isNotEmpty) {
      return ConvertUtils.convertPath(
        result.cast<String, dynamic>(),
        type: entity.type,
        optionGroup: entity.filterOption,
      ).first;
    }
    return null;
  }

  static Future<void> forceOldApi() => plugin.forceOldApi();

  /// Get the system version.
  static Future<String> systemVersion() => plugin.getSystemVersion();

  /// Clear all file caches.
  static Future<void> clearFileCache() => plugin.clearFileCache();

  /// Cache files into sandbox on Android Q when set to true,
  /// and cached files can be reused.
  static Future<bool> setCacheAtOriginBytes(bool cache) =>
      plugin.cacheOriginBytes(cache);
}

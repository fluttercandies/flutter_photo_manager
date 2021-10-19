///
/// [Author] Alex (https://github.com/AlexV525)
/// [Date] 2021/10/19 13:50
///
class PMConstants {
  const PMConstants._();

  static const String channelPrefix = 'com.fluttercandies/photo_manager';

  /// Keys for [MethodCall]s.
  static const String mRequestPermissionExtended = 'requestPermissionExtended';
  static const String mPresentLimited = 'presentLimited';
  static const String mGetGalleryList = 'getGalleryList';
  static const String mGetAssetWithGalleryId = 'getAssetWithGalleryId';
  static const String mGetAssetListWithRange = 'getAssetListWithRange';
  static const String mGetThumb = 'getThumb';
  static const String mGetOriginBytes = 'getOriginBytes';
  static const String mGetFullFile = 'getFullFile';
  static const String mReleaseMemCache = 'releaseMemCache';
  static const String mLog = 'log';
  static const String mOpenSetting = 'openSetting';
  static const String mFetchPathProperties = 'fetchPathProperties';
  static const String mNotify = 'notify';
  static const String mForceOldApi = 'notify';
  static const String mDeleteWithIds = 'deleteWithIds';
  static const String mSaveImage = 'saveImage';
  static const String mSaveImageWithPath = 'saveImageWithPath';
  static const String mSaveVideo = 'saveVideo';
  static const String mAssetExists = 'assetExists';
  static const String mSystemVersion = 'systemVersion';
  static const String mGetLatLngAndroidQ = 'getLatLngAndroidQ';
  static const String mCacheOriginBytes = 'cacheOriginBytes';
  static const String mGetTitleAsync = 'getTitleAsync';
  static const String mGetMediaUrl = 'getMediaUrl';
  static const String mGetSubPath = 'getSubPath';
  static const String mCopyAsset = 'copyAsset';
  static const String mDeleteAlbum = 'deleteAlbum';
  static const String mFavoriteAsset = 'favoriteAsset';
  static const String mRemoveNoExistsAssets = 'removeNoExistsAssets';
  static const String mGetPropertiesFromAssetEntity = 'getPropertiesFromAssetEntity';
  static const String mIgnorePermissionCheck = 'ignorePermissionCheck';
  static const String mClearFileCache = 'clearFileCache';
  static const String mCancelCacheRequests = 'cancelCacheRequests';
  static const String mRequestCacheAssetsThumb = 'requestCacheAssetsThumb';
  static const String mIsLocallyAvailable = 'isLocallyAvailable';
  static const String mCreateAlbum = 'createAlbum';
  static const String mCreateFolder = 'createFolder';
  static const String mRemoveInAlbum = 'removeInAlbum';
  static const String mMoveAssetToPath = 'moveAssetToPath';

  /// Constant value.
  static const int vDefaultThumbnailSize = 150;
  static const int vDefaultThumbnailQuality = 95;
}

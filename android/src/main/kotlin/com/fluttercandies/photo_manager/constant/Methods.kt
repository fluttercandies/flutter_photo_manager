package com.fluttercandies.photo_manager.constant

class Methods {
    companion object {
        const val log = "log"
        const val openSetting = "openSetting"
        const val forceOldAPI = "forceOldApi"
        const val systemVersion = "systemVersion"
        const val clearFileCache = "clearFileCache"
        const val releaseMemoryCache = "releaseMemoryCache"

        const val requestPermissionExtend = "requestPermissionExtend"

        const val getThumbnail = "getThumb"
        const val requestCacheAssetsThumbnail = "requestCacheAssetsThumb"
        const val cancelCacheRequests = "cancelCacheRequests"
        const val assetExists = "assetExists"
        const val getFullFile = "getFullFile"
        const val getOriginBytes = "getOriginBytes"
        const val getMediaUrl = "getMediaUrl"
        const val fetchEntityProperties = "fetchEntityProperties"

        const val getLatLng = "getLatLngAndroidQ"
        const val notify = "notify"
        const val deleteWithIds = "deleteWithIds"
        const val saveImage = "saveImage"
        const val saveImageWithPath = "saveImageWithPath"
        const val saveVideo = "saveVideo"
        const val copyAsset = "copyAsset"
        const val moveAssetToPath = "moveAssetToPath"
        const val removeNoExistsAssets = "removeNoExistsAssets"
        const val getColumnNames = "getColumnNames"

        const val getAssetCount = "getAssetCount"
        const val getAssetsByRange = "getAssetsByRange"

        /// Below methods have [RequestType] params, thus permissions are required for Android 13.
        const val fetchPathProperties = "fetchPathProperties"
        const val getAssetPathList = "getAssetPathList"
        const val getAssetListPaged = "getAssetListPaged"
        const val getAssetListRange = "getAssetListRange"

        val android13PermissionMethods = arrayOf(
            fetchPathProperties,
            getAssetPathList,
            getAssetListPaged,
            getAssetListRange,
        )
    }
}

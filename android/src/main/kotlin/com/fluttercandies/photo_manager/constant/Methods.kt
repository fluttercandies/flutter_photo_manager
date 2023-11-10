package com.fluttercandies.photo_manager.constant

class Methods {
    companion object {
        // Not need permission methods
        const val log = "log"
        const val openSetting = "openSetting"
        const val forceOldAPI = "forceOldApi"
        const val systemVersion = "systemVersion"
        const val clearFileCache = "clearFileCache"
        const val releaseMemoryCache = "releaseMemoryCache"
        const val ignorePermissionCheck = "ignorePermissionCheck"

        fun isNotNeedPermissionMethod(method: String): Boolean {
            return method in arrayOf(
                log,
                openSetting,
                forceOldAPI,
                systemVersion,
                clearFileCache,
                releaseMemoryCache,
                ignorePermissionCheck,
            )
        }
        // Not need permission methods end

        // About permission start
        const val requestPermissionExtend = "requestPermissionExtend"
        const val presentLimited = "presentLimited"

        fun isPermissionMethod(method: String): Boolean {
            return method in arrayOf(
                requestPermissionExtend,
                presentLimited,
            )
        }
        // About permission end

        /// Have [requestType] start
        const val fetchPathProperties = "fetchPathProperties"
        const val getAssetPathList = "getAssetPathList"
        const val getAssetListPaged = "getAssetListPaged"
        const val getAssetListRange = "getAssetListRange"
        const val getAssetCountFromPath = "getAssetCountFromPath"
        const val getAssetCount = "getAssetCount"
        const val getAssetsByRange = "getAssetsByRange"

        private val haveRequestTypeMethods = arrayOf(
            fetchPathProperties,
            getAssetPathList,
            getAssetListPaged,
            getAssetCountFromPath,
            getAssetListRange,
            getAssetCount,
            getAssetsByRange,
        )

        private fun isHaveRequestTypeMethod(method: String): Boolean {
            return method in haveRequestTypeMethods
        }
        /// Have [requestType] end

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
        const val moveToTrash = "moveToTrash"

        const val saveImage = "saveImage"
        const val saveImageWithPath = "saveImageWithPath"
        const val saveVideo = "saveVideo"
        const val copyAsset = "copyAsset"
        const val moveAssetToPath = "moveAssetToPath"
        const val removeNoExistsAssets = "removeNoExistsAssets"
        const val getColumnNames = "getColumnNames"

        private val needMediaLocationMethods = arrayOf(
            getLatLng,
            getFullFile,
            getOriginBytes,
        )

        private fun isNeedMediaLocationMethod(method: String): Boolean {
            return method in needMediaLocationMethods
        }

        @Suppress("unused")
        fun otherMethods(method: String): Boolean {
            return (isNotNeedPermissionMethod(method) ||
                    isPermissionMethod(method) ||
                    isHaveRequestTypeMethod(method) ||
                    isNeedMediaLocationMethod(method))
                .not()
        }
    }
}

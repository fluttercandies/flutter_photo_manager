package com.fluttercandies.photo_manager.core.entity

import android.net.Uri
import com.fluttercandies.photo_manager.core.utils.IDBUtils.Companion.isAndroidQ
import com.fluttercandies.photo_manager.core.utils.MediaStoreUtils
import java.io.File

/// create 2019-09-05 by cai
data class AssetEntity(
    val id: String,
    var path: String,
    val duration: Long,
    val createDt: Long,
    val width: Int,
    val height: Int,
    val type: Int,
    val displayName: String,
    val modifiedDate: Long,
    val orientation: Int,
    var lat: Double? = null,
    var lng: Double? = null,
    val androidQRelativePath: String? = null,
    val mimeType: String? = null
) {

    fun getUri(): Uri {
        return MediaStoreUtils.getDeleteUri(id, MediaStoreUtils.convertTypeToMediaType(type))
    }

    val relativePath: String?
        get() {
            return if (isAndroidQ) {
                androidQRelativePath
            } else {
                File(path).parent
            }
        }
}

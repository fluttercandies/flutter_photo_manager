package com.fluttercandies.photo_manager.core.entity

import android.net.Uri
import com.fluttercandies.photo_manager.core.utils.IDBUtils.Companion.isAboveAndroidQ
import com.fluttercandies.photo_manager.core.utils.MediaStoreUtils
import java.io.File

data class AssetEntity(
    val id: Long,
    val path: String,
    val duration: Long,
    val createDt: Long,
    val width: Int,
    val height: Int,
    val type: Int,
    val displayName: String,
    val modifiedDate: Long,
    val orientation: Int,
    val isFavorite: Boolean = false,
    val lat: Double? = null,
    val lng: Double? = null,
    val androidQRelativePath: String? = null,
    val mimeType: String? = null,
    // AIGC START - Android motion photo uses same subtype as iOS live photo for isLivePhoto
    val subtype: Int = 0
    // AIGC END
) {
    fun getUri(): Uri = MediaStoreUtils.getUri(
        id,
        MediaStoreUtils.convertTypeToMediaType(type)
    )

    val relativePath: String? = if (isAboveAndroidQ) {
        androidQRelativePath
    } else {
        File(path).parent
    }
}

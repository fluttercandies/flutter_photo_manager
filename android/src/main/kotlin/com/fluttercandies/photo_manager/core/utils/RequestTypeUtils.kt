package com.fluttercandies.photo_manager.core.utils

import android.provider.MediaStore

object RequestTypeUtils {
    private const val typeImage = 1
    private const val typeVideo = 1.shl(1)
    private const val typeAudio = 1.shl(2)

    fun containsImage(type: Int): Boolean = checkType(type, typeImage)

    fun containsVideo(type: Int): Boolean = checkType(type, typeVideo)

    fun containsAudio(type: Int): Boolean = checkType(type, typeAudio)

    private fun checkType(type: Int, targetType: Int): Boolean {
        return type and targetType == targetType
    }

    fun toWhere(requestType: Int): String {
        val typeInt = arrayListOf<Int>()
        if (containsImage(requestType)) {
            typeInt.add(MediaStore.Files.FileColumns.MEDIA_TYPE_IMAGE)
        }
        if (containsAudio(requestType)) {
            typeInt.add(MediaStore.Files.FileColumns.MEDIA_TYPE_AUDIO)
        }
        if (containsVideo(requestType)) {
            typeInt.add(MediaStore.Files.FileColumns.MEDIA_TYPE_VIDEO)
        }

        val where = typeInt.joinToString(" OR ") {
            "${MediaStore.Files.FileColumns.MEDIA_TYPE} = $it"
        }

        return "( $where )"
    }
}

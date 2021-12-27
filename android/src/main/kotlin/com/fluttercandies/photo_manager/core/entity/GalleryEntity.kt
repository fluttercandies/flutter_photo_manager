package com.fluttercandies.photo_manager.core.entity

data class GalleryEntity(
    val id: String,
    val name: String,
    var length: Int,
    val typeInt: Int,
    var isAll: Boolean = false,
    var modifiedDate: Long? = null
)

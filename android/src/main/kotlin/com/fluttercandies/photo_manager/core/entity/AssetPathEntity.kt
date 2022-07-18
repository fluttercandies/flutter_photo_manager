package com.fluttercandies.photo_manager.core.entity

data class AssetPathEntity(
    val id: String,
    val name: String,
    var assetCount: Int,
    val typeInt: Int,
    var isAll: Boolean = false,
    var modifiedDate: Long? = null
)

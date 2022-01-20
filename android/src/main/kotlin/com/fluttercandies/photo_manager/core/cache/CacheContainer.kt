package com.fluttercandies.photo_manager.core.cache

import com.fluttercandies.photo_manager.core.entity.AssetEntity

class CacheContainer {
    /** Keys are paths, values are [AssetEntity]. */
    private val assetMap = HashMap<String, AssetEntity>()

    fun getAsset(id: String): AssetEntity? = assetMap[id]

    fun putAsset(assetEntity: AssetEntity) {
        assetMap[assetEntity.id] = assetEntity
    }

    fun clearCache() = assetMap.clear()
}

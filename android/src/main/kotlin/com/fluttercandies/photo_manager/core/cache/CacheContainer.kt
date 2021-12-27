package com.fluttercandies.photo_manager.core.cache

import com.fluttercandies.photo_manager.core.entity.AssetEntity

class CacheContainer {
    // key is path
    // value is asset entity
    private val assetMap = HashMap<String, AssetEntity>()

    fun putAsset(assetEntity: AssetEntity) {
        assetMap[assetEntity.id] = assetEntity
    }

    fun getAsset(id: String): AssetEntity? {
        return assetMap[id]
    }

    fun clearCache() {
        assetMap.clear()
    }
}

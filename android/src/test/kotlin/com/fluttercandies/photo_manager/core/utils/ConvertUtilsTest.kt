package com.fluttercandies.photo_manager.core.utils

import com.fluttercandies.photo_manager.core.entity.AssetEntity
import org.junit.Assert.assertEquals
import org.junit.Test

class ConvertUtilsTest {

    @Test
    fun `convertAsset includes trash state`() {
        val entity = AssetEntity(
            1, "/tmp/asset.jpg", 0, 0, 1, 1,
            1, "asset.jpg", 0, 0,
            isTrashed = true
        )

        assertEquals(true, ConvertUtils.convertAsset(entity)["is_trashed"])
    }
}

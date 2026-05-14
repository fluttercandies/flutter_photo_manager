package com.fluttercandies.photo_manager.permission.impl

import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class PermissionDelegate34Test {
    @Test
    fun `common request requires both image and video permissions when not limited`() {
        val result = hasRequestedVisualPermissions(
            containsImage = true,
            containsVideo = true,
            hasImagePermission = true,
            hasVideoPermission = false,
            hasLimitedPermission = false,
        )

        assertFalse(result)
    }

    @Test
    fun `common request succeeds when image and video permissions are both granted`() {
        val result = hasRequestedVisualPermissions(
            containsImage = true,
            containsVideo = true,
            hasImagePermission = true,
            hasVideoPermission = true,
            hasLimitedPermission = false,
        )

        assertTrue(result)
    }

    @Test
    fun `limited visual access satisfies combined visual requests`() {
        val result = hasRequestedVisualPermissions(
            containsImage = true,
            containsVideo = true,
            hasImagePermission = false,
            hasVideoPermission = false,
            hasLimitedPermission = true,
        )

        assertTrue(result)
    }

    @Test
    fun `image only request still succeeds with image permission alone`() {
        val result = hasRequestedVisualPermissions(
            containsImage = true,
            containsVideo = false,
            hasImagePermission = true,
            hasVideoPermission = false,
            hasLimitedPermission = false,
        )

        assertTrue(result)
    }
}

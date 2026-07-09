package com.fluttercandies.photo_manager.core.utils

import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

/**
 * Unit tests for [IDBUtils.isVolumeNotFound].
 *
 * The predicate exists to route only MediaProvider's transient
 * "Volume <name> not found" IllegalArgumentException through the empty-cursor
 * graceful path. Any other IllegalArgumentException (bad projection, malformed
 * CustomFilter selection, unauthorized column) must still surface.
 */
class IsVolumeNotFoundTest {

    @Test
    fun `matches the primary volume message`() {
        val e = IllegalArgumentException("Volume external_primary not found")
        assertTrue(IDBUtils.isVolumeNotFound(e))
    }

    @Test
    fun `matches the external umbrella volume message`() {
        val e = IllegalArgumentException("Volume external not found")
        assertTrue(IDBUtils.isVolumeNotFound(e))
    }

    @Test
    fun `matches a hypothetical named removable volume`() {
        val e = IllegalArgumentException("Volume 0000-1234 not found")
        assertTrue(IDBUtils.isVolumeNotFound(e))
    }

    @Test
    fun `does not match a bad-projection error`() {
        val e = IllegalArgumentException("Invalid column bogus_column")
        assertFalse(IDBUtils.isVolumeNotFound(e))
    }

    @Test
    fun `does not match a bad-selection error`() {
        val e = IllegalArgumentException("bad SQL syntax near AND")
        assertFalse(IDBUtils.isVolumeNotFound(e))
    }

    @Test
    fun `does not match a message that only starts with Volume`() {
        // e.g. an unrelated exception that happens to mention Volume
        val e = IllegalArgumentException("Volume must be positive")
        assertFalse(IDBUtils.isVolumeNotFound(e))
    }

    @Test
    fun `does not match a message that only ends with not found`() {
        val e = IllegalArgumentException("Row not found")
        assertFalse(IDBUtils.isVolumeNotFound(e))
    }

    @Test
    fun `does not match when the exception has no message`() {
        val e = IllegalArgumentException()
        assertFalse(IDBUtils.isVolumeNotFound(e))
    }
}

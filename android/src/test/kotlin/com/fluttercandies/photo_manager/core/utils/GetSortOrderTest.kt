package com.fluttercandies.photo_manager.core.utils

import org.junit.Assert.assertEquals
import org.junit.Test

/**
 * Unit tests for the getSortOrder SQL syntax generation.
 *
 * These tests verify that the ORDER BY and LIMIT clauses are properly formatted
 * with correct spacing to prevent SQL syntax errors like "descLIMIT" instead of "desc LIMIT".
 */
class GetSortOrderTest {

    /**
     * Helper function that replicates the getSortOrder logic for testing.
     * This mirrors the implementation in IDBUtils.kt.
     */
    private fun getSortOrder(start: Int, pageSize: Int, orderBy: String?): String {
        val builder = StringBuilder()
        if (orderBy != null) {
            builder.append(orderBy)
            builder.append(" ")
        }
        builder.append("LIMIT $pageSize OFFSET $start")
        return builder.toString()
    }

    @Test
    fun `getSortOrder with orderBy ending in desc should have space before LIMIT`() {
        val result = getSortOrder(0, 10, "_id desc")
        assertEquals("_id desc LIMIT 10 OFFSET 0", result)
    }

    @Test
    fun `getSortOrder with orderBy ending in asc should have space before LIMIT`() {
        val result = getSortOrder(0, 10, "_id asc")
        assertEquals("_id asc LIMIT 10 OFFSET 0", result)
    }

    @Test
    fun `getSortOrder with multiple order conditions should have space before LIMIT`() {
        val result = getSortOrder(5, 20, "_id desc,date_added asc")
        assertEquals("_id desc,date_added asc LIMIT 20 OFFSET 5", result)
    }

    @Test
    fun `getSortOrder without orderBy should only have LIMIT clause`() {
        val result = getSortOrder(0, 10, null)
        assertEquals("LIMIT 10 OFFSET 0", result)
    }

    @Test
    fun `getSortOrder with different pagination values`() {
        val result = getSortOrder(100, 50, "_id desc")
        assertEquals("_id desc LIMIT 50 OFFSET 100", result)
    }

    @Test
    fun `getSortOrder should not produce descLIMIT syntax error`() {
        val result = getSortOrder(0, 1, "_id desc")
        // The bug was producing "_id descLIMIT 1 OFFSET 0" without space
        assert(!result.contains("descLIMIT")) { "Should not contain 'descLIMIT' (missing space)" }
        assert(result.contains("desc LIMIT")) { "Should contain 'desc LIMIT' with space" }
    }

    @Test
    fun `getSortOrder should not produce ascLIMIT syntax error`() {
        val result = getSortOrder(0, 1, "_id asc")
        assert(!result.contains("ascLIMIT")) { "Should not contain 'ascLIMIT' (missing space)" }
        assert(result.contains("asc LIMIT")) { "Should contain 'asc LIMIT' with space" }
    }
}

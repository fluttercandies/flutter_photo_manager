package com.fluttercandies.photo_manager.core

import android.content.ContextWrapper
import android.database.Cursor
import android.provider.MediaStore
import com.fluttercandies.photo_manager.extension.toAssetEntity
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Rule
import org.junit.Test
import org.junit.rules.TemporaryFolder
import java.lang.reflect.Proxy

/**
 * Unit tests for the Android `deleteWithIds` flow: [collectDeleteUris] decides what is
 * submitted, [androidRResultIds] decides what is replied on Android 11+.
 *
 * Lookups go through the same `toAssetEntity(checkIfExists = false)` conversion that
 * [PhotoManager.getUriOrNull] uses, against fake MediaStore rows.
 */
class DeleteWithIdsTest {

    @get:Rule
    val tmp = TemporaryFolder()

    private val context = ContextWrapper(null)

    /** Fake MediaStore keyed by ID; an ID that is not a key has no row. */
    private lateinit var rows: Map<String, Cursor>

    private fun uriOf(id: String): Long? =
        rows[id]?.toAssetEntity(context, checkIfExists = false)?.id

    @Before
    fun setUp() {
        rows = mapOf(
            VALID to row(VALID.toLong(), tmp.newFile("valid.jpg").path),
            OTHER_VALID to row(OTHER_VALID.toLong(), tmp.newFile("other.jpg").path),
            STALE to row(STALE.toLong(), "${tmp.root}/missing.jpg"),
        )
    }

    @Test
    fun `valid and absent-row IDs submit only the valid ID`() {
        val submitted = collectDeleteUris(listOf(VALID, ABSENT), ::uriOf)

        assertEquals(listOf(VALID), submitted.keys.toList())
    }

    @Test
    fun `valid and stale-row IDs submit both so the stale row is removed too`() {
        val submitted = collectDeleteUris(listOf(VALID, STALE), ::uriOf)

        assertEquals(listOf(VALID, STALE), submitted.keys.toList())
    }

    @Test
    fun `all absent IDs submit nothing`() {
        val submitted = collectDeleteUris(listOf(ABSENT, "404"), ::uriOf)

        assertTrue(submitted.isEmpty())
    }

    @Test
    fun `empty input submits nothing`() {
        val submitted = collectDeleteUris(emptyList(), ::uriOf)

        assertTrue(submitted.isEmpty())
    }

    @Test
    fun `duplicate IDs are submitted once in input order`() {
        val submitted = collectDeleteUris(listOf(OTHER_VALID, VALID, OTHER_VALID, VALID), ::uriOf)

        assertEquals(listOf(OTHER_VALID, VALID), submitted.keys.toList())
    }

    @Test
    fun `cancelled confirmation replies no IDs`() {
        val submitted = collectDeleteUris(listOf(VALID, STALE), ::uriOf).keys.toList()

        val replied = androidRResultIds(approved = false, submittedIds = submitted) {
            listOf(VALID, STALE)
        }

        assertEquals(emptyList<String>(), replied)
    }

    @Test
    fun `approved confirmation replies the submitted subset, not the requested IDs`() {
        val requested = listOf(VALID, ABSENT, STALE, VALID)
        val submitted = collectDeleteUris(requested, ::uriOf).keys.toList()

        val replied = androidRResultIds(approved = true, submittedIds = submitted) { requested }

        assertEquals(listOf(VALID, STALE), replied)
    }

    @Test
    fun `approved request without submitted IDs falls back to the requested IDs`() {
        // Trash and restore requests record no submitted IDs.
        val replied = androidRResultIds(approved = true, submittedIds = null) { listOf(VALID) }

        assertEquals(listOf(VALID), replied)
    }

    private fun row(id: Long, path: String): Cursor {
        val values = mapOf<String, Any>(
            MediaStore.MediaColumns._ID to id,
            MediaStore.MediaColumns.DATA to path,
            MediaStore.Files.FileColumns.MEDIA_TYPE to MediaStore.Files.FileColumns.MEDIA_TYPE_IMAGE,
            MediaStore.MediaColumns.MIME_TYPE to "image/jpeg",
            MediaStore.MediaColumns.WIDTH to 1,
            MediaStore.MediaColumns.HEIGHT to 1,
        )
        val columns = values.keys.toList()
        return Proxy.newProxyInstance(
            Cursor::class.java.classLoader,
            arrayOf(Cursor::class.java),
        ) { _, method, args ->
            val value = (args?.firstOrNull() as? Int)?.let { columns.getOrNull(it) }?.let(values::get)
            when (method.name) {
                "getColumnIndex" -> columns.indexOf(args!![0] as String)
                "getLong" -> (value as? Number)?.toLong() ?: 0L
                "getInt" -> (value as? Number)?.toInt() ?: 0
                "getString" -> value?.toString()
                else -> null
            }
        } as Cursor
    }

    private companion object {
        const val VALID = "1"
        const val OTHER_VALID = "2"
        const val STALE = "3"
        const val ABSENT = "999"
    }
}

package com.fluttercandies.photo_manager.util

import org.junit.Assert.*
import org.junit.Test

/**
 * Unit tests for XmpWriter utility.
 */
class XmpWriterTest {

    @Test
    fun testGenerateMotionPhotoXmp_containsCurrentFormatAttributes() {
        val videoOffset = 123456L
        val xmp = XmpWriter.generateMotionPhotoXmp(videoOffset = videoOffset)

        // Current Motion Photo format
        assertTrue("XMP should contain MotionPhoto=1", xmp.contains("Camera:MotionPhoto=\"1\""))
        assertTrue("XMP should contain MotionPhotoVersion=1", xmp.contains("Camera:MotionPhotoVersion=\"1\""))
        assertTrue("XMP should contain MotionPhotoPresentationTimestampUs", xmp.contains("Camera:MotionPhotoPresentationTimestampUs=\"1500000\""))
        assertTrue("XMP should contain Container:Directory", xmp.contains("Container:Directory"))
        assertTrue("XMP should contain Primary semantic", xmp.contains("Item:Semantic=\"Primary\""))
        assertTrue("XMP should contain MotionPhoto semantic", xmp.contains("Item:Semantic=\"MotionPhoto\""))
        assertTrue("XMP should contain video offset as Item:Length", xmp.contains("Item:Length=\"$videoOffset\""))
    }

    @Test
    fun testGenerateMotionPhotoXmp_containsLegacyMicroVideoAttributes() {
        val videoOffset = 123456L
        val xmp = XmpWriter.generateMotionPhotoXmp(videoOffset = videoOffset)

        // Legacy MicroVideo format (for Xiaomi/MIUI compatibility)
        assertTrue("XMP should contain GCamera:MicroVideo=1", xmp.contains("GCamera:MicroVideo=\"1\""))
        assertTrue("XMP should contain GCamera:MicroVideoVersion=1", xmp.contains("GCamera:MicroVideoVersion=\"1\""))
        assertTrue("XMP should contain GCamera:MicroVideoOffset", xmp.contains("GCamera:MicroVideoOffset=\"$videoOffset\""))
        assertTrue("XMP should contain MicroVideoPresentationTimestampUs", xmp.contains("GCamera:MicroVideoPresentationTimestampUs=\"1500000\""))
    }

    @Test
    fun testGenerateMotionPhotoXmp_containsDefaultMimeTypes() {
        val videoOffset = 54321L
        val xmp = XmpWriter.generateMotionPhotoXmp(videoOffset = videoOffset)

        assertTrue("XMP should contain image/jpeg MIME", xmp.contains("Item:Mime=\"image/jpeg\""))
        assertTrue("XMP should contain video/mp4 MIME", xmp.contains("Item:Mime=\"video/mp4\""))
    }

    @Test
    fun testInjectXmpIntoJpeg() {
        // Create a minimal valid JPEG: SOI marker (0xFF 0xD8) + EOI marker (0xFF 0xD9)
        val jpegBytes = byteArrayOf(0xFF.toByte(), 0xD8.toByte(), 0xFF.toByte(), 0xD9.toByte())
        val xmpData = "test XMP data"

        val result = XmpWriter.injectXmpIntoJpeg(jpegBytes, xmpData)

        // Verify the result starts with SOI marker
        assertEquals("Result should start with 0xFF", 0xFF.toByte(), result[0])
        assertEquals("Result should have SOI marker", 0xD8.toByte(), result[1])

        // Verify APP1 marker is injected
        assertEquals("APP1 marker should be 0xFF", 0xFF.toByte(), result[2])
        assertEquals("APP1 marker type should be 0xE1", 0xE1.toByte(), result[3])

        // Verify the result is larger than the original (XMP was added)
        assertTrue("Result should be larger than original", result.size > jpegBytes.size)

        // Verify the XMP namespace prefix is present
        val resultStr = String(result, Charsets.UTF_8)
        assertTrue("Result should contain XMP namespace prefix", resultStr.contains("http://ns.adobe.com/xap/1.0/"))
    }

    @Test(expected = IllegalArgumentException::class)
    fun testInjectXmpIntoJpeg_InvalidJpeg() {
        // Invalid JPEG data (missing SOI marker)
        val invalidBytes = byteArrayOf(0x00, 0x01, 0x02, 0x03)
        val xmpData = "test XMP data"

        // Should throw IllegalArgumentException
        XmpWriter.injectXmpIntoJpeg(invalidBytes, xmpData)
    }

    @Test
    fun testInjectXmpIntoJpeg_stripsExistingXmp() {
        // Create a JPEG with an existing XMP APP1 segment
        val xmpPrefix = "http://ns.adobe.com/xap/1.0/\u0000old XMP data".toByteArray(Charsets.UTF_8)
        val segLen = 2 + xmpPrefix.size
        val jpegWithXmp = byteArrayOf(
            0xFF.toByte(), 0xD8.toByte(),  // SOI
            0xFF.toByte(), 0xE1.toByte(),  // APP1 marker
            (segLen shr 8).toByte(), (segLen and 0xFF).toByte()  // Length
        ) + xmpPrefix + byteArrayOf(
            0xFF.toByte(), 0xD9.toByte()   // EOI
        )

        val newXmpData = "new XMP data"
        val result = XmpWriter.injectXmpIntoJpeg(jpegWithXmp, newXmpData)

        // Should contain new XMP but not old XMP
        val resultStr = String(result, Charsets.UTF_8)
        assertTrue("Result should contain new XMP", resultStr.contains("new XMP data"))
        assertFalse("Result should NOT contain old XMP", resultStr.contains("old XMP data"))
    }

    @Test
    fun testCreateMotionPhotoStream() {
        // Create minimal JPEG
        val imageBytes = byteArrayOf(0xFF.toByte(), 0xD8.toByte(), 0xFF.toByte(), 0xD9.toByte())
        val videoBytes = byteArrayOf(0x01, 0x02, 0x03, 0x04)

        val stream = XmpWriter.createMotionPhotoStream(imageBytes, videoBytes)
        val resultBytes = stream.readBytes()

        // Verify the result starts with JPEG SOI marker
        assertEquals("Result should start with 0xFF", 0xFF.toByte(), resultBytes[0])
        assertEquals("Result should have SOI marker", 0xD8.toByte(), resultBytes[1])

        // Verify APP1 marker is present (XMP was injected)
        assertEquals("APP1 marker should be 0xFF", 0xFF.toByte(), resultBytes[2])
        assertEquals("APP1 marker type should be 0xE1", 0xE1.toByte(), resultBytes[3])

        // Verify the result ends with the video bytes
        val actualEnd = resultBytes.takeLast(videoBytes.size).toByteArray()
        assertArrayEquals("Result should end with video bytes", videoBytes, actualEnd)

        // Verify XMP contains both legacy and current format attributes
        val resultStr = String(resultBytes, Charsets.UTF_8)
        assertTrue("Should contain Camera:MotionPhoto", resultStr.contains("Camera:MotionPhoto=\"1\""))
        assertTrue("Should contain GCamera:MicroVideo", resultStr.contains("GCamera:MicroVideo=\"1\""))
        assertTrue("Should contain MicroVideoOffset", resultStr.contains("GCamera:MicroVideoOffset=\"${videoBytes.size}\""))
    }
}

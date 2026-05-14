package com.fluttercandies.photo_manager.util

import java.io.ByteArrayOutputStream
import java.io.File
import java.io.FileOutputStream
import java.io.InputStream

/**
 * Utility for writing XMP metadata to JPEG files for Motion Photos.
 *
 * A Kotlin port following the approach of MotionPhotoMuxer
 * (https://github.com/mihir-io/MotionPhotoMuxer).
 *
 * Merges a JPEG photo and a video into a single Google Motion Photo
 * (MicroVideo-formatted JPEG with embedded video and XMP metadata).
 *
 * Also includes legacy MicroVideo attributes for compatibility with
 * older gallery apps (e.g., MIUI Gallery on Xiaomi devices).
 */
object XmpWriter {
    // JPEG markers
    private const val JPEG_SOI: Byte = 0xD8.toByte()    // Start Of Image
    private const val JPEG_APP1: Byte = 0xE1.toByte()   // APP1 marker (for EXIF/XMP)
    private const val JPEG_MARKER: Byte = 0xFF.toByte()

    // XMP APP1 identifier prefix
    private const val XMP_APP1_PREFIX = "http://ns.adobe.com/xap/1.0/"

    /**
     * Generates the XMP/RDF payload that marks the file as a Motion Photo.
     *
     * Follows both the current specification (Camera:MotionPhoto) and the
     * legacy MicroVideo format for maximum compatibility across different
     * gallery applications (e.g., Xiaomi, Samsung, older apps).
     *
     * @param videoOffset The number of bytes from EOF to the start of the
     *                    embedded video (i.e. the video file size, since
     *                    the video is appended at the end).
     * @return The XMP metadata as a string
     */
    fun generateMotionPhotoXmp(videoOffset: Long): String {
        return """
            <?xpacket begin="${'\uFEFF'}" id="W5M0MpCehiHzreSzNTczkc9d"?>
            <x:xmpmeta xmlns:x="adobe:ns:meta/">
              <rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#">
                <rdf:Description
                    xmlns:GCamera="http://ns.google.com/photos/1.0/camera/"
                    xmlns:Camera="http://ns.google.com/photos/1.0/camera/"
                    xmlns:Container="http://ns.google.com/photos/1.0/container/"
                    xmlns:Item="http://ns.google.com/photos/1.0/container/item/"
                    Camera:MotionPhoto="1"
                    Camera:MotionPhotoVersion="1"
                    Camera:MotionPhotoPresentationTimestampUs="1500000"
                    GCamera:MicroVideo="1"
                    GCamera:MicroVideoVersion="1"
                    GCamera:MicroVideoOffset="$videoOffset"
                    GCamera:MicroVideoPresentationTimestampUs="1500000">
                  <Container:Directory>
                    <rdf:Seq>
                      <rdf:li rdf:parseType="Resource">
                        <Container:Item
                            Item:Mime="image/jpeg"
                            Item:Semantic="Primary"/>
                      </rdf:li>
                      <rdf:li rdf:parseType="Resource">
                        <Container:Item
                            Item:Mime="video/mp4"
                            Item:Semantic="MotionPhoto"
                            Item:Length="$videoOffset"/>
                      </rdf:li>
                    </rdf:Seq>
                  </Container:Directory>
                </rdf:Description>
              </rdf:RDF>
            </x:xmpmeta>
            <?xpacket end="w"?>
        """.trimIndent()
    }

    /**
     * Injects XMP metadata into a JPEG file by adding an APP1 marker segment.
     *
     * The XMP APP1 is inserted right after the SOI marker. If the JPEG already
     * has an existing XMP APP1 segment, it is removed first to avoid duplicates.
     *
     * @param imageBytes The original JPEG image bytes
     * @param xmpData The XMP metadata string to inject
     * @return The modified JPEG bytes with XMP metadata
     */
    fun injectXmpIntoJpeg(imageBytes: ByteArray, xmpData: String): ByteArray {
        // Validate JPEG SOI marker
        if (imageBytes.size < 2 || imageBytes[0] != JPEG_MARKER || imageBytes[1] != JPEG_SOI) {
            throw IllegalArgumentException("Invalid JPEG file: missing SOI marker")
        }

        // First, strip any existing XMP APP1 segments from the image
        val strippedImage = stripExistingXmpApp1(imageBytes)

        val outputStream = ByteArrayOutputStream()

        // Write SOI marker
        outputStream.write(JPEG_MARKER.toInt())
        outputStream.write(JPEG_SOI.toInt())

        // Create XMP APP1 segment:
        // Segment data = XMP namespace URI + null byte + XMP data
        val xmpPayload = (XMP_APP1_PREFIX + "\u0000" + xmpData).toByteArray(Charsets.UTF_8)
        val segmentLength = 2 + xmpPayload.size // 2 bytes for length field

        if (segmentLength > 0xFFFF) {
            throw IllegalArgumentException("XMP data too large for APP1 segment")
        }

        // Write APP1 marker
        outputStream.write(JPEG_MARKER.toInt())
        outputStream.write(JPEG_APP1.toInt())

        // Write segment length (big-endian)
        outputStream.write((segmentLength shr 8) and 0xFF)
        outputStream.write(segmentLength and 0xFF)

        // Write XMP payload
        outputStream.write(xmpPayload)

        // Append the rest of the JPEG data (skip SOI we already wrote)
        outputStream.write(strippedImage, 2, strippedImage.size - 2)

        return outputStream.toByteArray()
    }

    /**
     * Strips any existing XMP APP1 segments from a JPEG byte array.
     * Keeps EXIF APP1 segments intact.
     */
    private fun stripExistingXmpApp1(imageBytes: ByteArray): ByteArray {
        val xmpPrefix = XMP_APP1_PREFIX.toByteArray(Charsets.UTF_8)
        val output = ByteArrayOutputStream()
        var i = 0

        // Write SOI
        if (imageBytes.size < 2) return imageBytes
        output.write(imageBytes[0].toInt())
        output.write(imageBytes[1].toInt())
        i = 2

        while (i < imageBytes.size - 1) {
            if (imageBytes[i] == JPEG_MARKER && imageBytes[i + 1] == JPEG_APP1) {
                // This is an APP1 segment. Check if it's XMP.
                if (i + 3 < imageBytes.size) {
                    val segLen = ((imageBytes[i + 2].toInt() and 0xFF) shl 8) or
                            (imageBytes[i + 3].toInt() and 0xFF)
                    val segEnd = i + 2 + segLen

                    // Check if segment starts with XMP namespace prefix
                    val prefixEnd = i + 4 + xmpPrefix.size
                    if (prefixEnd <= imageBytes.size && segEnd <= imageBytes.size) {
                        val segIdent = imageBytes.copyOfRange(i + 4, prefixEnd)
                        if (segIdent.contentEquals(xmpPrefix)) {
                            // Skip this XMP APP1 segment
                            i = segEnd
                            continue
                        }
                    }

                    // Not XMP, keep it
                    output.write(imageBytes, i, segEnd - i)
                    i = segEnd
                } else {
                    output.write(imageBytes, i, imageBytes.size - i)
                    break
                }
            } else if (imageBytes[i] == JPEG_MARKER && imageBytes[i + 1].toInt() and 0xFF in 0xE0..0xEF) {
                // Other APP markers - copy as-is
                if (i + 3 < imageBytes.size) {
                    val segLen = ((imageBytes[i + 2].toInt() and 0xFF) shl 8) or
                            (imageBytes[i + 3].toInt() and 0xFF)
                    val segEnd = i + 2 + segLen
                    if (segEnd <= imageBytes.size) {
                        output.write(imageBytes, i, segEnd - i)
                        i = segEnd
                    } else {
                        output.write(imageBytes, i, imageBytes.size - i)
                        break
                    }
                } else {
                    output.write(imageBytes, i, imageBytes.size - i)
                    break
                }
            } else {
                // Non-APP marker or SOS data - copy the rest of file
                output.write(imageBytes, i, imageBytes.size - i)
                break
            }
        }

        return output.toByteArray()
    }

    /**
     * Creates a Motion Photo JPEG file with proper XMP metadata.
     *
     * Merges the photo and video, then injects XMP metadata.
     *
     * @param imageBytes The JPEG image bytes
     * @param videoBytes The video file bytes
     * @param outputFile The output file to write the Motion Photo to
     */
    fun createMotionPhoto(imageBytes: ByteArray, videoBytes: ByteArray, outputFile: File) {
        val videoOffset = videoBytes.size.toLong()
        val xmpData = generateMotionPhotoXmp(videoOffset)
        val imageWithXmp = injectXmpIntoJpeg(imageBytes, xmpData)

        FileOutputStream(outputFile).use { fos ->
            fos.write(imageWithXmp)
            fos.write(videoBytes)
        }
    }

    /**
     * Creates a Motion Photo and returns the bytes as an InputStream.
     *
     * @param imageBytes The JPEG image bytes
     * @param videoBytes The video file bytes
     * @return InputStream containing the Motion Photo data
     */
    fun createMotionPhotoStream(imageBytes: ByteArray, videoBytes: ByteArray): InputStream {
        val videoOffset = videoBytes.size.toLong()
        val xmpData = generateMotionPhotoXmp(videoOffset)
        val imageWithXmp = injectXmpIntoJpeg(imageBytes, xmpData)

        val combined = imageWithXmp + videoBytes
        return combined.inputStream()
    }
}
